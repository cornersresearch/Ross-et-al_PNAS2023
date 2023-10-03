save_results <- function(results, results_type){
  # Saves the results file, including the results type ('simple' or 'full') in
  # the file name.
  
  # Get the absolute path to the main Ross-et-al_PNAS2023 directory.
  script_dir_trimmed <- get_main_path(results$parameters$main$script_directory)
  
  # Pull out the elements for the file name.
  org <- results$parameters$main$organization
  surv <- results$parameters$main$status_type
  config <- results$parameters$main$config_name %>% str_remove_all(".*/|.config$")
  datetime <- results$parameters$main$datetime
  
  # Build the file name (this path is relative to the absolute path of the
  # Ross-et-al_PNAS2023 path).
  fname <- glue("results/results_surv_{results_type}.{org}.{surv}.{config}.{datetime}.rds")
  
  message(glue("\nSaving {results_type} results:\n"))
  message(file.path(script_dir_trimmed, fname))
  
  # Save the results.
  saveRDS(results, file.path(script_dir_trimmed, fname))
}