# Rule `fastq2sbcd`

## Purpose
The `fastq2sbcd` rule aims to generate a spatial barcode map per-tile basis for an input 1st-seq FASTQ file.

## Input Files
The only input file required by `fastq2sbcd` is the 1st-seq FASTQ file. Ensure the raw FASTQ files are correctly formatted and listed in the [job configuration](../../getting_started/job_config.md) file.

## Output Files
The rule generates the following output in the specified directory path: 
```
<output_directory>/seq1st/<flowcell_id>/sbcds/<seq1st_id>
```

### (1) Per-Tile Spatial Barcode Maps

**Description**:
The spatial barcode map for each tile is stored in a zipped, tab-separated file. These files map the barcodes to their coordinates within the tile, facilitating easier matching with 2nd-Seq sequences through reverse-complemented barcodes.

**File Naming Convention**:
 `<lane_id>_<tile_id>.sbcds.sorted.tsv.gz`

**File Format**:
The format of the spatial barcode map is outlined below with an example:

```
AAAAAAAAAAAAGCGACCGGGTAATATATGT	3	2456	1036	35446	1
AAAAAAGGTACCCGCAGTGCGGACAAACGAA	3	2456	23448	29731	1
AAAAAGACGAGTAAAAGTGACTGTTAATTAC	3	2456	29794	1799	1
```

- Column 1: Spatial barcode sequence (HDMI, typically 32 base pairs).
- Column 2: Lane ID.
- Column 3: Tile ID.
- Column 4: X-coordinate within the tile (local X-coordinate).
- Column 5: Y-coordinate within the tile (local Y-coordinate).
- Column 6: Count of occurrences for each spatial barcode.

### (2) Flow Cell Manifest
**Description**:
The manifest file provides summary statistics for each tile within the input FASTQ file, with each tile's statistics presented in a separate row.

**File Naming Convention**:
`manifest.tsv` 

**File Format**:

```
id      filepath                        barcodes    matches mismatches  xmin    xmax    ymin    ymax
3_2456  3_2456.sbcds.sorted.tsv.gz      3460541     3377518 83023       1027    32949   1000    37059
3_2556  3_2556.sbcds.sorted.tsv.gz      3416413     3334054 82359       1036    32958   1000    37059
```

- `id`: The `id` is composed of `<lane_id>_<tile_id>`.
- `filepath`: The file name is the corresponding spatial barcode map.
- `barcodes`: The number of barcodes in the tile.
- `matches`: The number of barcodes match to the expected pattern.
- `mismatches`: The number of barcodes don't match to the expected pattern.
- `xmin`: The minimum X-coordinate across all barcodes within the tile (i.e., mimimum local X-coordinate).
- `xmax`: The maximum X-coordinate across all barcodes within the tile (i.e., maximum local X-coordinate).
- `ymin`: The minimum Y-coordinate across all barcodes within the tile (i.e., mimimum local Y-coordinate).
- `ymax`: The maximum Y-coordinate across all barcodes within the tile (i.e., maximum local Y-coordinate).

## Output Guidelines
For accuracy purposes, it's recommended to examine the [`manifest.tsv`](#2-flow-cell-manifest) file to verify:

1. A full lane typically comprises 936 tiles, with each tile having 3 million or more reads;
2. The majority of reads are expected to align with the anticipated HDMI patterns.


## Parameters
The following parameter in the [job configuration](../../getting_started/job_config.md) file will be applied in this rule. 

```yaml
upstream:
  fastq2sbcd:
    format: DraI32 
```

* **The `format` Parameter**
This parameter specifies the HDMI-oligo seed library used. The default setting is DraI32, which corresponds to HDMI32-DraI. Please see details for the seed HDMI-oligo library in the original publication of [SeqScope](https://doi.org/10.1016/j.cell.2021.05.010).

## Dependencies
Rule `fastq2sbcd` operates independently without dependencies on preceding rules. An overview of the rule dependencies are provided in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet 
The code for this rule is provided in [`a01_fastq2sbcd.smk`](https://github.com/seqscope/NovaScope/blob/main/rules/a01_fastq2sbcd.smk).