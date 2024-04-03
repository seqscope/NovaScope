
# Configuring a NovaScope Run

## Overview

Once you have [installed NovaScope](../installation/requirement.md) and [downloaded the input data](access_data.md), the next step is to configure a [NovaScope](https://seqscope.github.io/NovaScope/) run. This mainly involves preparing the input configuration files (in YAML) for the run.

## Preparing Input Config Files

The pipeline requires to have `config_job.yaml` file in the working directory (indicated by `-d` or `--directory`) to specify all input files, output files, and parameters. 

For user's convenience, we provide separate example `config_job.yaml` files for the [Minimal Test Run Dataset](https://github.com/seqscope/NovaScope/blob/main/testrun/minmal_test_run/config_job.yaml), [Shallow Liver Section Dataset](https://github.com/seqscope/NovaScope/blob/main/testrun/shallow_liver_section/config_job.yaml), and [Deep Liver Section Dataset](https://github.com/seqscope/NovaScope/blob/main/testrun/deep_liver_section/config_job.yaml) test runs.  

The details of each item specified in the `config_job.yaml` is described below:

### A Template of the Config File

Below is a template of the `config_job.yaml` file. 
Mandatory fields are marked as "REQUIRED FIELD".

```yaml
## Section to Specify Input Datta
input:
  flowcell: <flowcell_id>                       ## REQUIRED FIELD (e.g. N3-HG5MC)
  chip: <section_chip_id>                       ## REQUIRED FIELD (e.g. B08C)
  species: <species_info>                       ## REQUIRED FIELD (e.g. "mouse")
  lane: <lane_id>                               ## Optional. Auto-assigned based on section_chip_id's last letter if absent (A->1, B->2, C->3, D->4).
  seq1st:                                       ## 1st-seq information
    prefix: <seq1st_id>                         ## Optional. Defaults to "L{lane}" if absent.
    fastq: <path_to_seq1st_fastq_file>          ## REQUIRED FIELD
    layout: <path_to_sbcd_layout>               ## Optional. Default based on section_chip_id
  seq2nd:                                       ## 2nd-seq information
    - prefix: <seq2st_pair1_id>                 ## REQUIRED FIELD - for first pair of FASTQ files
      fastq_R1: <path_to_seq2nd_pair1_fastq_Read1_file> ## REQUIRED FIELD - Read 1 FASTQ file
      fastq_R2: <path_to_seq2nd_pair1_fastq_Read2_file> ## REQUIRED FIELD - Read 2 FASTQ file
    - prefix: <seq2st_pair2_id>                 ## Optional - if there are >1 pair of FASTQs
      fastq_R1: <path_to_seq2nd_pair2_fastq_Read1_file>
      fastq_R2: <path_to_seq2nd_pair2_fastq_Read2_file>
    # ... (if there are more 2nd-seq FASTQ files)
  label: <seq2nd_version>                       ## Optional. A version label (e.g. v1)
  histology: <path_to_the_input_histology_file> ## Optional, only if histology alignment is needed.

## Output
output: <output_directory>                      ## REQUIRED FIELD (e.g. /path/to/output/directory)
request:                                        
  - <required_output1>                          ## REQUIRED FIELD (e.g. sge-per-chip)
  - <required_output2>                          ## Optionally, you can request multiple outputs
  # ...

## Environment
env_yml: <path_to_config_env.yaml_file>         ## If absent, the pipeline will check if a "config_env.yaml" file exists in the `info` subdirectory in the Novascope repository.

## ================================================
##
##  Additional Fields:
## 
##    The "preprocess" and "histology" parameters are included below, along side the default values.
##    You only need to revise and enable the following parameters if you wish to utilize values different than the default.
##
## ================================================

### UNCOMMENT RELEVANT LINES TO ENABLE THE ADDITIONAL PARAMETERS
#preprocess:
#  fastq2sbcd:
#    format: DraI32          ## Example data uses DraI31, but DraI32 is a typical format.
#
#  sbcd2chip:                ## specify the parameters for sbcd2chip
#    gap_row: 0.0517
#    gap_col: 0.0048
#    dup_maxnum: 1
#    dup_maxdist: 1
#
#  smatch:                   ## specify the parameters for smatch
#    skip_sbcd: 1            ## If absent, default skip_sbcd follows the fastq2sbcd format: 1 for DraI31 and 0 for DraI32.
#    match_len: 27           ## Length of spatial barcode considered to be a perfect match.
#
#  align:                    ## specify the parameters for align (STARsolo)
#    min_match_len: 30       ## A minimum number of matching bases.
#    min_match_frac: 0.66    ## A minimum fraction of matching bases.
#    len_sbcd: 30            ## Length of spatial barcode (in Read 1) to be copied to output FASTQ file (Read 1).
#    len_umi: 9              ## Length of UMI barcode (in Read 2) to be copied to output FASTQ file (Read 1).
#    len_r2: 101             ## Length of read 2 after trimming (including randomers).
#    exist_action: overwrite ## Skip the action or overwrite the file if an intermediate or output file already exists. Options: "skip", and "overwrite".
#    resource:               ## See the "Detailed Description of Individual Fields" below.
#      assign_type: stdin
#      stdin:
#        partition: standard
#        threads: 10
#        memory: 70000m
#
#  dge2sdge:                 ## specify the parameters for dge2sdge
#    layout: null            ## If absent, the layout file in the info/assets/layout_per_section_basis/layout.1x1.tsv will be used for RGB plots.
#
#  gene_visual: null         ## If you have a specific set of genes to visualize, specify the path to a file containing a list of gene names (one per line) here. By default, the top five genes with the highest expression are visualized.
#
#  visualization:            ## specify the parameters for visualization
#    drawxy:
#      coord_per_pixel: 1000
#      intensity_per_obs: 50
#      icol_x: 3
#      icol_y: 4
#
#histology:                  ## specify the parameters for histology alignment using historef
#    resolution: 10
#    figtype: "hne"          ## Options: "hne", "dapi", and "fl".

```

### Detailed Description of Individual Fields

#### Input
* **`seq1st`**:
    * *`prefix`*: The `prefix` will be used to organize the 1st-seq FASTQ files. Make sure the `prefix` parameter in the corresponding flowcell is unique.  
    * *`layout`*: A file to provide the layout of tiles in a chip with the following format. If absent,[NovaScope](https://seqscope.github.io/NovaScope/) will automatically look for the spatial barcode (sbcd) layout within the NovaScope repository at [info/assets/layout_per_tile_basis](https://github.com/seqscope/NovaScope/tree/main/info/assets/layout_per_tile_basis), using the section chip ID for reference.
      ```yaml
      lane  tile  row  col  rowshift  colshift
      3     2556  1    1    0         0
      3     2456  2    1    0         0.1715
      ```
        * lane: Lane IDs
        * tile: Tile IDs 
        * row & col: The layout position
        * rowshift & colshift: The gap information

* **`seq2nd`**: Every FASTQ pair associated with the input section chip should be supplied in `seq2nd`.  The `prefix` should be unique among all 2nd-seq FASTQ pairs, not just within this flowcell.

#### Output
The output directory will be used to organize the input files and store output files. Please see the structure directory [here](output.md).

#### Requests

The pipeline interprets the requested output files via `request` and determines the execution flow. The `request` parameter should indicate the **final output** required, and all intermediary files contributing to the final output will be automatically generated (i.e., the dependencies between rules). For detailed insights into the excution flow, please consult the [execution flow by request](../walkthrough/execution_guide/rule_execution.md) alongside the [rulegraph](https://seqscope.github.io/NovaScope/#an-overview-of-the-workflow-structure). 

Below are the options with their output files and links to detailed output information.

| Option              | Main Output Files                                                                                             | Details                                              |
|-----------------------|------------------------------------------------------------------------------------------------------------ |-------------------------------------------------------|
| `sbcd-per-flowcell` | Spatial barcode map (per-tile basis) and Manifest file for a flowcell                                         | [fastq2sbcd](../walkthrough/rules/fastq2sbcd.md#output-files)       |
| `sbcd-per-chip`  | Spatial barcode map for a section chip, Image of spatial barcode distribution                                    | [sbcd2chip](../walkthrough/rules/sbcd2chip.md#output-files)         |
| `smatch-per-chip`| File with matched spatial barcodes, Image of matched barcode spatial distribution                                 | [smatch](../walkthrough/rules/smatch.md#output-files)               |
| `align-per-chip` | Binary Alignment Map (BAM) file, Digital gene expression matrix (DGE) for genomic features                       | [align](../walkthrough/rules/align.md)                              |
| `sge-per-chip`   | Spatial digital gene expression matrix (SGE), Spatial distribution images for all transcripts and specific genes of interest. | [dge2sdge](../walkthrough/rules/dge2sdge.md)                        |
| `hist-per-chip`  | Geotiff file for coordinate transformation between SGE and histology image, A Resized TIFF file                  | [historef](../walkthrough/rules/historef.md)                        |

#### preprocess

More details for the parameters in `preprocess` field are provided in the [NovaScope Walkthrough](../walkthrough/intro.md).

* **`align`**
    * *`resource`*:  The `resource` parameters are only applicable for HPC users. 
        * `assign_type`: two available options are `"stdin"` (recommended) and `"filesize"`. The `stdin`, short for standard input, requires the user manually define resource to be used for alignment. The `"filesize"` will automatically allocate resource based on the total size of the input 2nd-seq FASTQ files and the available computing resources. Please find details and an example for each option below.
        * `"stdin"`: this field is required if `assign_type` is defined as `stdin`. Revise `partition`, `threads`, and `memory` in the following example to fit your case.
            ```yaml
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
        * `filesize`: If using `assign_type` is defined as `filesize`, provide details about the computing capabilities of all available nodes, including `partition`, the available number of CPUs(`max_n_cpus`), and the memory allocated per CPU (`mem_per_cpu`). The current resource allocation strategy operates on the following basis: 1) For input 2nd-seq FASTQ files with a combined size under 200GB, allocate 70GB of memory for alignment processes; 2) When the total file size ranges from 200GB to 400GB, memory allocation increases to 140GB; 3) For file sizes exceeding 400GB, 330GB of memory is allocated specifically for the alignment.
            ```yaml
            preprocess:
            #  ...
               align:
            #   ...
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
