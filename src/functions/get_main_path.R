get_main_path <- function(script_directory){
  # Get the absolute path to the main outreach_individual directory. This will
  # be used to build directories and filenames.
  
  # If the framework is being run from a shell script, trim off the last two
  # directories (which will set it to be the outreach_individual directory); if
  # the framework is being run from the R-project in outreach_individual, then
  # this will not trim anything off.
  script_directory %>% str_remove("/src/shell-scripting$")
}