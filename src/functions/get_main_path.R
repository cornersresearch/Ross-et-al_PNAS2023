get_main_path <- function(script_directory){
  # Get the absolute path to the main Ross-et-al_PNAS2023 directory. This will
  # be used to build directories and filenames.
  
  # If the framework is being run from a shell script, trim off the last two
  # directories (which will set it to be the Ross-et-al_PNAS2023 directory); if
  # the framework is being run from the R-project in Ross-et-al_PNAS2023, then
  # this will not trim anything off.
  script_directory %>% str_remove("/src/shell-scripting$")
}