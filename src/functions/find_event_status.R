find_event_status <- function(units, status_type){
  #' This function takes in the *current evaluation units* and a *status type*
  #' (*arrest for a violent offense* or *victimization* or *either* ) and
  #' determines their event status and status time based on their start date.
  #' The *status_time* variable captures the number of *days* between the start
  #' date and the status-event date (for those with *no* status-events, this is
  #' right-censored; that is, the date of the most-recent status-event of *all*
  #' such status-events).
  
  # Get the specified set of status-events.
  if(str_to_lower(status_type) %in% c("arrest",
                                      "violent-arrest",
                                      "violent_arrest")){
    # Status type is *violent arrest*.
    status_events <- 
      arrest %>% 
      filter(violent == "violent") %>% 
      transmute(link_key, status_date = date)
  } else if(str_to_lower(status_type) %in% c("victimization", "victim")){
    # Status type is *victimization*.
    status_events <- 
      victim %>% 
      transmute(link_key, status_date = date)
  } else if(str_to_lower(status_type) == "either"){
    # Status type is *either violent arrest OR victimization*.
    status_events <- 
      arrest %>% 
      filter(violent == "violent") %>% 
      transmute(link_key, status_date = date) %>% 
      bind_rows(victim %>%
                  transmute(link_key, status_date = date))
  }
  
  # Pull out the date of the latest status event (of all the events).
  last_status_date <- status_events$status_date %>% max()
  
  #' 1/ Join status_events to units, keeping only those events pertaining to
  #'    members of the evaluation group.
  #' 2/ Keep only those events *after* the individual start date.
  #' 3/ Keep the earliest of the post-start status-events.
  #' 4/ Join back up with units (so as to get a row for units with NO post-start
  #'    status-events)
  #' 5/ Create a flag for status (*1* for *had a post-start status event*, *0*
  #'    for *no post-start status event*)
  #' 6/ Add a status_time variable with a time for the status event minus start
  #'    date (if status == 1) OR the last_status_date minus start
  #'    (if status == 0). This captures the number of days between the start
  #'    date and the status date (status == 0 is right-censoring, that is, the
  #'    end of the study period).
  #' 7/ Keep only the link_key, status, and status_time variables.
  status_events %>% 
    inner_join(units %>% 
                 transmute(link_key, start),
               by = "link_key") %>% # 1
    filter(status_date > start) %>% # 2
    transmute(link_key, status_date) %>% 
    group_by(link_key) %>%  # Need to get the earliest post-start status-event; some observations have multiple post-starts status events
    arrange(link_key, status_date) %>% 
    slice(1) %>% # 3 Get rid of subsequent status events beyond the earliest post-start status-event
    ungroup() %>% 
    right_join(units %>% 
                 transmute(link_key, start), by = "link_key") %>% # 4
    mutate(status = if_else(is.na(status_date), 0, 1), # 5
           status_time = if_else(status == 1,
                                 as.integer(status_date - start),
                                 as.integer(last_status_date - start))) %>% # 6
    transmute(link_key, status, status_time) # 7
}