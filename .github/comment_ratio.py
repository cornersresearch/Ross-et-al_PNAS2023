import json
import os
import subprocess

import pandas as pd

RATIO_THRESHOLD = 25


def run_cloc(file_path):
    """
    Runs cloc (an external CLI tool) to count lines of code
    :param file_path: a string with a path to a file
    :return: a dict of cloc results
    """
    # define arguments for cloc, '--by-percent='cm' to calculate ratio from code and comment lines EXCLUDING blank lines
    cmd_args = ['cloc', "--vcs='git'", '--exclude-dir=,.github,renv,venv',
                '--exclude-lang=Markdown', "--by-percent='cm'", '--json', file_path]
    stdout_results = subprocess.run(" ".join(cmd_args), shell=True, check=True, capture_output=True).stdout
    # cloc will output no results if it is a file that is excluded
    if stdout_results is not None and stdout_results.decode('utf-8') != '':
        return json.loads(stdout_results)
    return None


print('Scanning ' + os.getcwd())
# get results for entire repo
directory_results = run_cloc('.')
# get list of files to get results for each file
file_list = subprocess.run('git ls-files', shell=True, check=True, capture_output=True).stdout.decode('utf-8').split(
    '\n')

print('\n~~~~~Individual Results~~~~~')
file_below_thresh = False
for individ_path in file_list:
    # a blank string will just produce results for whole directory, so we want to exclude it
    if individ_path != '':
        results = run_cloc(individ_path)
        # results are None if file was excluded, so we can ignore
        if results is not None:
            # report ratio to developer if it is lower than threshold
            # test is not failed if a single file is lower than threshold to allow some flexibility
            ratio_result = results['SUM']['comment']
            if ratio_result < RATIO_THRESHOLD:
                # check if this is the first file below the threshold and print an intro message
                if not file_below_thresh:
                    print('Files with a comment to code ratio below the threshold:')
                    file_below_thresh = True
                # print tab to emphasize specific results, f-strings don't support tabs
                print('\t', end='')
                print(f'{individ_path}: {str(round(ratio_result, 1)) + "%"}')

# print some positive encouragement when all files are above the comment threshold
if not file_below_thresh:
    print('All files are above the comment to code ratio threshold')
    print('You get a gold star! ⭐')

# convert results to a DataFrame for easier wrangling
results_df = pd.DataFrame(directory_results)
# drop overall stats and make row labels into a column
cleaned_results = results_df[results_df['header'].isna()].drop(columns='header').rename_axis(
    'new_head').reset_index()
# for some reason cloc outputs the SUM results with headers not ending in '_pct'
# so to make the table look better we'll remove '_pct' from other row labels
cleaned_results['new_head'] = cleaned_results['new_head'].str.replace('_pct', '').str.replace('nFiles',
                                                                                              'n_files').str.replace(
    'code', 'n_code_lines')
# convert the raw float values to pretty formatted percent strings
pivot_results = cleaned_results.pivot_table(columns='new_head').applymap(lambda x: round(x, 1))
pivot_results[['blank', 'comment']] = pivot_results[['blank', 'comment']].astype(str).apply(lambda x: x + '%')
pivot_results[['n_code_lines', 'n_files']] = pivot_results[['n_code_lines', 'n_files']].apply(
    lambda x: round(x, 0)).astype(str)

print('\n~~~~~~Overall Results~~~~~~')
print("All percents are out of the total number of code lines + comment lines")
# requires tabulate, output in a pretty markdown-style table
print(pivot_results.to_markdown(tablefmt="grid"))

# total comment ratio for entire directory is used to determine if test should fail
if directory_results['SUM']['comment'] < RATIO_THRESHOLD:
    exit("Comment to code ratio too low!")
exit(0)
