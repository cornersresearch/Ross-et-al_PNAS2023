create_output_directories <- function(script_directory){
  # This function creates output directories for figures and results objects.
  # If the original directory structure is maintained and the run_bart_surv.sh
  # script is located in Ross-et-al_PNAS2023/src/shell-scripting/, these will be
  # located in the Ross-et-al_PNAS2023/src/ directory.
  
  message("--Creating output directories")
  
  # Get the absolute path to the main Ross-et-al_PNAS2023 directory.
  script_dir_trimmed <- get_main_path(script_directory)
  
  # Build the absolute directory paths.
  res_path <- glue("{script_dir_trimmed}/results")
  fig_path <- glue("{script_dir_trimmed}/figures")
  
  # Create the directories (do not show warnings if directories alread exist).
  dir.create(res_path, showWarnings = FALSE)
  dir.create(fig_path, showWarnings = FALSE)
}