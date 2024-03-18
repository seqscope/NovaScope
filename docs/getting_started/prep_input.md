
# Preparing Input

## 1. Input Data

Begin by establishing a specific directory for your job. This directory will be used to organize the input configuration file (i.e., `config_job.yaml`, as outlined in *2. Prepare Input Config Files*) and to store log files. 

The required input data includes 1st-seq and 2nd-seq FASTQ files, with the option to include an additional histology file and a file listing genes of interest. Below, we provide [three examples](https://github.com/seqscope/NovaScope/tree/main/testrun) from the same section chip, highlighting differences in 2nd-Seq library sequencing depth and selected regions.

### Example 1 - Regional Section Test Run

The input data originates from a specific, limited region of a section chip, which was subjected to a relatively 2nd-Seq library sequencing depth. No histology files is provided.

```
smk_dir="<path_to_NovaScope_repository>"    # Replace <path_to_NovaScope_repository> with the path to the NovaScope repository
job_dir="$smk_dir/testrun/regional_section"  

mkdir -p  $job_dir && cd $job_dir

mkdir -p input_data 
```

### Example 2 - Full Section Shallow Sequencing Test Run 

The input data was derived from one section chip and features a relatively shallow 2nd-Seq library sequencing depth (approximately 163 million reads). A histology file is also accessible. 

```
smk_dir="<path_to_NovaScope_repository>"    # Replace <path_to_NovaScope_repository> with the path to the NovaScope repository
job_dir="$smk_dir/testrun/full_section_shallow"  

mkdir -p  $job_dir && cd $job_dir

# Download the histology file
wget https://historef-sample-data.s3.amazonaws.com/sample/b08c/histology.tif
```


### Example 3 - Full Section Deep Sequencing Test Run 

The input data is based on one section chip underwent deep sequencing, resulting in 2.61 billion reads, and this too comes with an available histology file.

```
smk_dir="<path_to_NovaScope_repository>"    # Replace <path_to_NovaScope_repository> with the path to the NovaScope repository
job_dir="$smk_dir/testrun/full_section_deep"  

mkdir -p  $job_dir && cd $job_dir

# Download the histology file
wget https://historef-sample-data.s3.amazonaws.com/sample/b08c/histology.tif
```

## 2. Prepare Input Config Files

The pipeline necessitates a `config_job.yaml` file to define all inputs, outputs, and parameters. This `config_job.yaml` file should be provided in the `$job_dir`.

Separate example `config_job.yaml` files for the [regional section](https://github.com/seqscope/NovaScope/blob/main/testrun/regional_section/config_job.yaml), [full section shallow](https://github.com/seqscope/NovaScope/blob/main/testrun/full_section_shallow/config_job.yaml), and [full section deep](https://github.com/seqscope/NovaScope/blob/main/testrun/full_section_deep/config_job.yaml) test runs are provided.  

Below, you'll find explanations for each item specified in the `config_job.yaml`.

### 2.1 A Config Template 

```
## ================================================
##
## Mandatory Fields:
##
## ================================================

## Input
input:
  flowcell: <flowcell_id>
  section: <section_chip_id>
  specie: <specie_info>
  lane: <lane_id>                               ## Optional. Auto-assigned based on section's last letter if absent (A->1, B->2, C->3, D->4).
  seq1st:
    prefix: <seq1st_id>                         ## Optional. Defaults to "L{lane}" if absent.
    fastq: <path_to_seq1st_fastq_file>
    layout: <path_to_sbcd_layout>               ## Optional. See 2.2.
  seq2nd:                                       ## See 2.2.
    - prefix: <seq2st_pair1_id>
      fastq_R1: <path_to_seq2nd_pair1_fastq_Read1_file>
      fastq_R2: <path_to_seq2nd_pair1_fastq_Read2_file>
    - prefix: <seq2st_pair2_id>
      fastq_R1: <path_to_seq2nd_pair2_fastq_Read1_file>
      fastq_R2: <path_to_seq2nd_pair2_fastq_Read2_file>
    # ...
  label: <seq2nd_version>                       ## Optional. A version label for the input seq2 data, if applicable.
  histology: <path_to_the_input_histology_file> ## Optional.

## Output
output: <output_directory>                      ## See 2.2.
request:                                        ## See 2.2.
  - <required_output1>
  - <required_output2>
  # ...

## Environment
env_yml: <path_to_config_env.yaml_file>         ## If absent, the pipeline will check if a "config_env.yaml" file exists in the `info` subdirectory in the Novascope repository.

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
#    dup_maxdist: 1
#  smatch:
#    skip_sbcd: 1            ## If absent, skip_sbcd can be calculated follows the fastq2sbcd format: 1 for DraI31 and 0 for DraI32.
#    match_len: 27           ## Length of spatial barcode considered to be a perfect match.
#  align:
#    min_match_len: 30       ## A minimum number of matching bases.
#    min_match_frac: 0.66    ## A minimum fraction of matching bases.
#    len_sbcd: 30            ## Length of spatial barcode (in Read 1) to be copied to output FASTQ file (Read 1).
#    len_umi: 9              ## Length of UMI barcode (in Read 2) to be copied to output FASTQ file (Read 1).
#    len_r2: 101             ## Length of read 2 after trimming (including randomers).
#    exist_action: overwrite ## Skip the action or overwrite the file if an intermediate or output file already exists. Options: "skip", and "overwrite".
#    resource:               ## See 2.2.
#      assign_type: stdin
#      stdin:
#        partition: standard
#        threads: 10
#        memory: 70000m
#  dge2sdge:
#    layout: null            ## If absent, the layout file in the info/assets/layout_per_section_basis/layout.1x1.tsv will be used for RGB plots.
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
#    figtype: "hne"          ## Options: "hne", "dapi", and "fl".

```

### 2.2 Additional Information

#### Input

**`seq1st`** 

*`prefix`*

The `prefix` will be used to organize the 1st-seq FASTQ files. Make sure the `prefix` parameter in the corresponding flowcell is unique.  

*`layout`*

A file to provide the layout of tiles in a section chip with the following format. If absent, NovaScope will automatically look for the sbcd layout within the NovaScope repository at [info/assets/layout_per_tile_basis](https://github.com/seqscope/NovaScope/tree/main/info/assets/layout_per_tile_basis), using the section chip ID for reference.

```
lane  tile  row  col  rowshift  colshift
3     2556  1    1    0         0
3     2456  2    1    0         0.1715
```

  * lane: Lane IDs
  * tile: Tile IDs 
  * row & col: The layout position
  * rowshift & colshift: The gap information


**`seq2nd`**

Every FASTQ pair associated with the input section chip should be supplied in `seq2nd`.  The `prefix` should be unique among all 2nd-seq FASTQ pairs, not just within this flowcell.

#### output
The output directory will be used to organize the input files and store output files. Please see the structure directory [here](output.md)

#### request:

The pipeline interprets the requested output files via this parameter and determines which jobs need to be executed. 

Simply define the **final output** required, and all intermediary files contributing to this output will be automatically generated (i.e.,  the dependencies between rules). For instance, outputs from `"sbcd-per-flowcell"` serve as inputs for `"sbcd-per-section"`. Thus, by requesting `"sbcd-per-section"`, the pipeline will generate not only the files for `"sbcd-per-section"` but also those for `"sbcd-per-flowcell"`. For detailed insights into these dependencies, please consult the [rulegraph](https://seqscope.github.io/NovaScope/#an-overview-of-the-workflow-structure).

The options and corresponding output files are listed below:

  * `"sbcd-per-flowcell"`: A spatial barcode map for a flowcell organzied on a per-tile basis. Each tile has a compressed tab-delimited file for barcodes and corresponding local coordinates in the tile.
  * `"sbcd-per-section"`: A spatial barcode map for a section chip, including a compressed tab-delimited file for barcodes and corresponding global coordinates in the section chip, and an image displaying the spatial distribution of the barcodes' coordinates.
  * `"smatch-per-section"`: A compressed tab-delimited file with spatial barcodes corresponding to the 2nd-seq reads, a "smatch" image depicting the distribution of spatial coordinates for the matching barcodes, and a summary file of the matching results. 
  * `"align-per-section"`: A BAM file accompanied by alignment summary metrics, along with spatial digital gene expression (sDGE) matrices for Gene, GeneFull, splice junctions (SJ), and Velocyto.
  * `"sge-per-section"`: An sDGE matrix, an "sge" image depicting the spatial alignment of transcripts, and an RGB image representing the sDGE matrix and selected genes. In the absence of specified genes of interest, the RGB image will display the top 5 genes with the highest expression levels.
  * `"hist-per-section"`: Two aligned histology files, one of which is a referenced geotiff file facilitating the coordinate transformation between the SGE matrix and the histology image. The other is a tiff file matching the dimensions of both the "smatch" and "sge" images.

#### preprocess

**`align`**

*`resource`*: 

The `resource` parameters are only applicable for HPC users. The `assign_type` include two options: `"stdin"` (recommended) and `"filesize"`. 

If using `"stdin"`, define the resource parameters in the `stdin`, including `partition`, `threads`, and `memory`, to fit your case. Such resource will be used for the *align* step. An example is provided below. 

```
preprocess:
#  ...
  align:
#    ...
    resource:
      assign_type: stdin
      stdin:
        partition: standard
        threads: 10
        memory: 70000m
```

If using `"filesize"`, ensure to include details about the computing capabilities of all available nodes. This includes the partition name, the available number of CPUs, and the memory allocated per CPU (refer to the example provided). Resource allocation will be automatically adjusted based on the total size of the input 2nd-seq FASTQ files and the available computing resources. The preliminary strategy for resource allocation is as follows: for input 2nd-seq FASTQ files smaller than 200GB, allocate 70GB of memory for alignment processes; for file sizes ranging from 200GB to 400GB, allocate 140GB of memory; for anything larger, 330GB of memory will be designated for alignment step.

```
preprocess:
#  ...
  align:
#    ...
    resource:
      assign_type: filesize
      filesize:
        - partition: standard
          max_n_cpus: 20
          mem_per_cpu: 7g
        - partition: largemem
          max_n_cpus: 10
          mem_per_cpu: 25g
```
