# Rule `smatch`

## Purpose
The `smatch` rule examines that for a pair of 2nd-seq FASTQ files, if spatial barcode sequence (HDMI) in read 1 are found in the spatial barcodes map for this chip section. The `smatch` functions on a per-pair basis for 2nd-seq FASTQ files. This means that for a given chip of interest, which is associated with multiple pairs of 2nd-seq FASTQ files, NovaScope executes `smatch` for each pair in parallel.

## Input Files

* **Per-Chip Spatial Barcode Maps & Manifest File**
Required input files include the spatial barcode map and manifest file for the chip of interest, which are created by the [`sbcd2chip`](./sbcd2chip.md) rule.

* **The 2nd-seq FASTQ files**
Required input files also include the read 1 file for a pair of 2nd-seq FASTQ files.

## Output Files
The following files are generated for each pair of 2nd-seq FASTQ files in the specified directory path below:

```
<output_directory>/match/<flowcell_id>/<chip_id>/<seq2nd_id>
```

### (1) A Matched Spatial Barcode File

**Description**:
A compressed, tab-delimited file containing spatial barcodes matched to the 2nd-seq reads.

**File Naming Convention**:
`<seq2st_pair_id>.R1.match.sorted.uniq.tsv.gz`

**File Format**:

```
AAAAAAAATAGTTCTGCTAGCTGGTAAGCTA  1  1  7124822  2910007  1  6
AAAAAAAGTGATCAGAGGTGATATTATGCTT  1  1  7382402  2721048  1  6
AAAAAAAGTTCGCACTATACGAACAGGGATC  1  1  8634969  2843056  1  1
```

* Column 1: Spatial barcode sequence
* Column 2: Lane ID, which is defined as `1`.
* Column 3: Tile ID, which is defined as `1`.
* Column 4: X-coordinate within the chip (global X-coordinate).
* Column 5: Y-coordinate within the chip (global Y-coordinate).
* Column 6: Number of bases that do not match the expected pattern defined by the format (0 is a perfect match).
* Column 7: Number of occurrences in the 2nd-seq FASTQ read 1 file.

### (2) A "smatch" Image
**Description**:
An image depicting the spatial coordinate distribution of the matched barcodes.

**File Naming Convention**:
`<seq2st_pair_id>.R1.match.png`

**File Visualization**:
<figure markdown="span">
![smatch_image](../../images/smatch.png){ width="80%" }
</figure>

### (3) An Overall Summary of Matching Results
**Description**:
A summary of the count and fraction of 2nd-seq reads based on the matching results.

**File Naming Convention**:
`<seq2st_pair_id>.R1.summary.tsv`

**File Format**:

```
Type        Reads      Fraction
Total       163383382  1.00000
Miss        80020087   0.48977
Match       83363295   0.51023
Unique      17641021   0.10797
Dup(Exact)  65722274   0.40226
```

* `Type` : The type of statistics, including the following values:
    * `Total` : All reads in the 2nd-seq FASTQ file.
    * `Miss` : Reads that do not contain matching spatial barcodes.
    * `Match` : Reads that match with a spatial barcode.
    * `Unique` : Unique spatial barcodes that has matches.
    * `Dup(Exact)` : Duplicate barcodes calculated as Match - Unique.
* `Reads` : The number of reads or barcodes that match the type.
* `Fraction` : The fraction of the reads (among all reads) that match the type.

### (4) A Summary of Matched and Unique Barcodes
**Description**:
A tab-delimited file containing the number of matched and unique spatial barcodes.

**File Naming Convention**:
`<seq2st_pair_id>.R1.counts.tsv`

**File Format**:

```
id   filepath                 barcodes   matches   unique
1_1  1_1.sbcds.sorted.tsv.gz  175135683  83363295  17641021
```

- `id`: The `id` is composed of `<lane_id>_<tile_id>`. Given only one spatial barcode map is created for a chip, the ID is designed as `1_1`.
- `filepath`: The file name is the corresponding spatial barcode map.
- `barcodes`: The number of spatial barcodes in the chip.
- `matches`: The number of barcodes match to the expected pattern.
- `unique`: The number of unique barcodes match to the expected pattern.

## Output Guidelines
Suggested review steps:

1. Examine summary files to verify that the matched barcode rate isn't low rate, such as < 5%. A low matching rate might indicate a possible sample swap.
2. Inspect the "smatch" image for an even distribution of matched barcodes across the tissue area. An unexpected pattern may suggest issues with experimental procedures, like unsuccessful tissue permeabilization.

## Parameters
The following parameter in the [job configuration](../../basic_usage/job_config.md) file will be applied in this rule.

```yaml
upstream:
  smatch:                  
    skip_sbcd: 1            
    match_len: 27           
  visualization:
    drawxy:
      coord_per_pixel: 1000
      intensity_per_obs: 50
      icol_x: 3
      icol_y:
```

* **The `smatch` Parameters**

    Parameters for `smatch`, used to pass values to the [`match-sbcds`](https://seqscope.github.io/spatula/tools/match_sbcds/) function in [spatula](https://seqscope.github.io/spatula/). Below, for each parameter, the corresponding parameter in [spatula](https://seqscope.github.io/spatula/), description, and the default value in NovaScope are provided.

    | Parameter     | `spatula` parameter| Description                                                                                   | Default Value |
    |---------------|---------------------|-----------------------------------------------------------------------------------------------|----------------------------|
    | `skip_sbcd`   | `--skip-sbcd`       | The number of initial bases to omit from the read.*   | 1                          |
    | `match_len`   | `--match-len`       | The length of the spatial barcode to be considered as a perfect match.                         | 27                         |

    * `skip_sbcd`: This is useful if the 1st-seq spatial barcode lacks sufficient bases. When it is absent, NovaScope determines `skip_sbcd` following the [`format`](./fastq2sbcd.md#parameters) of `fastq2sbcd`: 1 for DraI31 and 0 for DraI32.

* **The `visualization` Parameters**

    Parameters for the `visualization` step, provided to the [`draw-xy`](https://seqscope.github.io/spatula/tools/draw_xy/) function in [spatula](https://seqscope.github.io/spatula/).

    | Parameter         | `spatula` parameter    | Description                                                                     | Default Value |
    |-------------------|-------------------------|---------------------------------------------------------------------------------|----------------------------|
    | `coord_per_pixel` | `--coord-per-pixel`     | Coordinates per pixel, as a divisor of input coordinate.                        | 1000                       |
    | `intensity_per_obs` | `--intensity-per-obs` | Intensity of points per pixel, max 255.                                         | 50                         |
    | `icol_x`          | `--icol-x`              | (0-based) index of X coordinate in input TSV.                                   | 3                          |
    | `icol_y`          | `--icol-y`              | (0-based) index of Y coordinate in input TSV.                                   | 4                          |


## Dependencies
The `sbcd2chip` requires the successful execution of [`sbcd2chip`](./sbcd2chip.md) to operate as intended. An overview of the rule dependencies are provided in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet
The code for this rule is provided in [a03_smatch.smk](https://github.com/seqscope/NovaScope/blob/main/rules/a03_smatch.smk)
