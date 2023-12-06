#!/usr/bin/env bash
# @file    filter-eprints.py
# @brief   Filter set of eprints records for Thomson lab project
# @created 2023-12-05
# @author  Mike Hucka <mhucka@library.caltech.edu>
#
# This script is meant to be run in the directory containing eprints record
# subdirectories as produced by eprints2bags. This means the current
# directory has subdirectories named 1, 2, 3, 4, 5, 6, ....

declare -a files

for dir in $(sort -n <(ls -1d [0-9]*)); do
    recordfile="$dir/$dir.xml"
    # The following gnarly yq command line looks inside the XML eprint record
    # file to select the <document> elements with <security> values of
    # "public" and then from the selected <document> elements, return the
    # URLs of all <file> elements.
    files=($(yq ".eprints.eprint.documents.document[] | select(.security == \"public\") | .files.file |= ([] + .) | .files.file[].url" -op $recordfile))

    # We only keep files that are public. If that leaves no files in a given
    # subdirectory, remove the subdirectory too.
    if [[ ${#files[@]} == 0 ]]; then
        echo "No acceptable files found in $dir"
        rm $dir/*
        rmdir $dir
    fi

    # Filter the list of files to keep only certain files and remove any
    # other files in the subdirectory.
    keepers=$((IFS=$'\n' && echo "${files[*]}") | egrep -i '(pdf|ps|bbl|bib|enl)$')
    keepers+=("$recordfile")
    for path in $dir/*; do
        file=${path##*/}
        if [[ ${keepers[@]} =~ "$file" ]]; then
            echo "$dir: keeping $file"
        else
            echo "$dir: discarding $file"
            rm $path
        fi
    done
    echo
done
