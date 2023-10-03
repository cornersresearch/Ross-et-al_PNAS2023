# This script prepares the environment by loading the necessary elements
# (libraries, functions, model specification, and datasets).
# 
# Load in this order:
#     -Libraries
#     -Functions
#     -Arguments from the terminal
#     -Data

message("\n\nPreparing R environment...\n")

message("--Loading libraries")
source("../packages.R")


message("--Loading functions")
walk(list.files("../functions/", full.names = TRUE), source)



# Build a parser to identify arguments passed to the shell script. Then parse
# the arguments passed via the script.
message("--Parsing arguments from the terminal")
opt_parser <- generate_option_parser()
model_spec <- parse_args(opt_parser)

# Validate the input from the terminal.
validate_input(model_spec)

# Create output directories relative to the shell script's directory.
create_output_directories(model_spec$script_directory)


message("--Loading datasets")
source("../import.R")