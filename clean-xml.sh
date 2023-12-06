#!/usr/bin/env bash
# @file    clean-xml.py
# @brief   Clean the Eprints record XML files of stuff we can't share
# @created 2023-12-05
# @author  Mike Hucka <mhucka@library.caltech.edu>
#
# This script is meant to be run in the directory containing eprints record
# subdirectories as produced by eprints2bags. This means the current
# directory has subdirectories named, e.g., 1, 2, 3, 4, 5, 6, ....

for dir in $(sort -n <(ls -1d [0-9]*)); do
    recordfile="$dir/$dir.xml"
    echo $recordfile
    yq -i -o=xml 'del(.eprints.eprint.documents)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.creators.item.email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.creators.item[].email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.creators.item.show_email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.creators.item[].show_email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.thesis_advisor.item.email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.thesis_advisor.item[].email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.thesis_advisor.item.show_email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.thesis_advisor.item[].show_email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.thesis_committee.item.email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.thesis_committee.item[].email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.thesis_committee.item.show_email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.thesis_committee.item[].show_email)' $recordfile
    yq -i -o=xml 'del(.eprints.eprint.suggestions)' $recordfile
done
