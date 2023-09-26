Demo BART Survival Analysis Code for _Ross et al. 2023, Evaluating the impact of a street outreach intervention on participant involvement in gun violence, PNAS_
================
**Repo Manager:** Marisa Ross & Erin M. Ochoa <br />
**Last updated:** September 26, 2023

## Overview

This repo contains demonstration code (in R) for using Bayesian Additive Regression Trees (BART) along with Survival Analysis to 
estimate the effect of outreach services on *victimization* and/or *arrest for a violent offense* among participants. A version
of this code base was used to estimate survival probabilities for victimization and arrest for a violent offense for participants
in Chicago CRED. Analyses and methodologies are presented in *Ross et al. 2023, Proceedings of the National Academies of Sciences*. 

## Methodology

The methodology has two parts:

- Generate a demonstration dataset, randomly assigning participants and balancing the comparison sample on covariates of interest
- A BART survival framework for analyzing the survival response, that is, the time to victimization or arrest for a violent offense.


## Data from the original paper

Due to the highly-sensitive nature of gunshot victimization, arrest, and street outreach program data, original data from paper cannot
be provided here. Instead, this repo contains code for generating a demo dataset with the same variables and balancing methods used in
the original paper. 

## BART Survival Analysis

The survival models require much in the way of computing resources---processing power, memory, and drive space.  Furthermore, 
each model requires a number of specifications (organization, status type, etc.).  Because of these needs, we recommend that the survival 
framework be restructured to run through a shell script with parameters specified in a configuration file when using real, large datasets. 
The shell script should support running multiple organizations and multiple survival types from a single configuration file, with the rest 
of the specifications fixed.  If multiple organizations and/or survival types are specified, the script will run the models in succession.

For each model, full and abbreviated (with input dataset, parameters, mean survival probabilities, and ggplot object), analysis results are
saved in RDS format, along with a plot (PDF) of the survival curves.


##### R Framework

- `src/run_bart_demo.R`: This script loads the `src/extra_demo_functions.R` script (see below for details), calls for building and validating the
  model options, and creates output directories. It ultimately carries out the analysis and saves the results (both full and abbreviated).

- `src/prepare_demo_environment.R`: This script calls a number of other R modules to load libraries and define functions. 

  - `src/packages.R`: This script loads the libraries necessary for the framework

- Options for building models with `build_demo_opt()` function:
  - `organization`: Space-separated list of organization names
  - `status_type`: Space-separated list of survival types
  - `geo_restrict`: Boolean; defines whether the pool of control units should be limited to those with an arrest within the geographic areast that overlap treatment community areas
  - `cg_size`: Desired size of control group
  - `treatment_variable`: Name of the treatment variable
  - `seed`: Used to set the seed for selecting the control group, assigning their start dates, and running the BART survival analysis
  

## Table of Contents
  - [src/](src/)
      - [extra_demo_functions.R](src/extra_demo_functions.R): Includes functions for setting up the R environment and building models
      - [run_bart_demo.R](src/run_bart_demo.R): Generates sample and runs BART survival analysis by calling relevant functions
      - [functions/](src/functions/): Directory containing the needed functions for BART survival analysis  
  - [objects/](objects/)
      - Currently empty; will hold figures etc


## References

1. M. C. Ross, E. O. Ochoa, & A. V. Papachristos. Evaluating the impact of a street outreach intervention on participant involvement in gun violence. *PNAS* (2023)
2. J. L. Hill, Bayesian Nonparametric Modeling for Causal Inference. *Journal of Computational and Graphical Statistics* 20, 217–240 (2011)
3. H. A. Chipman, E. I. George, R. E. McCulloch, BART: BAYESIAN ADDITIVE REGRESSION TREES. *The Annals of Applied Statistics* 4, 266–298
4. D. P. Green, H. L. Kern, Modeling Heterogeneous Treatment Effects in Survey Experiments with Bayesian Additive Regression Trees. *Public Opinion Quarterly* 76, 491–511 (2012)
5. R. A. Sparapani, B. R. Logan, R. E. McCulloch, P. W. Laud, Nonparametric survival analysis using Bayesian Additive Regression Trees (BART). *Statist. Med.* 35, 2741–2753 (2016)
6. G. Wood, A. V. Papachristos, Reducing gunshot victimization in high-risk social networks through direct and spillover effects. *Nat Hum Behav* 3, 1164–1170 (2019)





