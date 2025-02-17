# Configuring a NovaScope Run

After [installing NovaScope](../installation/requirement.md) and [downloading the input data](access_data.md), prepare a job configuration file to specify inputs, outputs, and parameters.

!!! info "Job Configuration File Specifications"
    The job configuration file must adhere to the following guidelines:

    * **Naming convention**: `config_job.yaml`.
    * **Location**: Ensure the `config_job.yaml` file is placed in the working directory. The working directory should be specified to NovaScope using the `-d` or `--directory` option.
    * **Fields**: The `config_job.yaml` file must include the following fields: : `input`, `output`, `request`, `env_yml`. Additional fields can be included as per the user's requirements.

### Prepare the Job Configuration file

Prepare your job configuration file following the template below.

!!! tip "Example job configuration files"

    For user's convenience, we provide separate example `config_job.yaml` files for the [Minimal Test Run](https://github.com/seqscope/NovaScope/blob/main/testrun/minimal_test_run/config_job.yaml), [Shallow Liver Test Run](https://github.com/seqscope/NovaScope/blob/main/testrun/shallow_liver_section/config_job.yaml), and [Deep Liver Test Run](https://github.com/seqscope/NovaScope/blob/main/testrun/deep_liver_section/config_job.yaml).

```yaml
## ================================================
##
##  Main Fields:
##  Detailed explanations for the "Main Fields" parameters are available at the bottom of this page.
##
## ================================================
## == Input Data ==
input:
  flowcell: <flowcell_id>                       ## REQUIRED FIELD (e.g. N3-HG5MC)
  chip: <chip_id>                               ## REQUIRED FIELD (e.g. B08C)
  species: <species_info>                       ## REQUIRED FIELD (e.g. "mouse")
  lane: <lane_id>                               ## Optional. Defaults to auto-assignment from the last character of chip_id (A->1, B->2, C->3, D->4) if absent.
  seq1st:                                       ## 1st-seq information
    id: <seq1st_id>                             ## Optional. Defaults to "L{lane}" if absent.
    fastq: <path_to_seq1st_fastq_file>          ## REQUIRED FIELD
    layout: <path_to_sbcd_layout>               ## Optional. Default based on chip_id
    layout_shift: <shift_type>                  ## Optional. Default to "tobe", which shifts odd-row tiles in the top layer and even-row tiles in the bottom layer horizontally.
  seq2nd:                                       ## 2nd-seq information. See the "Main Fields" below.
    ## specify the first pair of FASTQs.
    - id: <seq2nd_pair1_id>                     ## Optional. If provided, must be unique among all 2nd-seq pairs. Defaults to automatic assignment based on fastq_R1 if absent (see details below).
      fastq_R1: <path_to_seq2nd_pair1_fastq_Read1_file> ## REQUIRED FIELD. Path to Read 1 FASTQ file.
      fastq_R2: <path_to_seq2nd_pair1_fastq_Read2_file> ## REQUIRED FIELD. Path to Read 2 FASTQ file.
    ## if there is a second pair of FASTQs ...
    - id: <seq2nd_pair2_id>                     
      fastq_R1: <path_to_seq2nd_pair2_fastq_Read1_file>
      fastq_R2: <path_to_seq2nd_pair2_fastq_Read2_file>
    ## ... (if there are more 2nd-seq FASTQ files)
  run_id: <run_id>                              ## Optional. See the "Main Fields" below.
  unit_id: <unit_id>                            ## Optional. See the "Main Fields" below.
  histology:                                    ## Optional. Histology information. Only required if histology alignment is needed. See the "Main Fields" below.
    ## specify the first input histology file
    - path: <path_to_1st_histology_file>        ## REQUIRED FIELD. Path to the input histology file
      magnification: <magnification>            ## Optional. Magnification of the input histology file, default is "10X".
      figtype: <type>                           ## Optional. Type of the histology file. Options: "hne", "dapi", and "fl". 
    ## if there is a second input histology file ...
    - path: <path_to_2nd_histology_file>       
      magnification: <magnification>                         
      figtype: <type>   
    ## ...  
                         
## == Output == 
output: <output_directory>                      ## REQUIRED FIELD (e.g. /path/to/output/directory)
request:                                        ## See the "Main Fields" below.
  - <required_output1>                          ## REQUIRED FIELD (e.g. sge-per-run)
  - <required_output2>                          ## Optionally, you can request multiple outputs.
  # ...

## == Environment YAML == 
env_yml: <path_to_config_env.yaml_file>         ## If absent, NovaScope use the "config_env.yaml" file in the `info` subdirectory in the Novascope repository.

## ================================================
##
##  Additional Fields:
## 
##    * All parameters below are defined by their default values.
##    * Modify and enable the following parameters ONLY if you want to use values other than the defaults.
##    * Each parameter is briefly described here, with more details available in the NovaScope Full Documentation under the relevant rule pages.
##
## ================================================
#
## == Upstream Parameters (from fastq files to SGE) == 
#
#upstream:                 
#  stdfastq:                                    ## Specify whether to use FASTQ files. Set to True unless the user doesn't have FASTQ but has all output files from FASTQ are available.
#    seq1st: True
#    seq2nd: True           
#
#  fastq2sbcd:                                  ## Specify the HDMI-oligo seed library. DraI32 is the typical format. The example data uses DraI31.
#    format: DraI32             
#
#  sbcd_layout:                                 ## Specify parameters for sbcd layout examiniation if needed.
#    tiles:                                     ## List tile pairs to examine. Ensure tiles exist in the input spatial map. By default, the two pairs below will be used. For the minimal test dataset with only two tiles (ID: 2456, 2556), use those for examination.
#      - "1644,1544"
#      - "2644,2544"
#    colshift: 0.1715                           ## horizontal shift distance
#
#  sbcd2chip:                                   ## Specify tile gaps and duplicate settings for spatial barcodes. 
#    gap_row: 0.0517
#    gap_col: 0.0048
#    dup_maxnum: 1
#    dup_maxdist: 1
#
#  smatch:                                      
#    skip_sbcd: 0                               ## The number of initial bases to omit from the read.
#    match_len: 27                              ## Length of spatial barcode considered to be a perfect match.
#
#  align:                                       
#    min_match_len: 30                          ## Minimum number of matching bases.
#    min_match_frac: 0.66                       ## Minimum fraction of matching bases.
#    len_sbcd: 30                               ## Length of spatial barcode (in Read 1) to copy to output FASTQ file (Read 1).
#    len_umi: 9                                 ## Length of UMI barcode (in Read 2) to copy to output FASTQ file (Read 1).
#    len_r2: 101                                ## Length of read 2 after trimming (including randomers).
#    exist_action: overwrite                    ## Actions when an intermediate or output file exists. Options: "skip" or "overwrite".
#    resource:                                  ## Computing resources for alignment (HPC only). 
#      assign_type: stdin
#      stdin:
#        partition: standard
#        threads: 10
#        memory: 70000m
#
#  visualization:                               ## Visualization parameters.
#    drawxy:                                    ## Parameters for visualization for Rule sbcd2chip and smatch.
#      coord_per_pixel: 1000
#      intensity_per_obs: 50
#      icol_x: 3
#      icol_y: 4
#    drawsge:                                   ## Parameters for Rule sdge_visual.
#      action: True                             ## When False, NovaScope skips spatial expression visualization, helpful if species-specific gene lists are not available.
#      genes:                                   ## Gene sets for coloring.
#        - red: nonMT                           ## First set of genes.
#          green: Unspliced
#          blue: MT
#      # - ...                                  ## Additional gene sets if needed.
#      coord_per_pixel: 1000
#      auto_adjust: true
#      adjust_quantile: 0.99
#
## == Histology Alignment Parameters == 
# 
#histology:                                     ## Parameters for Rule historef.
#    min_buffer_size: 1000                      ## Use min_buffer_size, max_buffer_size, and step_buffer_size to create a list of buffer sizes for histology alignment.
#    max_buffer_size: 2000
#    step_buffer_size: 100
#    raster_channel: 1                          ## Roaster channel used for historef alignment.
#
## == Downstream Parameters (SGE filtering, reformatting, and segmentation) ==
#
#downstream:                 
#  mu_scale: 1000                               ## Coordinate to micron (um) conversion.
#
#  gene_filter:                                 ## Criteria for gene filtering in a manner compatible with regular expressions.
#    keep_gene_type: "protein_coding|lncRNA"    
#    rm_gene_regex: "^Gm\\d+|^mt-|^MT-"         
#    min_ct_per_feature: 50                     
#
#  polygon_density_filter:                      ## Parameters for polygon filtering by density, if applicable.
#    radius: 15               
#    hex_n_move: 1            
#    polygon_min_size: 500    
#    quartile: 2
#
#  segment:
#    hex_n_move: 1                              ## Sliding step in segmentation.
#    precision: 2                               ## Precision for spatial location in segmentation.
#    10x:                                       ## Parameters for hexagons in 10x Genomics format.
#      min_pixel_per_unit: 10                   
#      char:                                    ## Characteristics for hexagon segmentation.
#        - solo_feature: gn                     
#          hexagon_width: 24                   
#          quality_control: FALSE               
#      # - ...                                  ## Add more hexagon sets if needed. 
#    ficture:                                   ## Parameters fpr hexagons in FICTURE-compatible format.
#      min_density: 0.3                         
#      char:
#        - solo_feature: gn
#          hexagon_width: 24
#          quality_control: TRUE                
#      # - ...                                  ## Add more hexagon sets if needed. 
```

### `Main Fields` Parameters

#### Input
!!! tip "Relative Path"
    NovaScope supports using relative paths in the job configuration file, which should be relative to the working directory. If a relative path is found, NovaScope automatically obtains its real path and uses it in the process.

* **`seq1st`**:
    * *`id`*: The `id` will be used to organize the 1st-seq FASTQ files. Make sure the `id` field for 1st-seq in the corresponding flow cell is unique.  

    * **`layout`** & **`layout_shift`**: These parameters identify the spatial barcode (sbcd) layout file to provide the layout of tiles in a chip.
        * To use a specific layout file, set **`layout`** with the path to the desired layout file.
        * To use pre-built layout files in NovaScope, leave `layout` empty and define the **`layout_shift`**. The `layout_shift` defaults to `"tobe"`. [NovaScope](https://seqscope.github.io/NovaScope/) will then automatically identify the layout file from [info/assets/layout_per_tile_basis](https://github.com/seqscope/NovaScope/tree/main/info/assets/layout_per_tile_basis), using `layout_shift` and `chip` as reference. NovaScope supports two types of layout: `"tobe"` and `"tebo"`, which shift tiles in different ways (see [sbcd_layout.md#purpose](../fulldoc/rules/sbcd_layout.md#purpose)).

        !!! tip "Spatial layout examination"

            If the `layout_shift` is unclear or if misaligned fiducial marks are observed in the ["sbcd" image](../fulldoc/rules/sbcd2chip.md#3-an-sbcd-image), perform a spatial layout examination by setting `request` to `sbcdlo-per-flowcell`.
    
        ??? note "The spatial barcode (sbcd) layout format"

            ```yaml
            lane  tile  row  col  rowshift  colshift
            3     2556  1    1    0         0
            3     2456  2    1    0         0.1715
            ```
            * `lane`: Lane IDs;
            * `tile`: Tile IDs;
            * `row` & `col`: The layout position;
            * `rowshift` & `colshift`: The gap information

* **`seq2nd`**: This field requires all FASTQ pairs associated with the input section chip to be provided under `seq2nd`. 

    ??? note "How to generate `seq2nd_pair_id`?"
        If an ID is not specified, NovaScope will automatically generate one using the format `<flowcell_id>.<chip_id>.<randomer>`, where `randomer` is the last 5 digits of the md5 hash of the real path of the read 1 FASTQ file from the 2nd-seq.

* **`run_id`**: Only needed if alignment is required to generate the requested output. It is used as an identifier for alignment and Spatial Digital Gene Expression matrices (SGEs) to differentiate between input 2nd-seq FASTQ files. This is particularly useful when generating SGEs using the same 1st-seq files but different 2nd-seq files. If not provided, NovaScope will generate it based on the flow cell ID, chip ID, and all input 2nd-seq read 1 FASTQ files.

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

#### Request
The pipeline interprets the requested output files via the `request` field and determines the execution flow. The `request` field allows multiple desired output.
 
!!! info
    The `request` field should indicate the **final output** required, and all intermediary files contributing to the final output will be automatically generated (i.e., the dependencies between rules). 

##### Main Request 
Below are request options for NovaScope's [main functionalities](../home/workflow_structure.md#main-workflow), alongside their final output and links to detailed output information. 

| Option              | Final Output Files                                                                                 | Details      |
|---------------------|----------------------------------------------------------------------------------------------------|--------------|
| `sbcd-per-flowcell` | Spatial barcode maps for a flowcell at per-tile basis, and a manifest file of summary statistics for each tile. | [fastq2sbcd](../fulldoc/rules/fastq2sbcd.md#output-files)|
| `sbcd-per-chip`     | A spatial barcode map for a chip, and an image of spatial barcode distribution.| [sbcd2chip](../fulldoc/rules/sbcd2chip.md#output-files)|
| `smatch-per-chip`   | A TSV file of spatial barcodes matched to the 2nd-Seq reads, and an image of matched spatial barcode distribution. | [smatch](../fulldoc/rules/smatch.md#output-files) |
| `align-per-run`     | A Binary Alignment Map file with summary metrics, and  a digital gene expression matrix for genomic features. | [align](../fulldoc/rules/align.md#output-files)                              |
| `sge-per-run`       | An SGE matrix with a coordinate metadata file, an image showing distributions of all, matched, and aligned spatial barcodes, and images of specific gene expressions.| [dge2sdge](../fulldoc/rules/dge2sdge.md#output-files) and [sdge_visual](../fulldoc/rules/sdge_visual.md#output-files)  |

##### Plus Request 
The options below are only for executing the [additional functionalities](../home/workflow_structure.md#plus-workflow). Please make sure you have installed the [additional requirements](../installation/requirement_for_plus.md#output-files) properly.

| Option                | Final Output Files                                                                                  | Details   |
|-----------------------|---------------------------------------------------------------------------------------------------- |---|
| `histology-per-run`   | Geotiff files for coordinate transformation between SGE matrix and histology image.| [historef](../fulldoc/rules/historef.md#output-files)                        |
| `sbcdlo-per-flowcell` | Two spatial barcode maps each aligns tile pairs using one spatial map layout.| [sbcd_layout](../fulldoc/rules/sbcd_layout.md)|
| `transcript-per-unit` | An SGE matrix in the TSV format that is compatible toFICTURE. | [sdgeAR_reformat](../fulldoc/rules/sdgeAR_reformat.md#output-files)          |
| `filterftr-per-unit`  | A feature file for genes that pass gene-based filtering, formatted as a TSV file that contains detailed information about each gene. | [sdgeAR_featurefilter](../fulldoc/rules/sdgeAR_featurefilter.md#output-files)    |
| `filterpoly-per-unit` | An SGE matrix, a coordinate metadata file, a feature file, and a boundary JSON file, all reflecting the SGE matrix that passed the polygon-based density filtering.| [sdgeAR_polygonfilter](../fulldoc/rules/sdgeAR_polygonfilter.md#output-files)|
| `segment-10x-per-unit`| A hexagon-indexed SGE matrix in the 10x genomics format. |[sdgeAR_segment_10x](../fulldoc/rules/sdgeAR_segment_10x.md#output-files) |
| `segment-ficture-per-unit`| A hexagon-indexed SGE matrix in the FICTURE-compatible TSV format. | [sdgeAR_segment_ficture](../fulldoc/rules/sdgeAR_segment_ficture.md#output-files) |