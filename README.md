# Collecting Caltech thesis PDFs for a Caltech project

For reproducibility and documentation purposes, this repository contains information and scripts used to select a subset of Caltech Thesis eprints for a faculty project in late 2023.

## Process followed

### 1. Download records from Caltech Thesis Eprints server

I used our [eprints2bags](https://github.com/caltechlibrary/eprints2bags) program to download all the public records, with flags to make `eprints2bags` leave the results unbagged and uncompressed. The command was:

```sh
eprints2bags -k -s "^inbox,buffer,deletion" -b none -e none -a https://thesis.library.caltech.edu/rest
```

This resulted in a directory containing a subdirectory for each thesis, named using its Eprints record id (which is an integer starting from 1). The result looks roughly like this:

```
...
├── 10262
│   ├── 10262.xml
│   └── spontaneous-pattern-formation.pdf
├── 10263
│   ├── 10263.xml
│   └── catanach_thesis_deposit.pdf
├── 10264
│   ├── 10264.xml
│   └── Song_Myungkoo_2017.pdf
├── 10265
│   ├── 10265.xml
│   └── teng-alexander-2017.pdf
├── 10266
│   ├── 10266.xml
│   └── Chun-Jen_Hsueh_final_version.pdf
...
```

### 2. Remove files that cannot be released publicly

I wrote a [filter script](filter-eprints.sh) to remove documents based on their release status as recorded in the Eprints XML metadata file of a given thesis record. The selection criteria was as follows:

1. The `<security>` element in the `<document>` element has a value of `public`.
2. The file name suffix is `pdf`, `ps`, `bbl`, `bib`, `enl`. (This choice was based on the fact that the group who wanted the theses was planning on doing machine learning on the text, so there seems to be no need to keep other files such as images or movies.)

If this resulted in no files other than the Eprints XML file left in a directory, then it removed the whole directory.

### 3. Scrub the Eprints XML metadata files

I wrote a [cleaning script](clean-xml.sh) script to edit the Eprints XML files, to remove metadata that the Library did not want to release. This included things like people's email addresses and internal communications.

### 3. Manually remove stragglers

A manual check of the thesis records that resulted from the steps above revealed a small number that contained this value in the metadata XML file:

```xml
<full_text_status>restricted</full_text_status>
```

These metadata records seemed to have inconsistent values for the other fields tested by the steps above, so I manually removed them from the final set and flagged them for review by Library staff.
