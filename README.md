Repo Template
================
**Repo Manager:** Adam Shelton <br />
**Last updated:** November 29, 2021

## Overview

This repo is a template that is used to create new repos on the N3
GitHub org. It includes a .gitignore file that should prevent data files
and other unnecessary files from being pushed to a repo, a README
template in both raw Markdown and R Markdown formats, and other
configuration files for virtual environments and GitHub Actions
workflows.

**IMPORTANT:**

Before creating a new repo, review the [Quantitative Workflow
Documentation](https://github.com/n3-initiative/Quantitative-Data-Documentation/wiki/Quantitative-Data-Analysis-Workflow).
It contains policies you ***must*** follow throughout the development
cycle to maintain access, quality, and reproducibility of all projects.
The documentation is updated regularly, so check it regularly!

**How to use this repo template:**

1.  Click the `Use this template` button above. This will create a new
    repo with the contents of this one. You can find more information
    about repo templates
    [here](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-from-a-template).

2.  In this new repo, if you **are not** using R delete the R Markdown
    template. Then, ***edit the README*** to add the appropriate title,
    Repo Manager, and other content. **DO NOT add code to your repo if
    you have not first removed this template text and added an adequate
    explanation of your project to the README.** The R Markdown README
    will automatically put the current date in
    `full_month_name day, year` format when knitted. If you are not
    using R, make sure to update the date as you update the repo.

3.  If you are creating a repo that is only a single R Markdown document
    without any other scripts or documents/reports, you can omit the
    “Documents and Reports” and “Table of Contents” sections and include
    your content at the end of this README.

This Overview section should be used to give a brief abstract of your
project.

## Documents and Reports

If you have any important documents or reports you want people to view,
make sure to put them here.

Use the following format:

-   ***[Title of Document 1](path/to/document.pdf)***
-   ***[Title of Document 2:](path/to/document.pdf)*** *a short
    description of this document (if necessary)*

## Methodology

Briefly describe the most essential parts of your methodology, making
sure to include the names of datasets that were used and a link or
reference to any external datasets. Give an in-depth description of any
code or scripts you need to run the project, including the order they
should be run in and any unusual dependencies, quirks, or features you
think others should know about to reproduce your project.

## Table of Contents

A linked table of contents for all the files on the repo (you *do not*
need to list the files included in the template here)

Follow the format used below:

-   **[.github:](.github/)** *contains scripts and configs for GitHub
    Actions workflows*
    -   **[comment_ratio.py:](.github/comment_ratio.py)** *calculates
        comment to code ratio for all python files*
    -   **[diff_files.sh:](.github/diff_files.sh)** *calculates
        differences between README in a repo and this template*
    -   **[lint_python_files.sh:](.github/lint_python_files.sh)** *lints
        all python files*
    -   **[lint_r\_files.R:](.github/lint_r_files.R)** *lints all R
        files*
    -   **[var_scan.sh:](.github/var_scan.sh)** *scans all files for
        unhelpful variable names*
    -   **[workflows:](.github/workflows)** *contains configs for GitHub
        Actions workflows*
        -   **[check-var-names.yaml:](.github/workflows/check-var-names.yaml)**
        -   **[comment-ratio.yaml:](.github/workflows/comment-ratio.yaml)**
        -   **[diff-readme.yaml:](.github/workflows/diff-readme.yaml)**
        -   **[lint-python.yaml:](.github/workflows/lint-python.yaml)**
        -   **[lint-r.yaml:](.github/workflows/lint-r.yaml)**
        -   **[pr-review-reminder.yaml:](.github/workflows/pr-review-reminder.yaml)**
        -   **[update-actions.yaml:](.github/workflows/update-actions.yaml)**
-   **[.gitignore:](.gitignore)** *keeps specified files from being
    tracked by `git`*
-   **[.Rbuildignore:](.Rbuildignore)** *keeps specified files from
    being included in an R package*
-   **[.Rprofile:](.Rprofile)** *runs R commands on load of project*
-   **[r-project.Rproj:](r-project.Rproj)** *config file/shortcut to
    load the R project for this repo*
-   **[README.md:](README.md)** *README Markdown file - describes your
    project/repo*
-   **[README.Rmd:](README.Rmd)** *R Markdown file to generate README
    file*
-   **[renv:](renv/)** *contains scripts and configs required for `renv`
    (see [Quant Workflow
    Docs](https://github.com/n3-initiative/Quantitative-Data-Documentation/wiki/Quantitative-Data-Analysis-Workflow)
    for more info)*

## References

No one likes plagiarizers, cite your work!
