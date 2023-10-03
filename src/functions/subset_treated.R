subset_treated <- function(org){
  # This function selects a subset of the treated observations according to the
  # outreach organization from which they receive services.
  # 
  # The possible subsets from Ross et al. 2023 include:
  # 
  # Org Code           Description
  # --------------------------------------------
  # cred               All CRED cohorts combined
  # cred_alumni        Alumni of CRED program only (includes employment and
  #                      training)
  # cred_programming   CRED participants who advanced past the outreach stage
  
  # Clean up the organization name.
  org_name <- str_to_lower(org)
  
  # Return the subset of treated units for the given organization(s).
  if(org_name == "cred"){
    # All CRED cohorts combined.
    treated %>% 
      filter(organization == "cred")
  }
  else if(org_name == "cred_alumni"){
    # CRED alumni participants.
    treated %>% 
      filter(organization == "cred",
             participant_status_program_phase %in% c("Alumni",
                                                     "Employment and Training"))
  }
  else if(org_name == "cred_programming"){
    # CRED participants who have advanced past the outreach stage.
    
    # Declare vector of allowed values for participant phase.
    allowed_phase <- c("Alumni",
                       "Employment and Training",
                       "Peace Ambassador",
                       "Programming - Phase 1",
                       "Programming - Phase 2",
                       "Programming - Phase 3")
    
    # All CRED participants excluding those inactive for reasons other than CJ
    # or Violence.
    treated %>%
      filter(organization == "cred",
               participant_status_program_phase %in% allowed_phase |
                 str_detect(participant_status_program_phase, "Deceased") &
                   previous_status_value %in% allowed_phase |
                 str_detect(participant_status_program_phase, "Inactive") &
                   previous_status_value %in% allowed_phase)
  }
}