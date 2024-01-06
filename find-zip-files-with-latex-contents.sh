#!/usr/bin/env bash
# @file    find-zip-files-with-latex-content.sh
# @brief   Look through eprints zip files looking for tex/latex sources
# @created 2023-12-05
# @author  Mike Hucka <mhucka@library.caltech.edu>
#
# Usage:
#     # Go to the directory containing the zip files, then:
#     find-zip-files-with-latex-content.sh *.zip

shopt -s nocasematch

for file in "$@"; do
    contents=($(unzip -Z1 $file 2> /dev/null))
    for item in ${contents[@]}; do
        if [[ "$item" =~ (\.tex|latexmk)$ ]]; then
            echo "$file"
            continue 2
        fi
    done
done
