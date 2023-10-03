#!/usr/bin/env bash

##### This script takes as an argument the name of the configuration file that
##### defines the parameters of the BART model to be run by R.

###### This shell script must be called with the name of the configuration file.
###### For example, if config_file.config is in the same directory as this
###### script, call the script with:
######     sh run_bart_surv.sh config_file.config

###### It is recommended that the configuration file name be descriptive and
###### include the parameters specified within the file as well as the run date,
###### as this will aid the user in quickly assessing the parameters of models
###### run with different configuration files.
###### For example, a script run on 2023 September 30 for the DemoOrgName
###### organization, for all three status types (victim, arrest, and either),
###### with a geo-restricted control group of size 100, with the treatment
###### variable called tx, with the seed set to 1, balanced on male, black,
###### hispanic, gang, victimization, and year of birth, would have the
###### following file name:
######     20230930_org-DemoOrgName_status-victim-arrest-either_geo-TRUE_cg-100_treat-tx_seed-1_bal-male-black-hisp-gang-arrest-vic-yob.config
###### HOWEVER, note that the name of the configuration file DOES NOT affect the
###### arguments that are parsed from within the configuration file by this
###### script; in other words, if the format of the configuration file name does
###### not match the arguments within the configuration file, it is immaterial
###### and this script will nevertheless read the arguments specified within the
###### configuration file.

# Set the first argument (the name of the configuration file).
config=$1

# Load the variables in the configuration file.
. $config

# This is the path in which this script is located.
# stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# This is the name of the configuration file with the model specifications.
CONFIG_NAME=$1

# Navigate to this script's directory (outreach_individual/src/shell-scripting)
# as all the R scripts depend on being here.
cd $(dirname "$0")


# # Declare model specification.
# # Option flags: o s g z v e l t n h
# -o: Organization name(s)
# -s: Event status type(s)
# -g: Whether the control group should be restricted geographically (TRUE/FALSE)
# -z: Desired (approximate) control group size
# -v: Name of treatment variable
# -e: Seed
# -l: Name(s) of variable(s) on which to balance
# -t: Path to directory in which this script is located
# -n: Name of configuration file
# -h: Datetime at which the call to the R script is initiated


for Organization in $ORGANIZATIONS
# Loop through organizations and run the R script.
do
  # Assign to the $org parameter (can't pass $Organization to the Rscript call).
  org=${Organization:-o}
  
  for Status_Type in $STATUS_TYPE
  # Loop through survival types and run one model for each.
  do
    # Assign to the $status_type parameter (can't pass $Status_Type to the
    # Rscript call).
    status_type=${Status_Type:-s}
    datetime=$(date +%Y%m%d_%H-%M-%S)
      # Print organization name with model specification.
      printf "\n"
      printf "%.s*" {1..80}
      
      # Print the model specification.
      printf "\n\nInitializing BART survival analysis with parameters:\n"
      printf "\n%*s: %s" 36 "Organization" $Organization
      printf "\n%*s: %s" 36 "Survival mode" $Status_Type
      printf "\n%*s: %s" 36 "Geographically limited control group" $GEO_RESTRICT
      
      printf "\n%*s: %s" 36 "Approximate control group size" $CG_SIZE
      printf "\n%*s: %s" 36 "Treatment variable name" $TREATMENT_VARIABLE
      printf "\n%*s: %s" 36 "Seed" $SEED
      
      # Balance may have multiple space-separated variables, so enclose in
      # quotation marks.
      printf "\n%*s: %s" 36 "Balance sample on" "$BALANCE"
      
      printf "\n%*s: %s\n" 36 "Path to this script" $SCRIPT_PATH
      printf "\n%*s: %s" 36 "Name of the configuration file" $CONFIG_NAME
      printf "\n%*s: %s" 36 "Date-time of script initiation" $datetime
      printf "\n"
      
      # Pass all the arguments to the R script (break to new line with "\").
      Rscript run_bart_surv.R -o $org -s $status_type -g $GEO_RESTRICT\
                              -z $CG_SIZE -v $TREATMENT_VARIABLE -e $SEED\
                              -l "$BALANCE" -t $SCRIPT_PATH -n $CONFIG_NAME\
                              -h $datetime
  done
  printf "\n\n"
done