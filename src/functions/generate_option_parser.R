generate_option_parser <- function(){
  # Define the arguments to be passed from the shell script (run_bart_surv.sh).
  # 
  # Option flags: o s g z v e l t n h
  # -o: Organization name(s)
  # -s: Event status type(s)
  # -g: Whether the control group should be geo-restricted (TRUE/FALSE)
  # -z: Desired (approximate) control group size
  # -v: Name of treatment variable
  # -e: Seed
  # -l: Name(s) of variable(s) on which to balance
  # -t: Path to directory in which this script is located
  # -n: Name of configuration file
  # -h: Datetime at which the call to the R script is initiated
  
  
  option_list <- list(make_option(opt_str = c("-o", "--organization"),
                                  type = "character",
                                  default = NULL, 
                                  help = "Organization name(s) (and possibly CRED cohort)"),
                      make_option(opt_str = c("-s", "--status_type"),
                                  type = "character",
                                  default = NULL, 
                                  help = "Survival type (victimization, violent arrest, or either)"),
                      make_option(opt_str = c("-g", "--geo_restrict"),
                                  type = "logical",
                                  default = NULL,
                                  help = "Limit control group to arrestees in treatment police districts"),
                      make_option(opt_str = c("-z", "--cg_size"),
                                  type = "integer",
                                  default = 2500, 
                                  help = "Desired size of control group"),
                      make_option(opt_str = c("-v", "--treatment_variable"),
                                  type = "character",
                                  default = NULL, 
                                  help = "Name of variable that indicates whether an observation is in the treatment or control group"),
                      make_option(opt_str = c("-e", "--seed"),
                                  type = "integer",
                                  default = 1, 
                                  help = "Seed for reproducibility"),
                      make_option(opt_str = c("-l", "--balance"),
                                  type = "character",
                                  default = NULL,
                                  help = "Balance groups on these variables (space separated, in quotes)"),
                      make_option(opt_str = c("-t", "--script_directory"),
                                  type = "character",
                                  default = NULL, 
                                  help = "Path to directory containing the run_bart_surv.sh script"),
                      make_option(opt_str = c("-n", "--config_name"),
                                  type = "character",
                                  default = NULL, 
                                  help = "Name of the configuration file"),
                      make_option(opt_str = c("-h", "--datetime"),
                                  type = "character",
                                  default = NULL, 
                                  help = "Datetime (string) the script began running this model"))
  
  # Return the option parser (will be used to parse input arguments from the
  # shell).
  opt_parser <- OptionParser(option_list = option_list, add_help_option = FALSE)
  
  return(opt_parser)
}