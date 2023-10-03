generate_fixed_covariates <-function(units){
  # This function adds fixed covariates to the units dataframe.
  
  # 1/ Take modal year of birth, gender (male), race as reported in arrest data.
  #    Race categories are based on CPD codes.
  x <-
    units |>
    left_join(arrest, by = "link_key", multiple = "all") |>
    mutate(
      yob  = year(date) - age,
      male = ifelse(sex == "M", 1, 0),
      gang = ifelse(link_key %in% gang$link_key, 1, 0),
      race = case_when(
        race == "BLK"             ~ "black",
        race %in% c("WWH", "WBH") ~ "hispanic",
        race == "WHI"             ~ "white",
        TRUE                      ~ "other"
      )
    ) |>
    group_by(link_key, tx, organization, start, gang) |>
    dplyr::summarize(across(c(yob, male, race), mode), .groups = "drop")
  
  # 2/ Drop units with NAs and units with year of birth before 1920.
  out <-
    x |>
    drop_na(yob, male, race) |>
    filter(yob >= 1920)
  
  # 3/ Count dropped units by treatment status.
  dropped <- count(setdiff(x, out), tx)
  
  message(
    glue("--Dropping {dropped$n[dropped$tx == 1]} treated unit(s) and {dropped$n[dropped$tx == 0]} untreated unit(s) born before 1920 or with missing year of birth, sex, or race.")
  )
  
  # 4/ Return fixed covariates with race one-hot encoded.
  out |>
    dummy_cols(select_columns = c("race"), remove_selected_columns = TRUE)
}