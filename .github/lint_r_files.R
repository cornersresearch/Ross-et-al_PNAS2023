# load necessary packages
if ("renv:shims" %in% search()) {
  # check if renv is being used in repo
  # then update renv with already installed packages
  message("Repo is using renv, re-hydrating packages from cache")
  renv::hydrate(c("magrittr", "stringr", "lintr"))
}
# for pipes
library(magrittr)
 # for regex matching
library(stringr)
# for linting (duh)
library(lintr)

# get all R and R Markdown files in the directory
all_r_files = list.files(pattern = "(\\.R$)|(\\.Rmd$)", ignore.case = TRUE, recursive = TRUE)

# filter out any R files in the `renv` directory
files_to_lint = all_r_files %>% .[!str_detect(., "^renv/")]

# takes linting output and prints a human-readable message
print_lint_msg = function(lint_vect) {
  message(paste(lint_vect["message"], "in line", lint_vect["line_number"], "of", lint_vect["filename"], sep = " "))
}

lint_results = lapply(files_to_lint, lint) %>% unlist(recursive = FALSE) %>% lapply(unlist)

# lintr only returns anything if there are issues found
# so if there are any linting results, issues were found and the test fails
if (length(lint_results) > 0) {
  lint_results %>% lapply(print_lint_msg)
  stop("Issues found in R scripts!")
}
cat("All R files are good!")
