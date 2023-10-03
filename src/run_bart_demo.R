# This script runs a demo of the analysis from start to finish. To run the demo,
# open an Rstudio session by loading the r-proj.Rproj file, then select this
# file from the Files pane and proceed line by line.


# Load demo functions; assumes the present working directory is the directory in
# which r-project.Rproj is located (achieved by loading this file from an
# RStudio session of the r-proj.Rproj project file).
source("src/extra_demo_functions.R")

# Prepare environment by loading additional functions and libraries.
prepare_demo_environment()

# Generate the model-specification object and the option parser; validate the
# inputs.
opt_parser <- generate_option_parser()
opt <- build_demo_opt()
validate_input(opt)

# Create output directories.
create_output_directories(opt$script_directory)

# Generate BART results.
bart_results_full <- run_bart_surv_demo(opt)

# Create a simpler version of the results file (contains plot).
bart_results_simple <- bart_results_full %>% list_modify(bart = NULL)

# Save simple results object.
save_results(bart_results_simple, results_type = 'simple')

# Save full results if desired; 167 MB.
save_results(bart_results_full, results_type = 'full')