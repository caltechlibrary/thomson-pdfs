# Collecting Caltech thesis PDFs for a Caltech project

For reproducibility and documentation purposes, this repository contains information and scripts used to select a subset of Caltech Thesis eprints for a faculty project in late 2023.

## Process followed for PDF files

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


## Process followed for TeX/LaTeX files

Some of the records have associated Zip files on our Eprints server. The connection between the records and those Zip files were unfortunately broken during some past server move or server crash recovery. The effect is that the paths written in the XML record files are invalid, and can't be used to get to the Zip files directly. However, all is not lost: the XML files contain partial paths, and many of the Zip files are named uniquely enough that matching them up is possible.

### 1. Obtain all the Zip files

I staretd by downloading all the Zip files from the Eprints server. On our server, they are located in `/coda/eprints-3.3/archives/caltechthesis/documents/` in a subdirectory named `disk0`. The structure inside `disk0` is a pairtree, but the first level is always `00`, so the initial path is always `disk0/00`. Going inside `disk0/00`, we find two subdirectories, `00` and `01`, and then inside those, things get fuller: `00`, `01`, `02`, `03`, etc. The path to given Zip file will thus look like, for example,

```
disk0/00/01/01/10/07/Grinthal_ET_1969.zip
```

To make it easier to deal with the collection of Zip files, I copied all the Zip files and renamed them with a prefix corresponding to their path inside the pairtree. The result was a set of Zip files in a single directory named, e.g.,

```
disk00001613801-Jeanloz_R_1980.zip
disk00001613902-Bryson_rp_1937_minor.zip
disk00001614102-Scrivner_CW_1998.zip
disk00001614302-Jamele-LEWIS_1946.zip
```

Basically, this flattens the `disk0/00/...` structure and makes it part of the file name. The number of Zip files retrieved this way was 3870.


### 2. Find which zip files actually contain TeX/LaTeX files

Inspection of the zip files showed that most contained things like images, data files, spreadsheets, etc., and not TeX or LaTeX files. I wrote a simple script to look at the list of file names inside each Zip file and report those Zip files that contained a file name ending in `.tex` or containing `latexmk`. This script ([`find-zip-files-with-latex-contents.sh`](./find-zip-files-with-latex-contents.sh)) yielded a list of 615 Zip files.


### 3. Match Zip files to corresponding Eprints thesis records

Here is where things get difficult. Looking inside the Eprints records XML files, we can find an element `<dir>` that looks like, for example,

```xml
<dir>disk0/00/01/01/10</dir>
```

These paths are not the full paths of the directories containing the relevant zip files. If we take the initilal example above of the Zip file on disk,

```txt
disk0/00/01/01/10/07/Grinthal_ET_1969.zip
```

and compare it to the value of the `<dir>` element, we see that the file path on disk has an extra two digits (in this case, `07`). This means that given only the value of the `<dir>` element in a random XML file, we have 100 possible alternative paths where the zip file could be located in the disk structure. Not good.

However, things get better when we inspect the XML record files a little more closely. In the full original XML records, the are `<document>` elements, and it turns out that the records with Zip files have a `<url>` element containing URLs with the Zip file names. The URLs themselves are invalid – the URLs matching functionality got broken some point in the past, so the Eprints server simply doesn't recognize them as valid anymore – but there is something very interesting in those `<url>` element values. First, let's extract them all into a file.

```sh
grep -i 'http.*zip</url>' */*.xml |\
    sed 's,<url>,,g;s,</url>,,g' |\
    sort > ../records-with-zip-files.txt
```

The file [`outputs/records-with-zip-files.txt`](outputs/records-with-zip-files.txt) contains the results. They look like this:

```txt
10000/10000.xml: https://thesis.library.caltech.edu/10000/14/Cox_Stephen_2016_raw_files.zip
10001/10001.xml: https://thesis.library.caltech.edu/10001/65/Dong_Sijia_Dec2016_thesis_LaTeX_source.zip
10001/10001.xml: https://thesis.library.caltech.edu/10001/66/Dong_Sijia_Dec2016_thesis_GPCR_supp_PDB.zip
10002/10002.xml: https://thesis.library.caltech.edu/10002/73/optics-high-efficiency.zip
```

Notice that each URL contains repeats the record id _and has two additional digits_. Could the two digits be the same two digits missing from in the `<dir>` values? Can we simply append the two digits to the paths we have, and find the Zip file at that location? The answer is _mostly yes_. Many records have multiple URL values, and not all match the Zip files we can find on disk. But many others, and we're helped by the fact that we only need to consider the subset of 615 Zip archives.

We can first create a list of candidate full file names from the results in [`outputs/records-with-zip-files.txt`](outputs/records-with-zip-files.txt):

```sh
cut -f1,5-9 -d'/' < records-with-zip-files.txt |\
    sed 's,/,:,' |\
    sed 's,/\([0-9]\)/,/0\1/,g' |\
    sed 's,:\([0-9][0-9][0-9][0-9]\)/,:0\1/,g' |\
    sed 's,/,,1' |\
    tr '/' '-' |\
    sed 's,:\(.*\),:disk000\1,g' |\
    sort
```

(The second `sed` expression above replaces cases of single digits like `/7/` with `/07/`, i.e., zero-padding the value, while the third sed expression does the same with 4-digit values.) The above produces a list of pairs of _id_:_filename_, like this:

```txt
10000:disk0001000014-Cox_Stephen_2016_raw_files.zip
10001:disk0001000165-Dong_Sijia_Dec2016_thesis_LaTeX_source.zip
10001:disk0001000166-Dong_Sijia_Dec2016_thesis_GPCR_supp_PDB.zip
10002:disk0001000273-optics-high-efficiency.zip
10016:disk0001001607-Li_X_1998.zip
```

These pairs are saved in the file [`candidates`](outputs/candidates.txt) in this repository. Now we can try to match the file names in that file (which are the names of all Zip files referenced in all XML records) against the 615 Zip files we determined actually do contain TeX/LaTeX files.

Doing this resulted in 608 matches, which is almost our entire set of candidate Zip files. This means that we now have the record id's for nearly all the Zip files that contain TeX/LaTeX files.

A simple script can be used to move the matched Zip archives into a set of directories named according to the Eprints record id's. That's the script [`file-latex-zip-archives.sh`](./file-latex-zip-files.sh).

The final tally is 599 Zip files moved into 584 record directories. The smaller number of directories is explained by the fact that some records matched multiple Zip files. The difference between 599 and 608 is unclear but most likely due to the fact that a few of the Zip files have names containing special characters, such as parentheses, which probably caused the simple script above to fail in some way.
