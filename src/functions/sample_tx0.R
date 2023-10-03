sample_tx0 <- function(eligible_units, n, seed){
  # This function generates a sample of control units and returns a single
  # dataframe with both the treatment and control groups.
  
  # Set the seed for reproducibility.
  # Because of a change in a recent version of R, the results from setting a
  # seed VARY when running this in RStudio compared to from a script or in the
  # bare R application. We have to set the seed with *setRNG()*.
  # NOTE: The BART process yields identical results as long as it uses the same
  # sample and parameters; this means the BART library(ies) must be setting the
  # seed in an actually reproducible way (similar or as done here).
  # See the discussions below for more information:
  # community.rstudio.com/t/getting-different-results-with-set-seed/31624/5
  # stackoverflow.com/questions/63276681/same-seed-different-results-in-docker-r-and-local-r
  # stackoverflow.com/questions/47199415/is-set-seed-consistent-over-different-versions-of-r-and-ubuntu/56381613#56381613
  setRNG(seed = seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
  
  # 1/ separate treated units
  treated_units <- filter(eligible_units, tx == 1)
  
  # 2/ sample untreated units and randomize start dates
  message(glue("--Sampling {n} untreated unit(s) and randomizing start dates with seed = {seed}."))
  
  # 3/ Generate a control sample (without replacement) from the pool of eligible
  # control units. Drawing with replacement from the treatment group's start
  # dates, assign a random start date to each control observation.
  untreated_units <- 
    filter(eligible_units, tx == 0) |>
    sample_n(size = n, replace = FALSE) |>
    mutate(start = sample(treated_units$start, size = n(), replace = TRUE))
  
  # 4/ bind all treated units with sample of untreated units; return.
  all_units_raw <- bind_rows(treated_units, untreated_units)
}