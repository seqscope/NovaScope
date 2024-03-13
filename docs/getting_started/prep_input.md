
# Preparing Input

## 1. Input Data

The input data include 1st-seq and 2nd-seq FASTQ files and a histology file (optional).

Begin by creating a dedicated directory for your job. This directory will serve to identify the input configuration file (refer to *2. Prepare Input Config Files*) and to store log files.


### Example 1 - Regional Section Test Run

The input data originates from a specific, limited region of a section. No histology files is provided.

Now Download the first and second sequencing data sets from [here](https://www.dropbox.com/scl/fi/3egsr9nqc559e9hb45vik/B08Csub_20240301_raw.tar.gz?rlkey=z06xwb3v6ku19dp6br6mlsgkm&dl=0).

```
job_dir="$smk_dir/testrun/regional_section"  

mkdir -p  $job_dir && cd $job_dir
```

### Example 2 - Full Section Shallow Sequencing Test Run 

The input data is from a full section with an available histology file.

Download the first and second sequencing data sets from here. *TBC: Add the download link*

```
# Define the $job_dir
job_dir="$smk_dir/testrun/full_section_shallow"  

mkdir -p  $job_dir && cd $job_dir

# Download the histology file
wget https://historef-sample-data.s3.amazonaws.com/sample/b08c/histology.tif
```

## 2. Prepare Input Config Files

The pipeline necessitates a `config_job.yaml` file to define all inputs, outputs, and parameters. This `config_job.yaml` file should be provided in the `$job_dir`.

Separate example `config_job.yaml` files for the [regional](https://github.com/seqscope/NovaScope/blob/main/testrun/regional_section/config_job.yaml) and [full](https://github.com/seqscope/NovaScope/blob/main/testrun/full_section_shallow/config_job.yaml) section test runs are provided.  

Below, you'll find explanations for each item specified in the `config_job.yaml`.

```
## ================================================
##
## Mandatory Fields:
##
## ================================================

## Input Section
input:
  flowcell: <flowcell_id>
  section: <section_chip_id>
  specie: <specie_info>
  lane: <lane_id>             ## Optional. Auto-assigned based on section's last letter if absent (A->1, B->2, C->3, D->4).
  seq1st:
    prefix: <seq1st_id>       ## Optional. Defaults to "L{lane}" if absent.
    fastq: <path_to_seq1st_fastq_file>
    sbcd_layout_summary: <path_to_sbcd_layout_summary> ## Provide sbcd_layout_summary or sbcd_layout.
  seq2nd:                     ## List all input 2nd sequencing data here.
    - prefix: <seq2st_pair1_id>
      fastq_R1: <path_to_seq2nd_pair1_fastq_R1_file>
      fastq_R2: <path_to_seq2nd_pair1_fastq_R2_file>
    - prefix: <seq2st_pair2_id>
      fastq_R1: <path_to_seq2nd_pair2_fastq_R1_file>
      fastq_R2: <path_to_seq2nd_pair2_fastq_R2_file>
    # ...
  label: <seq2nd_version>     ## Optional. A version label for the input seq2 data, if applicable.

## Output Section
output: <output_directory>

request:                      ## Required output files. Options: "nbcd-per-section", "nmatch-per-section", "align-per-section", "nge-per-section", "hist-per-section"
  - <required_output1>
  - <required_output2>
  # ...

## Environment Section
env_yml: <path_to_config_env.yaml_file>## If absent, the pipeline will check if a "config_env.yaml" file exists in the Novascope directory.


## ================================================
##
##  Optional Fields:
## 
##    The "preprocess" and "histology" parameters are included below, along side the default value for each parameter.
##    Revise and enable the following parameters only if you wish to utilize values different than the default.
##
## ================================================

#preprocess:
#  fastq2sbcd:
#    format: DraI32
#  sbcd2chip:
#    gap_row: 0.0517
#    gap_col: 0.0048
#    dup_maxnum: 1
#    dup_maxdist: 0.1
#  smatch:
#    skip_sbcd: 1            ## If absent, skip_sbcd can be calculated follows the fastq2sbcd format: 1 for DraI31 and 0 for DraI32.
#    match_len: 27
#  align:
#    len_sbcd: 30
#    min_match_len: 30
#    min_match_frac: 0.66
#    resource:
#      assign_type: stdin    ## Options: "filesize", "stdin". If "filesize", there's no need to input the three values below, as the resources will be automatically determined based on the total size of the second set of sequencing FASTQ files. 
#      partition: standard
#      threads: 10
#      memory: 70000m
#  gene_visual: None         ## If you have a specific set of genes to visualize, specify the path to a file containing a list of gene names (one per line) here. By default, the top five genes with the highest expression are visualized.
#  visualization:
#    drawxy:
#      coord_per_pixel: 1000
#      intensity_per_obs: 50
#      icol_x: 3
#      icol_y: 4
#
#histology:
#    resolution: 10
#    figtype: "hne"          ## Options: "hne","dapi","fl"
```