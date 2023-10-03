# This script is intended to be run using a shell script (which must be located
# at outreach_individual/src/shell-scripting/run_bart_surv.sh) that can loop
# through any combination of organizations and survival types. The parameters
# should be set in a .config file, which is passed as an argument to the shell
# script. For record-keeping purposes, USE A NEW CONFIG FILE EACH TIME.
# 
# The call, from the terminal and in the src/shell-scripting directory, should
# look like this:
#                ./run_bart_surv.sh [path to and name of config file].config
# 
# Note that the script can be executed while working in a different directory,
# as long as the correct path to the script is specified.


# The relative location depends on whether we are running this script from the
# outreach_individual/outreach.Rproj project or from the shell script.
wd <- getwd()


# Note the script changes the working directory to that of the *shell script*
# (that is, outreach_individual/src/shell-scripting). This means we need to go
# up one level to get to the prepare_environment.R file.
source("../prepare_environment.R")


# The model_spec object has been loaded with prepare_environment.R.


# Build the BART model and get the full results object.
results_full <- run_bart_survival(model_spec)


# Make a lightweight version of the results, in case the larger file is
# corrupted.
results_simple <- results_full %>% list_modify(bart = NULL)


# Save the results, SIMPLE FIRST, in case something fails with the larger file.
save_results(results_simple, "simple")
save_results(results_full, "full")