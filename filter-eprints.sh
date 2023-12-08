#!/usr/bin/env bash
# @file    filter-eprints.py
# @brief   Filter set of eprints records for Thomson lab project
# @created 2023-12-05
# @author  Mike Hucka <mhucka@library.caltech.edu>
#
# This script is meant to be run in the directory containing eprints record
# subdirectories as produced by eprints2bags. This means the current
# directory has subdirectories named 1, 2, 3, 4, 5, 6, ....

declare -a candidates
declare -a files

for dir in $(sort -n <(ls -1d [0-9]*)); do
    recordfile="$dir/$dir.xml"
    # The following gnarly yq command line looks inside the XML eprint record
    # file to select the <document> elements with <security> values of
    # "public" and then from the selected <document> elements, returns the
    # URLs of all <file> elements.
    candidates=($(yq ".eprints.eprint.documents.document[] | select(.security == \"public\") | .files.file |= ([] + .) | .files.file[].url" -op $recordfile))

    # Filter the list of files to keep only certain types of files.
    files=($((IFS=$'\n' && echo "${candidates[*]}") | egrep -i '(pdf|ps|bbl|bib|enl)$'))
    # In case of an empty list, the command above leaves one empty string in
    # the array -- I wish I could find a better way to remove it than this:
    for i in ${!files[@]}; do
        if [[ -z ${files[i]} ]]; then
           unset files[i]
        fi
    done

    # We only keep files that are public. If that leaves no files in a given
    # subdirectory, remove the subdirectory too.
    if [[ ${#files[@]} == 0 ]]; then
        echo "No acceptable files found in $dir"
        rm $dir/*
        rmdir $dir
        continue
    fi

    # Remove the files we're not keeping.
    files+=("$recordfile")
    for path in $dir/*; do
        file=${path##*/}
        if [[ ${files[@]} =~ "$file" ]]; then
            echo "$dir: keeping $file"
        else
            echo "$dir: discarding $file"
            rm $path
        fi
    done
    echo
done
