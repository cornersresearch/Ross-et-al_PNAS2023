perc_same=$(dwdiff -s repo-template/README.md this-repo/README.md 2>&1 >/dev/null | cut -d " " -f 6 | tr -d "%" | head -1)
perc_added=$(dwdiff -s repo-template/README.md this-repo/README.md 2>&1 >/dev/null | cut -d " " -f 10 | tr -d "%" | head -1)
echo "Identical to template: $perc_same%"
echo "Added to template: $perc_added%"
if (( $perc_same > 95 || $perc_added < 5 )); then
   echo "Edit your README to add more relevant info!"
   exit 1
else
   echo "README looks good"
fi
