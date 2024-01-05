#!/usr/bin/env bash
# @file    list-zip-file-contents.sh
# @brief   Output a TSV file with the names of files inside zip files
# @created 2024-01-05
# @author  Mike Hucka <mhucka@library.caltech.edu>
#
# It's tab separated instead of comma separated because the file names
# inside the zip file may contain commas.
#
# Usage:
#     list-zip-file-contents.sh *.zip > output.tsv

shopt -s nocasematch

function print_row {
    echo -e "$1\t$2"
}

# Sort the list of zip files.
IFS=$'\n'
zip_files=($(sort <<<"$*"))
unset IFS

# Iterate through the zip files given as the arguments.
num_zip_files=${#zip_files[@]}
for (( index=0; index<=$num_zip_files; index++ )); do
    current_zip=${zip_files[index]}
    contents=($(unzip -Z1 "$current_zip" 2> /dev/null))

    # Sort the list of files inside this zip file.
    IFS=$'\n'
    sorted_contents=($(sort <<<"${contents[*]}"))
    unset IFS

    # Print the name of the zip file and the first item in it.
    print_row "$current_zip" "${sorted_contents[0]}"

    # Print the  remaining items but skip the zip current_zip name.
    num_files=${#sorted_contents[@]}
    for (( i=1; i<$num_files; i++ )); do
        print_row "." "${sorted_contents[i]}"
    done
done
