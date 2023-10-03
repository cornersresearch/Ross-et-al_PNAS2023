## Required parameters that must be specified in the configuration file passed
## to the run_bart_surv.sh shell script:
# -o: organization
# -s: survival
# -g: geo_restrict
# -z: cg_size
# -v: treatment_variable
# -e: seed
# -l: balance
# -t: script_directory
# -n: config_name
# -h: datetime

validate_input <- function(opt){
  # This function takes the parsed input object and validates each input.
  
  message("--Validating input")
  
  check_for_missing(opt)
  
  # Validate the inputs, checking by type.
  valid_str <- validate_str(opt)
  valid_int <- validate_int(opt)
  valid_bool <- validate_bool(opt)
  valid_list <- validate_list(opt)
  
  # Throw an error and stop execution if any of the values are invalid.
  if(!(valid_list & valid_bool & valid_int & valid_str)){
    stop(paste("One or more inputs are invalid. Correct the values in the",
               "configuration script\n  and try again."))
  }
}

check_for_missing <- function(opt){
  # Ensure that there is a value for each parameter.
  for(i in 1:length(opt_parser@options)){
    local_arg <- opt_parser@options[[i]]@dest
    local_val <- opt[[local_arg]]
    
    # If there is a missing value, throw an error and stop execution.
    if(is.null(local_val)){
      local_flag <- opt_parser@options[[i]]@short_flag
      stop(glue("There was no argument for the '{local_arg}' parameter.\n",
                "Indicate a valid argument for the '{local_flag}' parameter ", 
                "and try again."))
    }
  }
}

validate_list <- function(opt){
  # Validate values that are a list of one or more possible options.
  
  # Initialize the flag to true.
  valid_list <- TRUE
  
  # Declare list of option lists and their possible members.
  options <- list(balance = c("male", "black", "hispanic", "gang", "arrest",
                              "arrests", "victim", "victimization",
                              "coarrestees", "peer-victim",
                              "peer-victimization", "yob","none"))
  
  # For each parameter in the list of required list-type parameters:
  for(option in names(options)){
    # Pull out the necessary string value for the current parameter, convert to
    # lowercase, and split into a list of individual items.
    parsed_values <- opt[[option]] %>% str_to_lower() %>% split_var_list()
    
    if("none" %in% parsed_values & length(parsed_values) > 1){
      # If "none" is among others in a list, stop and warn the user.
      stop(glue("Option 'none' included in list passed to '{option}' parameter.",
                "\n  Either enter 'none' alone or remove 'none' from list."))
    }
    
    # Find the list of allowed options for the current parameter.
    possible_options <- options[[option]]
    
    # Validate the inputs: For each item in the parsed values for the current
    # parameter:
    for(item in parsed_values){
      if(!(item %in% possible_options)){
        # If the current parsed value is not in the list of allowed values for
        # the current parameter, flip the flag and print a warning that the
        # value is invalid.
        valid_list <- FALSE
        warning(glue("Option '{item}' is invalid for parameter '{var_type}'. ",
                     "\nMust be any of:\n{possible_options}"))
      }
    }
  }
  return(valid_list)
}

validate_bool <- function(opt){
  # Validates the boolean values.
  
  # Initialize the flag to true.
  valid_bool <- TRUE
  
  # Declare the values to look for in opt.
  values_bool <- c("geo_restrict")
  
  # For each parameter in the list of required boolean parameters:
  for(bool in values_bool){
    # Pull out the parsed boolean value for the current parameter.
    parsed_value <- opt[[bool]]
    
    # If the parsed_value is not of class 'logical', flip the flag and print a
    # warning.
    if(!(parsed_value %in% c(TRUE, FALSE))){
      valid_bool <- FALSE
      warning(paste0("The value for '", bool, "' (", parsed_value, ") ", "is ",
                     "invalid; must be of class 'logical':\n      TRUE or FALSE"))
    }
  }
  return(valid_bool)
}

validate_int <- function(opt){
  # Validates the integer values.
  
  # Initialize the flag to true.
  valid_int <- TRUE
  
  # Build list of allowed value ranges.
  values_int <- list(cg_size = list(lower = 50, upper = 6000),
                     seed = list(lower = 0, upper = 1000000000))
  
  # For each parameter in the list of required integer parameters:
  for(int in names(values_int)){
    # Pull out the parsed integer value for the current parameter.
    parsed_value <- opt[[int]]
    
    # Find the allowed upper and lower limits for the current parameter.
    allowed_lower <- values_int[[int]]$lower
    allowed_upper <- values_int[[int]]$upper
    
    # If the parsed_value is not an integer between the given range, set the
    # flag to FALSE and show a warning.
    if(!(parsed_value >= allowed_lower & parsed_value <= allowed_upper)|
       parsed_value %% 1 != 0){
      valid_int <- FALSE
      warning(paste0("The value for '", int, "' ('", parsed_value, "') ",
                     "is invalid; must be an integer between:\n      [",
                     paste0(allowed_lower, ", ", allowed_upper), "]"))
      
    }
  }
  return(valid_int)
}

validate_str <- function(opt){
  # Validates the string-type options.
  
  # Initialize the flag to true.
  valid_str <- TRUE
  
  # Create a named list of the allowed values for the string types.
  values_str <- list(organization = c("cred", "demo_organization"),
                     status_type = c("victim", "victimization", "arrest",
                                     "violent-arrest", "violent_arrest",
                                     "either"),
                     treatment_variable = c("tx", "treatment", "treat", "trt",
                                            "group"))
  
  # Validate the inputs: For each parameter in the list of required parameters:
  for(string in names(values_str)){
    # Pull out the necessary values; convert parsed value to lowercase.
    parsed_value <- opt[[string]] %>% str_to_lower()
    
    # Get the allowed values for the current parameter.
    allowed_values <- values_str[[string]]
    
    # If the parsed value is not in the list of allowed values for the current
    # parameter, flip the flag and print a warning that the value is invalid.
    if(!(parsed_value %in% allowed_values)){
      valid_str <- FALSE
      warning(paste0("The value for '", string, "' ('", parsed_value, "') ",
                     "is invalid; must be one of:\n      '",
                     paste0(allowed_values, collapse = "', '"), "'"))
    }
  }
  return(valid_str)
}