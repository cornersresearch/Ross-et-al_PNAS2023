prepare_demo_environment <- function(){
  message("\nPreparing environment...\n")
  
  #load in necessary packages
  source("src/packages.R")
  
  #load in necessary functions
  walk(list.files("src/functions/", full.names = TRUE), source)
  
}

run_bart_surv_demo <- function(opt){
  message("\nRunning BART survival analysis framework...\n")
  
  # Prepare demo sample observations for analysis.
  df_demo <- prepare_demo_sample(opt)
  
  # Generate and bundle parameters for BART
  params <- bundle_parameters(df_demo, opt)
  
  # Run BART and save results
  bart_results <- build_bart(params)
  
}

build_demo_opt <- function(){
  # Build a model specification object.
  opt <- list(organization = "demo_organization",
              status_type = "violent_arrest",
              geo_restrict = FALSE,
              cg_size = as.integer(100),
              treatment_variable = "tx",
              seed = as.integer(1),
              balance = "male black hispanic gang arrest victimization yob",
              script_directory = "src",
              config_name = "demo.config",
              datetime = Sys.time() %>% 
                gsub("-", "", .) %>% 
                gsub(" ", "_", .) %>% 
                gsub(":", "-", .))
}

build_demo_pool <- function(){
  # Build a pool of observations (both treatment and control).
  
  # Choose a number, n, for the total pool size (both treatment and control).
  n <- 400
  
  # Create a range of start dates to choose from (5 years, starting on 15th).
  start_dates <- seq(lubridate::date('2018-01-15'),
                     by = 'month',
                     length.out = 12 * 5)
  
  # Create a fixed final date through which the dataset captures event
  # observations.
  end_date <- date('2023-09-30')
  
  # Set seed in a reproducible manner.
  setRNG(seed = opt$seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
  
  # Create a dataframe with n observations, starting with an ID variable as a
  # unique identifier.
  # Use random sampling for the rest of the variables.
  sample_df <- data.frame(link_key = 1:n) %>% 
    mutate(
      tx = rbinom(n, 1, 0.25),
      organization = ifelse(tx == 0, NA, "demo_organization"),
      start = sample(start_dates, n, replace = TRUE),
      gang = rbinom(n, 1, 0.6),
      yob = sample(1980:2004, n, replace = TRUE),
      male = rbinom(n, 1, 0.92),
      race = sample(c('black','hispanic','other','white'),
                    n,
                    replace = TRUE,
                    prob = c(0.7, 0.24, 0.01, 0.05)),
      victim_3_0 = sample(0:2, n, replace = TRUE, prob = c(0.7, 0.25, 0.05)),
      arrest_3_0 = sample(0:10, n, replace = TRUE),
      co_3_0 = sample(0:5, n, replace = TRUE) %>% 
                 ifelse(arrest_3_0 == 0, 0, .)) %>% 
    rowwise() %>% 
    mutate(
      pv_3_0 = sample(0:co_3_0, 1, replace = TRUE),
      prop.deg1_tx1 = (sample(0:co_3_0, 1, replace = TRUE) / co_3_0) %>% 
                        replace_na(0),
      prop.deg2_tx2 = (sample(0:(co_3_0 * 2), 1, replace = TRUE) / 
                        (co_3_0 * 2)) %>% replace_na(0),
      time_prelim = seq(start + 1, end_date, by = 'day') %>% sample(1),
      time_delta = difftime(time_prelim, start, units = 'days') %>% 
                     as.numeric()) %>% 
    ungroup() %>% 
    mutate(
      status = rbinom(n, 1, 0.25),
      time = ifelse(status == 1, time_delta, max(time_delta))) %>% 
    select(-c(time_prelim, time_delta)) %>% 
    dummy_cols("race", remove_selected_columns = TRUE)
}

prepare_demo_sample <- function(opt){
  # Generate a dataframe containing the treatment observations and a randomly
  # sampled control group.
  
  if(opt$balance %>% str_to_lower() %>% str_detect("none")){
    # If there are no balancing variables specified, sample without balancing.
    
    # Generate pool from which to sample.
    df_pool <- build_demo_pool() 
    
  } else{
    # If there are balancing variables specified, balance the control pool on
    # those covariates.
    df_pool <- build_demo_pool() %>% 
               balance_df(opt)
  }
  
  # Split into two dataframes, one for treatment and the other for control.
  df_tx1 <- filter(df_pool, tx == 1)
  df_tx0 <- filter(df_pool, tx == 0)
  
  # Randomly select a control group of specified size, then add treatment group.
  df_sample_prelim <- sample_n(df_tx0, opt$cg_size) %>% 
                      bind_rows(df_tx1)
  
  # Get names of any variables that should be dropped (because they have
  # constant value across all observations).
  drop_names <- vars_to_drop(df_sample_prelim) 
  
  # Drop specified variable names and return.
  df_sample <- df_sample_prelim %>% 
    select(-c(all_of(drop_names), start, link_key, organization))
}