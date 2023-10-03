run_bart_survival <- function(opt){
  # Starting with a model specification object, run the BART analysis from start
  # to finish. Return a results object.
  
  message("\nRunning BART survival analysis framework...\n")
  
  # Prepare sample observations for analysis.
  sample_data <- prepare_sample(opt)
  
  # Bundle up the data and parameters for the BART calls.
  params <- bundle_parameters(sample_data, opt)
  
  # Build the BART model and get the results object.
  bart_results <- build_bart(params)
  
  return(bart_results)
}


prepare_sample <- function(opt){
  # Prepare the sample for analysis: subset the treatment group for the
  # specified organization/cohort; generate a control group; augment the sample
  # with covariates; drop administrative variables & those with a single value.
  
  message(glue("Preparing sample with seed = {opt$seed}...\n"))
  
  # Subset treated units.
  sample_tx <- subset_treated(opt$organization)
  
  # Add eligible untreated units to the treatment group; add fixed covariates.
  eligible_units <-
    arrest |>
    generate_eligible_untreated(treated = sample_tx, services = services,
                                order = 1, arrest_since = ymd("2016-01-01"),
                                geo_restrict = opt$geo_restrict) |> 
    bind_rows(sample_tx) |>
    generate_fixed_covariates()
  
  if(opt$balance %>% str_to_lower() %>% str_detect("none")){
    # If there are no balancing variables specified, sample without balancing.
    
    # Generate sample (all treatment units and sample of untreated units) AND
    # add the arrest, co-arrest, victimization, and peer-victimization
    # covariates. Augment the sample with additional covariates.
    sample_aug <- generate_evaluation_data(eligible_units,
                                           n = opt$cg_size,
                                           seed = opt$seed) %>% 
                  augment_units(opt)
  } else{
    # If there are balancing variables specified, balance the pool on those
    # covariates and generate the evaluation sample.
    sample_aug <- balance(eligible_units, opt)
  }
  
  # Find the names of variables that have a single value (these can't be used in
  # the analysis).
  drop_names <- vars_to_drop(sample_aug)
  
  # Drop the variables with a single value as well as the administrative
  # variables.
  sample_data <- 
    sample_aug %>% 
    select(-c(all_of(drop_names), start, link_key, organization))
  
  message("\nUsing the following variables:\n",
          paste(names(sample_data), collapse = ", "))
  
  return(sample_data)
}


vars_to_drop <- function(units){
  # Find the names of variables that only have a single value throughout the
  # entire sample.
  units |>
    select(where(is.numeric)) |>
    summarise(across(everything(), ~ length(unique(.x)))) |>
    select(where(function(x) x == 1)) |>
    names()
}


augment_units <- function(sample_all, opt){
  # Augment the sample with additional covariates.
  
  message("--Augmenting sample with covariates")
  
  # Add proportion of treated first- and second-order co-arrest peers.
  # Add survival/failure status time (victimization, violent_arrest, or either).
  sample_aug <- 
    sample_all %>% 
    left_join(count_treated_peers(.),
              by = "link_key") %>% 
    left_join(find_event_status(., opt$status_type), by = "link_key") %>% 
    rename(time = status_time)
}


bundle_parameters <- function(sample_data, opt){
  # Build a list with all the needed parameters and data.
  
  message("\nSetting parameters")
  
  # Build the basic model.
  bart_params <- list(sample_data = sample_data,
                      cores = parallel::detectCores(),
                      times = ceiling(sample_data$time / 7), # weeks
                      delta = sample_data$status,
                      N = nrow(sample_data),
                      x.train = sample_data %>% 
                                  select(-c(time, status)) %>% 
                                  data.matrix(),
                      treatment_variable = opt$treatment_variable,
                      seed = opt$seed,
                      printevery = 100) # Only prints to terminal, not R console
 
  message("--N = ", bart_params$N, " total observations\n")
  
  # Build list of parameters: main (user-specified) and bart (components for the
  # analysis).
  params <- list(main = opt, bart = bart_params)
  
  return(params)
}


build_bart <- function(params){
  # Bundle up the pre and post.
  b <- bart_pre_post(params$bart)
  
  # Run the predictions and get results.
  results <- bart_predict(b, params)
  
  return(results)
}


bart_pre_post <- function(bart_params){
  message("Processing BART survival analysis...")

    b <- list(post = mc.surv.bart(x.train = bart_params$x.train,
                                  times = bart_params$times,
                                  delta = bart_params$delta,
                                  printevery = bart_params$printevery,
                                  mc.cores = bart_params$cores,
                                  seed = bart_params$seed),
              pre = surv.pre.bart(times = bart_params$times,
                                  delta = bart_params$delta,
                                  x.train = bart_params$x.train,
                                  x.test = bart_params$x.train))
  
  return(b)
}


bart_predict <- function(b, params){
  # Predictions.
  
  message("--Generating predictions...\n")
  
  # Number of unique status times in the dataset.
  K <- b$pre$K
  
  # Number of posterior draws returned.
  M <- b$post$ndpost
  
  # Find position of treatment variable in the tx.test dataframe.
  tx_position <- match(params$bart$treatment_variable,
                       b$pre$tx.test %>% as.data.frame() %>% names())
  
  # Augment with itself.
  b$pre$tx.test <- rbind(b$pre$tx.test, b$pre$tx.test)
  
  # Top are control; lower are treatment.
  b$pre$tx.test[, tx_position] <- c(rep(0, params$bart$N * K),
                                    rep(1, params$bart$N * K))
  
  # Generate predictions.
  b$pred <- predict(b$post,
                    newdata = b$pre$tx.test,
                    mc.cores = params$bart$cores)
  
  # Initialize empty matrix (with NAs) to hold mean prediction values.
  b$pd <- matrix(nrow = M, ncol = 2 * K)
  
  # Populate the matrix:
  # For every unique status time:
  for(j in 1:K){
    # A vector of numbers from j to (num rows * num times) by (num times).
    h <- seq(j, params$bart$N * K, by = K)
    
    # Calculate and fill in mean prediction values.
    # The 1 is for rows; it's an R-ism, not a magic number.
    b$pd[ , j] <- apply(b$pred$surv.test[ , h], 1, mean)
    b$pd[ , j + K] <- apply(b$pred$surv.test[ , h + params$bart$N * K], 1, mean)
  }
  
  # Not strictly needed.
  rm(h, j)
  
  # Get means.
  # The 2 is for columns; it's not a magic number, it's an R-ism.
  pd <- list(mu = apply(b$pd, 2, mean),
             # posterior intervals, 85% CI
             ci.075 = apply(b$pd, 2, quantile, probs = 0.075),
             ci.925 = apply(b$pd, 2, quantile, probs = 0.925))
  
  # Indices of rows for control and treated observations for each unique status
  # time.
  ix.untreated <- 1:K
  ix.treated <- ix.untreated + K

  # Generate results object, including tibble of computed effects and CI values.
  results <- list(bart = b,
                  parameters = params,
                  table = tibble(time   = rep(b$pre$times, 2),
                                 group  = c(rep("tx", length(b$pre$times)),
                                            rep("cg", length(b$pre$times))),
                                 mu     = c(pd$mu[ix.treated],
                                            pd$mu[ix.untreated]),
                                 ci_min = c(pd$ci.075[ix.treated],
                                            pd$ci.075[ix.untreated]),
                                 ci_max = c(pd$ci.925[ix.treated],
                                            pd$ci.925[ix.untreated])))
  
  # Build the plot and add to the results object.
  results$plot <- build_plot(results$table, params$main)
  
  return(results)
}


build_plot <- function(results_table, main_params){
  # Builds and returns a plot of the survival curves.
  
  # Build the file name; first get the absolute path to the main
  # outreach_individual directory; then paste the rest of it together.
  script_dir_trimmed <- get_main_path(main_params$script_directory)
  fname <- paste("figures/plot_surv",
                 main_params$organization,
                 main_params$status_type,
                 main_params$config_name %>% str_remove_all(".*/|.config$"),
                 main_params$datetime,
                 "pdf",
                 sep = ".")
  
  # Build the plot title.
  title <- main_params$organization %>% str_to_upper()
  
  # Build the subtitle.
  subtitle <- paste0("Status type: ", main_params$status_type,
                     "\nSeed: ", main_params$seed,
                     "\nGeographically constrained: ", main_params$geo_restrict,
                     "\nBalance sample on: ", main_params$balance)
  
  # Build plot.
  surv_plot <- 
    results_table %>% 
    mutate(group = factor(group,
                          levels = c("cg", "tx"),
                          labels = c("Control", "Treatment"))) %>% 
    ggplot(aes(time, mu)) + 
    geom_line(aes(color = group)) +
    geom_ribbon(aes(ymin = ci_min, ymax = ci_max, fill = group),
                alpha = 0.2) +
    coord_cartesian(ylim = c(0.8, 1)) + 
    labs(title = title, subtitle = subtitle,
         x = "Weeks After Start Date",
         y = "Mean Probability of Survival") +
    theme_minimal() + 
    theme(legend.title = element_blank(),
          legend.position = "bottom",
          plot.subtitle = element_text(size = 8),
          axis.title = element_text(size = 8))
  
  message("Saving plot:\n")
  message(file.path(script_dir_trimmed, fname))
  
  # Save plot.
  ggsave(file.path(script_dir_trimmed, fname),
         width = 8, height = 6, units = "in")
  
  return(surv_plot)
}