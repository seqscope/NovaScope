
# Accessing Example Datasets

## Dataset Overview

There are three example datasets published with the NovaScope protocol. Each input dataset contains two types of FASTQ files: (a) 1st-seq (single-end) FASTQ file that contains spatial barcodes to construct a barcode map, and (b) 2nd-seq (paired-end) FASTQ files that contains spatial barcodes in Read 1, and cDNA sequences in Read 2. 

### Minimal Test Run Dataset

This is a small (1.14GB) test run dataset comprising of a subset of the (shallow) liver section data described in [Shallow Liver Section Dataset](#shallow-liver-section-dataset). This dataset is meant to be used to test the sanity of the pipeline, without necessarily offering biologically meaningful interpretation of data. 

### Shallow Liver Section Dataset

This dataset is a typical (23.7GB) example of Seq-Scope dataset that can be initially generated for a tissue section. Typically, the 2nd-seq FASTQ files contain 150-200M paired-end reads. This should be sufficient to examine the spatial distribution of the transcripts across the tissue, assess the quality of dataset, identify major cell types and marker genes, and perform basic pixel-level decoding of the spatial transcriptome. If the quality of the initial dataset look great, one may decide to sequence the library much more deeply to maximize the information content. (see [Deep Liver Section Dataset](#deep-liver-section-dataset) for more details)

### Deep Liver Section Dataset

If the initial examination of the [shallow dataset](#shallow-liver-section-dataset) looks promising, one can sequence the library much more deeply, to the level of saturating the library. A deeply sequenced dataset typically contains multiple pairs of FASTQ files, possibly across multiple sequencing runs. The deeply sequenced liver section dataset, available at [https://doi.org/10.7302/tw62-4f97](https://doi.org/10.7302/tw62-4f97), has 7 pairs of FASTQ files (250GB) in addition to the [shallow dataset](#shallow-liver-section-dataset).

## Downloading the Datasets

Each of the three datasets have their own DOIs, which can be accessed using the URLs below.

* Minimal Test Run Dataset (1.14GB) : [https://doi.org/10.5281/zenodo.10835761](https://doi.org/10.5281/zenodo.10835761)

```bash
## To download the tarball from Zenodo, you can use the following command
wget "https://zenodo.org/records/10835761/files/B08Csub_20240318_raw.tar.gz"

## uncompress the tarball using the following command:
mkdir B08Ctest
cd B08Ctest
tar xzvf ../B08Csub_20240318_raw.tar.gz
```

* Shallow Liver Section Dataset (23.7GB) : [https://doi.org/10.5281/zenodo.10840696](https://doi.org/10.5281/zenodo.10840696) 

```bash
## To download the tarball from Zenodo, you can use the following command

## create a directory to store the data
mkdir B08Cshallow
cd B08Cshallow

## download the 1st-seq FASTQ file
wget "https://zenodo.org/records/10840696/files/9203-AP.L3.B08C.R1_001.fastq.gz"

## download the 2nd-seq FASTQ files (R1 and R2)
wget "https://zenodo.org/records/10840696/files/9748-YK-3_CGAGGCTG_S3_R1_001.fastq.gz"
wget "https://zenodo.org/records/10840696/files/9748-YK-3_CGAGGCTG_S3_R2_001.fastq.gz"

## Additionally, you may want to download md5sum files 
## to verify the integrity of the downloaded files
```

* Deep Liver Section Dataset (250GB) : [Link to Deep Blue Data](https://doi.org/10.7302/tw62-4f97) 
    - Note that you need to use [Globus](https://www.globus.org/) to download the dataset.
    - Note that this dataset contains only additional 2nd-seq FASTQ files in addition to the [Shallow Liver Section Dataset](#shallow-liver-section-dataset), so you need to download the shallow dataset first. 