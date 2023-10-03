#' The treatment group and the pool of potential control units are unbalanced
#' across a number of important characteristics, such as gang affiliation,
#' the distribution of racial makeup, gender, prior gunshot victimization, etc.
#' This means that a control group taken with a simple random sample from the
#' pool will likely also be unbalanced compared to the treatment group across
#' these characteristics.
#' 
#' The goal here is to balance the control pool such that a simple random sample
#' yields a control group that is balanced with the treatment group in terms of
#' these characteristics. This is achieved by dropping units from the control
#' pool using Bernoulli trials with a success probability calculated based on
#' the actual and desired counts of control-group observations bearing a given
#' characteristic (e.g., participants recorded as gang-affiliated, participants
#' with race recorded as Hispanic, participants recorded as having had a gunshot
#' victimization, etc.) necessary to achieve balance with the treatment group's
#' proportion of participants with the given characteristic.
#' 
#' Because the treatment group is consistently over-represented in terms of all
#' the flag variables (note that we don't balance on race_white, for which the
#' treatment group used in Ross et al. 2023 is always under-represented), we can
#' assume that the proportion in the treatment group with (flag_name = TRUE)
#' will always be greater than that in the control pool. This means that we can
#' drop non-flagged control units (flag_name = FALSE) so that the pool reaches
#' balance with the treatment group. We never have to drop flagged
#' (flag_name = TRUE) control units.
#' 
#' HOWEVER, this means that the approach taken here is NOT a general solution
#' for balancing all possibel pools (that is, with any possible relative
#' proportion of TRUE values in treatment compared to control for any given
#' flag_name).


build_flag <- function(df_aug, var_list){
  # This function takes in a dataframe of treatment and control observations and
  # creates indicator variables for the specified variables (e.g., a specific
  # race, any victimization in a given period; also works for variables that are
  # already dichotomous, such as gender or gang membership).
  
  # Copy the augmented dataset.
  df_flagged <- df_aug
  
  # Initialize an empty vector to store the new variable names.
  flag_names <- c()
  
  for(var_name in var_list){
    # For every variable in the list of covariates, generate the new variable
    # name and append it to the vector of flag names.
    flag_name <- get_flag_name(var_name)
    flag_names <- flag_names %>% append(flag_name)
    
    # Add a new indicator variable to show whether the covariate in question is
    # >= 1.
    df_flagged <- df_flagged %>% 
                  mutate(!!flag_name := ifelse(!!sym(var_name) >= 1, 1, 0))
    
    # Add indicator for participants with year of birth in 1984 or later.
    df_flagged$flag.yob <- ifelse(df_flagged$yob < 1984,0,1)
  }
  # Return a list with the augmented dataframe and the vector of flag names.
  flagged <- list(df = df_flagged,
                  flag_names = flag_names)
}


get_flag_name <- function(var_name){
  # This function takes in a variable name (string) and returns a variable name
  # (string) for the corresponding indicator variable.
  
  # Regular expression to find an interval listed in a variable name.
  int <- "_[0-9]_[0-9]"
  
  # Build a variable name for the flag: detect the type based on strings of
  # known possibilities, then output the flag name. For variable names with an
  # interval, keep the interval as part of the flag_name.
  flag_name <- 
    case_when(var_name == "gang" ~ "flag.gang",
              var_name == "male" ~ "flag.male",
              var_name == "race_black" ~ "flag.black",
              var_name == "race_hispanic" ~ "flag.hispanic",
              var_name == "yob" ~ "flag.yob",
              str_detect(var_name, "^victim") ~ paste0("flag.victim",
                                                       str_extract(var_name,
                                                                   int)),
              str_detect(var_name, "^arrest") ~ paste0("flag.arrest",
                                                       str_extract(var_name,
                                                                   int)),
              str_detect(var_name, "^co_") ~ paste0("flag.co",
                                                    str_extract(var_name,
                                                                int)),
              str_detect(var_name, "^pv_") ~ paste0("flag.pv",
                                                    str_extract(var_name,
                                                                int)))
}


balance_df <- function(df_aug, opt){
  # This function takes in a pool containing the treatment observations and all
  # the eligible control observations, as well as a list of the covariates to
  # balance across groups. It balances the dataframe on each variable and
  # returns the balanced dataframe (all treatment observations and a balanced
  # subset of control observations).
  
  # Get a parsed and cleaned list of balancing variables.
  balance_vars <- get_balance_names(names(df_aug), opt$balance)
  
  message(glue("--Balancing sample on covariates:\n----",
               paste(balance_vars, collapse = " ")))
  
  # Get an object with: 1) a df with flag variables for each balancing variable;
  # and 2) a list of the names of these flag variables.
  flagged <- build_flag(df_aug, balance_vars)
  
  # Copy to a new object.
  df_balanced <- flagged$df
  
  for(flag_name in flagged$flag_names){
    # For every flagged variable name, balance the dataset on that variable.
    df_balanced <- balance_variable(df_balanced, flag_name, opt$seed)
  }
  # Build and write table of proportions for balancing variables and p-values.
  proportions_table(df_balanced, flagged$flag_names, opt)
  
  # Drop the flag name variables and return.
  df_balanced %>% 
    select(-all_of(flagged$flag_names))
}


proportions_table <- function(df, flag_names, opt){
  # This function writes a CSV of the proportions by group for each balancing
  # covariate, along with the p-value from a test of equal proportions.
  
  # Initialize an empty object to create a proportions table.
  df_props <- c()
  
  # For each balancing covariate, add a row to the table.
  for(flag_name in flag_names){
    df_props <- prop_test(df, flag_name, df_props)
  }
  
  # Build file name for output.
  script_dir_trimmed <- get_main_path(opt$script_directory)
  fname <- paste("results/prop_table",
                 opt$organization,
                 opt$status_type,
                 opt$config_name %>% str_remove_all(".*/|.config$"),
                 opt$datetime,
                 "csv",
                 sep = ".")
  
  # Write the table.
  write.csv(df_props %>% rename(Control = `0`, Treatment = `1`),
            file.path(script_dir_trimmed, fname),
            row.names = FALSE)
}


get_flag_values <- function(df, flag_name, prop = TRUE){
  # Build a cross-tabs table, either count (prop is FALSE) or proportions (prop
  # is TRUE).
  
  # Build cross-tabs for treatment group and the current flag_name variable. If
  # prop is TRUE, convert to proportions table (instead of counts).
  xtbl <- df %>% 
          tabyl(tx, !!sym(flag_name)) %>% 
    {function(x)
      if(prop){
        x %>% adorn_percentages()
      }
      else(x)}()
  
  # Build and return a named list of values of groups by flag_name value.
  # The tx11 group is treatment units for whom the flag_name variable is 1.
  #     tx10: treatment group, flag_name = 0.
  #     tx01: control group, flag_name = 1.
  #     tx00: control group, flag_name = 0.
  value_list <- list(tx11 = pull_value(xtbl, 1, "1"),
                     tx10 = pull_value(xtbl, 1, "0"),
                     tx01 = pull_value(xtbl, 0, "1"),
                     tx00 = pull_value(xtbl, 0, "0"))
}


pull_value <- function(xtb, tx_value, flag_value){
  # Takes in a cross-tabs table [from janitor::tabyl()] and pulls the specified
  # value (treatment or not, flagged or not).
  
  # Validate the cross-tabs table.
  xtb_validated <- validate_xtb(xtb)
  
  # Pull out the count/proportion for the tx_value group (1 = treatment, 0 =
  # control) with flag_value (1 = has the flag; 0 = doesn't have the flag).
  xtb_validated %>% 
    filter(tx == tx_value) %>% 
    select(!!sym(flag_value)) %>% 
    pull()
}


validate_xtb <- function(xtb){
  # Validate a cross-tabs table (from janitor::tabyl()), such that there is one
  # row each for tx0 and tx1, one column each for (flag = 0) and (flag = 1),
  # with a value >= 0 in each cell.
  
  # If there is no `0` or `1` column, that means there are no observations where
  # the flag variable is equal to 0 or 1, respectively: all observations (both
  # treatment & control) either have the characteristic or not and thus have
  # parity. Add a column with the value zero to continue.
  for(category in c("0", "1")){
    if(!(category %in% names(xtb))){
      xtb <- xtb %>% mutate(!!sym(category) := 0)
    }
  }
  # Return.
  return(xtb %>% select(tx, `0`, `1`))
}


get_target_tx00_prob <- function(df, flag_name){
  # This function takes in a dataframe and flag name and returns a ratio of the
  # target count for tx00 to the current count of tx00. This is the success
  # probability that will be used in the Bernoulli trials for tx00.
  
  # Get the values from the count cross-tabs (group x flag).
  values <- list(counts = get_flag_values(df, flag_name, FALSE))
  
  # The target number of tx00 for the balanced pool.
  # If values$counts$tx11 AND values$counts$tx01 both are ZERO, returns NaN.
  trg_ct_tx00 <- (values$counts$tx10 / values$counts$tx11) * values$counts$tx01
  
  # Return Bernoulli probability.
  if(is.nan(trg_ct_tx00)){
    # If trg_ct_tx00 is NaN, this means that there are ZERO observations with
    # TRUE for the current flag_name (e.g., ZERO Hispanic participants, ZERO
    # gang-affiliated participants, etc.). This means that 100% of all
    # observations, both treatment and control, have flag_name = FALSE, which
    # means that the proportion of {[(flag_name = TRUE) / tx*] = 1} for each
    # group, so we keep ALL control observations (with bern_prob = 1).
    bern_prob <- 1
  }
  else{
    # Otherwise, compute the probability needed to keep the correct number of
    # control observations with (flag_name = 0).
    # The WANTED probability for the Bernoulli trial is the ratio of the TARGET
    # count of tx00 observations to the ACTUAL count of tx00 observations.
    bern_prob <- trg_ct_tx00 / values$counts$tx00
  }
}


balance_variable <- function(df, flag_name, seed = 1){
  # This function takes in a dataframe and flag_name and returns a dataframe
  # balanced across treatment and control groups for the specified flag_name
  # variable.
  
  # Validate the cross table, adding zeros as necessary.
  df_valid <- validate_xtb(df %>% tabyl(tx, !!sym(flag_name)))
  # Get probability for Bernoulli trials for tx0_0 observations.
  bern_prob <- get_target_tx00_prob(df, flag_name)
  
  # Set seed in a reproducible manner. See for more details:
  # community.rstudio.com/t/getting-different-results-with-set-seed/31624/5
  # stackoverflow.com/questions/63276681/same-seed-different-results-in-docker-r-and-local-r
  # stackoverflow.com/questions/47199415/is-set-seed-consistent-over-different-versions-of-r-and-ubuntu/56381613#56381613
  setRNG(seed = seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
  
  # Randomly assign the FALSE flag_name observations to either keep or discard
  # and then drop the discards, thus balancing the pool on that variable.
  # If an observation is tx1* or tx01, keep it (probability = 1). For tx00
  # observations, assign either TRUE or FALSE randomly to keep, using a
  # Bernoulli trial with p = bern_prob. Keep the TRUE observations; drop keep
  # variable. Return df.
  # Note: purrr::rbernoulli() is now deprecated, but was not at the time this
  #       code was written.
  df_balanced <- df %>% 
                 mutate(keep = rbernoulli(nrow(.),
                                          ifelse(tx | !!sym(flag_name),
                                                 1,
                                                 bern_prob))) %>% 
                 filter(keep) %>% 
                 select(-keep)
}


sample_balanced <- function(df_balanced, cg_size, seed){
  # This function takes in a df balanced across one or more covariates as well
  # as the desired control group size and the seed; it returns a dataframe with
  # the treatment group and the sampled control observations.
  
  # Set seed in a reproducible manner. See for more details:
  # community.rstudio.com/t/getting-different-results-with-set-seed/31624/5
  # stackoverflow.com/questions/63276681/same-seed-different-results-in-docker-r-and-local-r
  # stackoverflow.com/questions/47199415/is-set-seed-consistent-over-different-versions-of-r-and-ubuntu/56381613#56381613
  setRNG(seed = seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
  
  # Pull out just the treated observations.
  df_treatment <- df_balanced %>% 
                  filter(tx == 1)
  
  # Sample from the control pool.
  df_control <- df_balanced %>% 
                filter(!tx) %>% 
                sample_n(size = cg_size, replace = FALSE)
  
  # Bind the treatment and control groups together; return.
  df_sample <- bind_rows(df_treatment, df_control)
}


parse_balance_list <- function(balance_string){
  # Build a list of proper variable names from the opt$balance string, which
  # specifies a space-separated list of variable names.
  
  # Split the string into a list of variables, all lower-case.
  var_list <- split_var_list(balance_string) %>% str_to_lower()
  
  # Initialize an empty list to hold the clean names.
  parsed_balance_vars <- c()
  
  for(var in var_list){
    # For every variable in the list, match it to its proper variable name. If
    # it doesn't match any of the listed cases, add it as-is.
    clean_var <- case_when(var == "victimization" ~ "victim",
                           var == "arrests" ~ "arrest",
                           var == "coarrestees" ~ "co",
                           str_detect(var, "peer-victim") ~ "pv",
                           TRUE ~ var)
    
    # Append the proper name to the list.
    parsed_balance_vars <- parsed_balance_vars %>% append(clean_var)
  }
  # Take the set.
  unique(parsed_balance_vars)
}


split_var_list <- function(var_list_raw){
  # Takes a string containing one or more variable names and splits it into a
  # list of all the different variable names.
  var_list <- (str_split(var_list_raw, " "))[[1]] %>% c()
}


get_balance_names <- function(aug_names, balance_string){
  # Takes in the names from a dataframe augmented with all covariates and a
  # string containing a space-separated list of balancing variables. Creates a
  # list of the actual covariate names that correspond to the balancing
  # variables. This is specifically designed to add the intervals for arrest,
  # co-arrest, victimization, and peer-victimization periods.
  
  # Get parsed list of balance variables.
  parsed_balance_vars <- parse_balance_list(balance_string)
  
  # Initialize a list to hold the names of the balancing covariates.
  actual_balance_names <- c()
  
  # For every item in the list of parsed names:
  for(bal_var in parsed_balance_vars){
    
    # For every covariate in the list of variable names:
    for(covar in aug_names){
      
      # If bal_var is detected in covar, add covar to the list of balance vars.
      if(str_detect(covar, bal_var)){
        actual_balance_names <- append(actual_balance_names, covar)
      }
    }
  }
  return(actual_balance_names)
}


balance <- function(eligible_units, opt){
  # This function takes in a dataframe of eligible units (treatment and control)
  # as well as the options object and returns a dataframe with all treatment
  # observations and a sample of control observations balanced on specified
  # variables.
  
  # To oversample, generate start dates for the control pool but do not drop any
  # control units. Obtain a dataframe with the treated units and the whole
  # pool of control observations.
  
  # Start by finding the number of control units.
  n_control <- eligible_units %>% filter(!tx) %>% nrow()
  
  # Add start dates to entire pool of control units. Augment the pool with
  # additional covariates. Balance on opt$balance variables. Sample from the
  # balanced pool.
  sample_aug <- generate_evaluation_data(eligible_units,
                                         n = n_control,
                                         seed = opt$seed) %>% 
                augment_units(opt) %>% 
                balance_df(opt) %>%       
                sample_balanced(opt$cg_size, opt$seed)
}


prop_test <- function(df, flag_name, df_props){
  # This function builds cross-tabs for groups by a given balancing variable and
  # conducts a proportion test to assess similarity. It returns a dataframe with
  # the proportion for each group and the p-value from Fisher's exact test of
  # proportions.
  
  # Cross-tabs of group and target covariate flag.
  xtb <- df %>% tabyl(tx, !!sym(flag_name))
  
  # Validate to make sure there are both `0` and `1` columns.
  xtb_validated <- validate_xtb(xtb)
  
  # Build a matrix of observations by type per group.
  mtx <- xtb_validated %>% select(-tx) %>% as.matrix()
  
  # We could have extremely small counts for some groups, so use the exact test.
  test <- fisher.test(mtx)
  
  # Return df_props with a new row for the current flag_name covariate.
  xtb_validated %>% 
    untabyl() %>%  
    adorn_totals("col") %>% 
    transmute(tx,
              proportion = `1` / Total,
              Covariate = flag_name) %>% 
    pivot_wider(values_from = proportion,
                names_from = tx) %>% 
    mutate(exact_p = test$p.value) %>% 
    bind_rows(df_props)
}