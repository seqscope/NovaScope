
# Configuring a NovaScope Run

## Overview

Once you have [installed NovaScope](../installation/requirement.md) and [downloaded the input data](access_data.md), the next step is to configure a [NovaScope](https://seqscope.github.io/NovaScope/) run. This mainly involves preparing the input job configuration file (in YAML, `config_job.yaml`) for the run.

## Preparing Input Config Files
!!! info
    The pipeline requires to have `config_job.yaml` file in the working directory, which will be indicated by `-d` or `--directory` when executing NovaScope, to specify all input files, output files, and parameters. 

For user's convenience, we provide separate example `config_job.yaml` files for the [Minimal Test Run Dataset](https://github.com/seqscope/NovaScope/blob/main/testrun/minimal_test_run/config_job.yaml), [Shallow Liver Section Dataset](https://github.com/seqscope/NovaScope/blob/main/testrun/shallow_liver_section/config_job.yaml), and [Deep Liver Section Dataset](https://github.com/seqscope/NovaScope/blob/main/testrun/deep_liver_section/config_job.yaml) test runs.

The details of each item specified in the `config_job.yaml` is described below:

### A Template of the Config File

Below is a template of the `config_job.yaml` file. 

Mandatory fields are marked as "REQUIRED FIELD".

```yaml
## Section to Specify Input Datta
input:
  flowcell: <flowcell_id>                       ## REQUIRED FIELD (e.g. N3-HG5MC)
  chip: <chip_id>                               ## REQUIRED FIELD (e.g. B08C)
  species: <species_info>                       ## REQUIRED FIELD (e.g. "mouse")
  lane: <lane_id>                               ## Optional. Defaults to auto-assignment from the last character of chip_id (A->1, B->2, C->3, D->4) if absent.
  seq1st:                                       ## 1st-seq information
    id: <seq1st_id>                             ## Optional. Defaults to "L{lane}" if absent.
    fastq: <path_to_seq1st_fastq_file>          ## REQUIRED FIELD
    layout: <path_to_sbcd_layout>               ## Optional. Default based on chip_id
  seq2nd:                                       ## 2nd-seq information. See the "Detailed Description of Individual Fields" below.
    ## specify the first pair of FASTQs.
    - id: <seq2nd_pair1_id>                     ## Optional. If provided, must be unique among all 2nd-seq pairs. Defaults to automatic assignment based on fastq_R1 if absent (see details below).
      fastq_R1: <path_to_seq2nd_pair1_fastq_Read1_file> ## REQUIRED FIELD - path to Read 1 FASTQ file,
      fastq_R2: <path_to_seq2nd_pair1_fastq_Read2_file> ## REQUIRED FIELD - path to Read 2 FASTQ file
    ## if there is a second pair of FASTQs ...
    - id: <seq2nd_pair2_id>                     
      fastq_R1: <path_to_seq2nd_pair2_fastq_Read1_file>
      fastq_R2: <path_to_seq2nd_pair2_fastq_Read2_file>
    ## ... (if there are more 2nd-seq FASTQ files)
  run_id: <run_id>                              ## Optional. See the "Detailed Description of Individual Fields" below.
  unit_id: <unit_id>                            ## Optional. See the "Detailed Description of Individual Fields" below.
  histology:                                    ## Histology information. Only required if histology alignment is needed. See the "Detailed Description of Individual Fields" below.
    ## specify the first input histology file
    - path: <path_to_1st_histology_file>        ## REQUIRED FIELD - path to the input histology file
      magnification: <magnification>            ## Optional - specify the magnification of the input histology file, default is "10X"
      figtype: <type>                           ## Optional - specify the type of the histology file. Options: "hne", "dapi", and "fl". 
    ## if there is a second input histology file ...
    - path: <path_to_2nd_histology_file>       
      magnification: <magnification>                         
      figtype: <type>   
    ## ...                           
## Output
output: <output_directory>                      ## REQUIRED FIELD (e.g. /path/to/output/directory)
request:                                        ## See the "Detailed Description of Individual Fields" below.
  - <required_output1>                          ## REQUIRED FIELD (e.g. sge-per-run)
  - <required_output2>                          ## Optionally, you can request multiple outputs
  # ...

## Environment
env_yml: <path_to_config_env.yaml_file>         ## If absent, NovaScope use the "config_env.yaml" file in the `info` subdirectory in the Novascope repository.

## ================================================
##
##  Additional Fields:
## 
##    The "upstream", "histology", and "downstream" parameters are included below, along side the default values.
##    Revise and enable the following parameters ONLY IF you wish to utilize values different than the default.
##
## ================================================

### UNCOMMENT RELEVANT LINES TO ENABLE THE ADDITIONAL PARAMETERS
#upstream:
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
#    skip_sbcd: 0            ## If absent, default skip_sbcd follows the fastq2sbcd format: 1 for DraI31 and 0 for DraI32.
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
#  visualization:            ## specify the parameters for visualization
#    drawxy:                 ## specify the parameters for visualization for sbcd and smatch images
#      coord_per_pixel: 1000
#      intensity_per_obs: 50
#      icol_x: 3
#      icol_y: 4
#    drawsge:                ## specify the parameters for sdge visualization 
#      genes:                ## specify sets of genes to be colored
#        - red: nonMT        ## the first set of genes
#          green: Unspliced
#          blue: MT
#      # - ...               ## if more 1 set of genes are required
#      coord_per_pixel: 1000
#      auto_adjust: true
#      adjust_quantile: 0.99
#
#histology:                  ## specify the parameters for histology alignment using historef
#    min_buffer_size: 1000   ## min_buffer_size, max_buffer_size and step_buffer_size will create a list of buffer size help historef to do the alignment
#    max_buffer_size: 2000
#    step_buffer_size: 100
#    raster_channel: 1       ## roaster channel used for historef alignment
#
#downstream:
#  mu_scale: 1000           ## Specify coordinate to um translate for hexagon. By default, we consider the spatial digital gene expression matrix (SGE) is in nano meter.
#  gene_filter:             ## Specify the criteria for gene filtering in a manner compatible with regular expressions, which will be applied when creating the FICTURE-compatible SGE and hexagonal SGE.
#   keep_gene_type: "protein_coding,lncRNA"    # genes to keep
#   rm_gene_regex: "^Gm\\d+|^mt-|^MT-"         # genes to remove
#  segment:                 ## specify the parameters for grouping the pixels into hexagons
#    precision: 2           ## specify the number of digits to store spatial location (in um, 0 for integer)
#    min_pixel_per_unit: 10 ## specify a minimum UMI count of output hexagons
#    char:                  ## specify the characteristics for the hexagons
#      - solo_feature: gn    ## specify the genomic feature to create hexagon
#        hexagon_width: 24   ## specify the size for a hexagonal grid
#        segment_move: 1     ## Specify if the SGE is based on overlapping hexagons or non-overlapping hexagon. The default value 1 will create non-overlapping hexagons.

```

### Detailed Description of Individual Fields

#### Input
!!! tip
    NovaScope supports using relative paths in the job configuration file, which should be relative to the working directory. If a relative path is found, NovaScope automatically obtains its real path and uses it in the process.

* **`seq1st`**:
    * *`id`*: The `id` will be used to organize the 1st-seq FASTQ files. Make sure the `id` parameter for 1st-seq in the corresponding flowcell is unique.  

    * *`layout`*: A spatial barcode (sbcd) layout file to provide the layout of tiles in a chip with the following format. If absent, [NovaScope](https://seqscope.github.io/NovaScope/) will automatically look for the sbcd layout within the NovaScope repository at [info/assets/layout_per_tile_basis](https://github.com/seqscope/NovaScope/tree/main/info/assets/layout_per_tile_basis), using the section chip ID for reference.
        ```yaml
        lane  tile  row  col  rowshift  colshift
        3     2556  1    1    0         0
        3     2456  2    1    0         0.1715
        ```
        * `lane`: Lane IDs;
        * `tile`: Tile IDs;
        * `row` & `col`: The layout position;
        * `rowshift` & `colshift`: The gap information

* **`seq2nd`**: This parameter requires all FASTQ pairs associated with the input section chip to be provided under `seq2nd`. 

    ??? note "How to generate `seq2nd_pair_id`?"
        If an ID is not specified, NovaScope will automatically generate one using the format `<flowcell_id>.<chip_id>.<randomer>`, where `randomer` is the last 5 digits of the md5 hash of the real path of the read 1 FASTQ file from the 2nd-seq.

* **`run_id`**: Only needed if alignment is required to generate the requested output. It is used as an identifier for alignment and Spatial Digital Gene Expression matrices (SGEs) to differentiate between input 2nd-seq FASTQ files. This is particularly useful when generating SGEs using the same 1st-seq files but different 2nd-seq files. If not provided, NovaScope will generate it based on the flowcell ID, chip ID, and all input 2nd-seq read 1 FASTQ files.

    ??? note "How to generate `run_id`?"
        NovaScope automatically generates `run_id` in the format `<flowcell_id>-<chip_id>-<species>-<randomer>`. The `randomer` is created by sorting all input seq2nd_pair_id, concatenating these seq2nd_pair_id into a single long string, and then computing the md5 hash of this string. The last 5 digits of this hash are used as the `randomer`.

* **`unit_id`**: Only needed if reformat feature is required to generate the requested output. It acts as an identifier for SGEs that are prepared for reformatting. This identifier is especially useful when users wish to manually modify SGE outside of NovaScope and then proceed to reformat both the original and modified SGEs. The `unit_id` ensures clear distinction between the original and modified datasets.

    ??? note "How to generate `unit_id`"
        If `unit_id` is not specified and reformatting is requested, it will default to `<run_id>-default`, indicating that no manual preprocessing has occurred. 
        
        Users who prefer to reformat manually modified SGEs should define their own `unit_id`. We recommend incorporating `run_id` into the `unit_id` to maintain a clear trace of the dataset lineage.

* **`histology`**: NovaScope allows multiple input histology files for alignment. However, it is important to note that the magnification and type of each histology file serve as identifiers. Ensure that no two input histology files share the same magnification and type. Currently, [historef](https://github.com/seqscope/historef) supports the following types:
    * `"hne"`: [Hematoxylin and Eosin (H&E) stained](https://en.wikipedia.org/wiki/H%26E_stain) histology images;
    * `"dapi"`: [DAPI or 4',6-diamidino-2-phenylindole stained](https://en.wikipedia.org/wiki/DAPI) histology images;
    * `"fl"`: Fluorescence stained histology images.

#### Output
The output directory will be used to organize the input files and store output files. Please see the structure directory [here](output.md).

#### Requests

The pipeline interprets the requested output files via `request` and determines the execution flow.
 
!!! info
    The `request` parameter should indicate the **final output** required, and all intermediary files contributing to the final output will be automatically generated (i.e., the dependencies between rules). 


##### Main Options 
Below are the options with their final output files and links to detailed output information. For more insights into the excution flow, please consult the [execution flow by request](../walkthrough/execution_guide/rule_execution.md) alongside the [rulegraph](https://seqscope.github.io/NovaScope/#an-overview-of-the-workflow-structure). 


| Option              | Final Output Files                                                                                             | Details                                              |
|---------------------|----------------------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| `sbcd-per-flowcell` | Spatial barcode map (per-tile basis) and Manifest file for a flowcell                                          | [fastq2sbcd](../walkthrough/rules/fastq2sbcd.md#output-files)       |
| `sbcd-per-chip`     | Spatial barcode map for a section chip, Image of spatial barcode distribution                                  | [sbcd2chip](../walkthrough/rules/sbcd2chip.md#output-files)         |
| `smatch-per-chip`   | File with matched spatial barcodes, Image of matched barcode spatial distribution                              | [smatch](../walkthrough/rules/smatch.md#output-files)               |
| `align-per-run`     | Binary Alignment Map file, Digital gene expression matrix for genomic features                                 | [align](../walkthrough/rules/align.md)                              |
| `sge-per-run`       | SGE, Spatial distribution images for transcripts                                                               | [dge2sdge](../walkthrough/rules/dge2sdge.md) and [sdge_visual](../walkthrough/rules/sdge_visual.md)                       |


##### Plus Options 
The options below are only for executing the [additional functionalities](../index.md#functionality). To execute this, make sure you have installed the [additional requirement](../installation/requirement_for_plus.md) properly.

| Option              | Final Output Files                                                                                             | Details                                              |
|---------------------|----------------------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| `hist-per-run`      | Geotiff files for coordinate transformation between SGE and histology image                                    | [historef](../walkthrough/rules/historef.md)                        |
| `transcript-per-unit`  | SGE in in the FICTURE-compatible format                                                                     | [sdgeAR_reformat](../walkthrough/rules/sdgeAR_reformat.md)                        |
| `segment-per-unit`     | hexagon-indexed SGE in the 10x genomics format                                                                | [sdgeAR_segment](../walkthrough/rules/sdgeAR_segment.md)                        |


#### Upstream & Downstream

Parameter details for the `upstream` and `downstream` fields are outlined in the [NovaScope Walkthrough](../walkthrough/intro.md), under the specific rule pages to which they apply.

* **`align`**
    * *`resource`*: Only applicable for HPC users.
        * `assign_type`: two available options for how NovaScope allocates resources for alignment. The options include `"stdin"` (recommended) and `"filesize"`. Details for each option are provided in the blocks below. 

        ??? note "Option `stdin`"
            **Advantages:**
            - Directly allocates resources as specified in the `stdin` field, bypassing calculations for precision in resource management.
            - Enables customization of resources for different datasets in the job configuration file, allowing for optimization of costs based on file size.

            **Disadvantages:**
            - Requires users to specify resources for each job unless default settings (partition name, threads, memory) fit the computing environment. An example is provided in the [template](#a-template-of-the-config-file).

        ??? note "Option `filesize`"
            **Advantages:**
            - Automatically allocates resources based on the total size of input 2nd-seq FASTQ files and specified computing resources in the [environment configuration file](../installation/env_setup.md#optional-computing-capabilities).
            - Once computing resources are specified in the environment file, they automatically apply to all jobs, simplifying the setup.

            **Disadvantages:**
            - Requires computing time to calculate the total size of input files, potentially delaying the start of data processing.

            The resource allocation strategy is as follows:

            | Total File Size (GB) | Memory Allocated for Alignment (GB) |
            |----------------------|-------------------------------------|
            | Under 200            | 70                                  |
            | 200 to 400           | 140                                 |
            | Over 400             | 330                                 |
