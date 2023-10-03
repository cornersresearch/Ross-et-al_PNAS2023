generate_evaluation_data <- function(eligible_units, n = 10, seed = 50){
  # This function generates a dataframe with all the treatment units and subset
  # of the control units. The control units will have assigned "start" dates
  # (drawn from the treatment group's start dates). Control units with
  # fatalities before their assigned "start" date are dropped. Covariates are
  # added for pre-victimizations, pre-arrests, pre-coarrestees, and
  # pre-coarrestees' pre-victimizations.
  #
  # NOTE on BALANCING:  When balancing groups on certain covariates, the value
  # for n should be the size of the entire control pool in the eligible_units
  # df; in this case, the entire set of observations will be returned, except
  # for control units that had a fatality before their randomly assigned start
  # date.
  
  # 1/ Generate a sample of control units with assigned start dates and include
  # all the treatment observations, too.
  all_units_raw <- sample_tx0(eligible_units, n, seed)
  
  # 2/ Find units with fatal victimizations in the 50 years before start.
  #    Accounts for the possibility that there aren't any observations with a
  #      fatal victimization in the 50 years before start.
  fatal_before_start <-
    count_events(victim, all_units_raw, interval_width = 50,
                 intervals = "[-50,0)", by = "type") |>
    {function(x)
      if("victim_50_0_fatal" %in% names(x)){
        # Keep only units with a fatality before their start date.
        x %>% filter(!is.na(victim_50_0_fatal))
      } else{
        # Create a one-row dataframe with NA for link_key (this will allow for
        # dropping no units at all at the next step).
        data.frame(link_key = NA)
        }
      }()
    
  
  message(glue("--Removing {length(unique(fatal_before_start$link_key))} unit(s) with a fatal victimization before start date."))
  
  # 3/ Drop units with a fatality before their assigned start date (or none, if
  #    there were no such units).
  all_units <- 
    anti_join(all_units_raw, fatal_before_start, by = "link_key")
  
  # 4/ Victimizations in the 3 years before start date in a 3-year interval.
  pre_victimizations <- 
    count_events(response = victim, units = all_units, interval_width = 3,
                 intervals = c("[-3,0)"))
  
  # 5/ Arrests in the 3 years before start date in a 3-year interval.
  pre_arrests <- 
    count_events(response = arrest, units = all_units, interval_width = 3,
                 intervals = c("[-3,0)"))
  
  # 6/ Coarrestees in 3 years before start date in a 3-year interval.
  pre_coarrestees <- 
    count_coarrestees(all_units, interval_width = 3,
                      intervals = c("[-3,0)"))
  
  # 7/ Peer victimizations in the 3 years before start in a 3-year interval.
  pre_coarrestee_victimizations <- 
    count_coarrestee_victimizations(all_units, interval_width = 3,
                                    intervals = c("[-3,0)"))
  
  # 8/ Join covariates; replace NAs with zero.
  evaluation <- 
    all_units |>
    left_join(pre_victimizations, by = "link_key") |>
    left_join(pre_arrests, by = "link_key") |>
    left_join(pre_coarrestees, by = "link_key") |>
    left_join(pre_coarrestee_victimizations, by = "link_key") |>
    mutate(across(where(is.integer), replace_na, 0))
  
  message(glue("--Evaluation sample generated (seed: {seed})."))
  
  evaluation
}