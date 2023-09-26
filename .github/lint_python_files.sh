python_scripts=$(git ls-files | grep -v 'venv' | egrep -v '^\.' | egrep '\.(py)$')
jupyter_notebooks=$(git ls-files | grep -v 'venv' | egrep -v '^\.' | egrep '\.(ipynb)$')
issues=''

# check if variable is not empty
if ! test -z "$python_scripts"
then
  echo -n "Linting python scripts"
  for py_sc in $python_scripts
  do
    cur_iss=$(pylint --score='no' $py_sc | egrep -v '\*\*\*\*\*\*\*\*\*\*\*\*\* Module .*$') # remove header text from results
    # check if variable is not empty
    if ! test -z "$cur_iss"
    then
      # newline needed for proper formatting
      issues="$issues"$'\n'"$cur_iss"
    fi
  done
  echo " - complete!"
else
  echo "No python scripts found!"
fi

# check if variable is not empty
if ! test -z "$jupyter_notebooks"
then
  echo -n "Linting jupyter notebooks"
  for jup_nb in $jupyter_notebooks
  do
    # remove header text from results
    cur_iss=$(nbqa pylint --score='no' $jup_nb | egrep -v '\*\*\*\*\*\*\*\*\*\*\*\*\* Module .*$')
    # check if variable is not empty
    if ! test -z "$cur_iss"
    then
      # newline needed for proper formatting
      issues="$issues"$'\n'"$cur_iss"
    fi
  done
  echo " - complete"
else
  echo "No jupyter notebooks found!"
fi

# check if variable is not empty
if ! test -z "$issues"
then
  echo $'\nIssues in python code found'
  # print out output from linting tools - listing code issues
  echo "$issues"
  # exit with error to trigger test failure
  exit 1
fi
