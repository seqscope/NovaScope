
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


### Example 3 - Full Section Deep Sequencing Test Run 

The input data is from a full section with an available histology file.

Download the first and second sequencing data sets from here. *TBC: Add the download link*

```
# Define the $job_dir
job_dir="$smk_dir/testrun/full_section_deep"  

mkdir -p  $job_dir && cd $job_dir

# Download the histology file
wget https://historef-sample-data.s3.amazonaws.com/sample/b08c/histology.tif
```

## 2. Prepare Input Config Files

The pipeline necessitates a `config_job.yaml` file to define all inputs, outputs, and parameters. This `config_job.yaml` file should be provided in the `$job_dir`.

Separate example `config_job.yaml` files for the [regional section](https://github.com/seqscope/NovaScope/blob/main/testrun/regional_section/config_job.yaml), [full section shallow](https://github.com/seqscope/NovaScope/blob/main/testrun/full_section_shallow/config_job.yaml), and [full section deep]() test runs are provided.  

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
    layout: <path_to_sbcd_layout>
  seq2nd:                     ## List all input 2nd sequencing data here.
    - prefix: <seq2st_pair1_id>
      fastq_R1: <path_to_seq2nd_pair1_fastq_Read1_file>
      fastq_R2: <path_to_seq2nd_pair1_fastq_Read2_file>
    - prefix: <seq2st_pair2_id>
      fastq_R1: <path_to_seq2nd_pair2_fastq_Read1_file>
      fastq_R2: <path_to_seq2nd_pair2_fastq_Read2_file>
    # ...
  label: <seq2nd_version>     ## Optional. A version label for the input seq2 data, if applicable.

## Output Section
output: <output_directory>

request:                      ## Required output files. Options: "sbcd-per-section", "smatch-per-section", "align-per-section", "sge-per-section", "hist-per-section"
  - <required_output1>
  - <required_output2>
  # ...

## Environment Section
env_yml: <path_to_config_env.yaml_file> ## If absent, the pipeline will check if a "config_env.yaml" file exists in the Novascope directory.


## ================================================
##
##  Optional Fields:
## 
##    The "preprocess" and "histology" parameters are included below, along side the default values.
##    You only need to revise and enable the following parameters if you wish to utilize values different than the default.
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
#  dge2sdge:
#      layout: null          ## If absent, the layout file in the info/assets/layout_per_section_basis/layout.1x1.tsv will be used for RGB plots.
#  gene_visual: null         ## If you have a specific set of genes to visualize, specify the path to a file containing a list of gene names (one per line) here. By default, the top five genes with the highest expression are visualized.
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



### Input

#### seq1st

**`prefix`**

The `prefix` will be used to organize the 1st-seq FASTQ files. Make sure the `prefix` parameter in the corresponding flowcell is unique.  

**`sbcd_layout_summary`**

A file summarizes the tile information for section chips with the following format. You only need to supply either `sbcd_layout_summary` or `sbcd_layout`, not both. 

```
section_id  lane  topbot  start  end
B02A        1     2       01     10
B03A        1     2       09     18
```

  * section_id: Section chip IDs
  * lane: Lane IDs
  * topbot: The positions of each section chip where 1 represents top and 2 indicates bottom.
  * start: The start tile.
  * end: The end tile.

**`sbcd_layout`**

The sbcd layout file for the input section chip. The format should be:

```
lane  tile  row  col  rowshift  colshift
3     2556  1    1    0         0
3     2456  2    1    0         0.1715
```

  * lane: Lane IDs
  * tile: Tile IDs 
  * row & col: The layout position
  * rowshift & colshift: The gap information

#### seq2nd
Every FASTQ pair associated with the input section chip should be supplied in `seq2nd`.  The `prefix` should be unique among all 2nd-seq FASTQ pairs, not just within this flowcell.

### output
The output directory will be used to organize the input files and store output files. Please see the structure directory [here](output.md)

### request:
The pipeline interprets the requested output file via this parameter and determines which jobs need to be executed.

The options and corresponding output files are listed below:

  * `"sbcd-per-section"`: A spatial barcode map for a section chip, including a compressed tab-delimited file for barcodes and corresponding global coordinates, and an image displaying the spatial distribution of the barcodes' coordinates.
  * `"smatch-per-section"`: A compressed tab-delimited file with spatial barcodes corresponding to the 2nd-seq reads, a "smatch" image depicting the distribution of spatial coordinates for the matching barcodes, and a summary file of the matching results.
  * `"align-per-section"`: A BAM file accompanied by alignment summary metrics, along with spatial digital gene expression (sDGE) matrices for Gene, GeneFull, splice junctions (SJ), and Velocyto.
  * `"sge-per-section"`: An sDGE matrix, an "sge" image depicting the spatial alignment of transcripts, and an RGB image representing the sDGE matrix and selected genes. In the absence of specified genes of interest, the RGB image will display the top 5 genes with the highest expression levels.
  * `"hist-per-section"`: Two aligned histology files, one of which is a referenced geotiff file facilitating the coordinate transformation between the SGE matrix and the histology image. The other is a tiff file matching the dimensions of both the "smatch" and "sge" images.
