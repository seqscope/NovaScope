# Rule `sdgeAR_segment_10x`:

## Purpose
The `sdgeAR_segment_10x` transforms transcript-indexed spatial digitial gene expression (SGE) matrix into hexagon-indexed SGE matrix by aggregating pixels into hexagonal grids, the size of which is determined by the user. This hexagon-indexed SGE matrix will be in 10x genomics format.


## Input Files
* **A SGE matrix in a FICTURE-compatible Format and Correspondings Files**
The necessary input files include a FICTURE-compatible SGE matrix and its corresponding meta file for X and Y coordinates. If the user requests 
filtered hexagon-indexed SGE matrix (i.e., `quality_control` field in the [job configuration](../../basic_usage/job_config.md) file is `TRUE`), this rule uses the filtered SGE matrix and its meta file for coordinates from Rule [`sdgeAR_polygonfilter`](./sdgeAR_polygonfilter.md). Otherwise, it uses the raw SGE matrix created by Rule [`sdgeAR_reformat`](./sdgeAR_reformat.md) and its meta file for coordinates from Rule [`sdgeAR_minmax`](./sdgeAR_minmax.md). 

* **(Optional) A Strict Boundary GEOJSON File**
When segmenting a filtered SGE matrix, the strict boundary GEOJSON file from Rule [`sdgeAR_polygonfilter`](./sdgeAR_polygonfilter.md) will be applied.


## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/analysis/<run_id>/<unit_id>/segment/gn.<sge_qc>.d_<hexagon_width>/10x
```
* `<sge_qc>` stands for whether gene-filtering and polygon-filtering have been applied to the SGE matrix. For filtered SGE, `<sge_qc>` is set to `filtered`. Otherwise, `<sge_qc>` is `raw`.
* `<hexagon_width>` represents the hexagon size.

### (1) hexagon-indexed SGE in 10x Genomics Format

**Description**: This output consists of an SGE formatted by segmenting pixels into hexagonal units. The size of the hexagons is defined by the user. The format of this SGE conforms to the 10x Genomics standard.

**File Naming Convention**: 
```
barcodes.tsv.gz
features.tsv.gz
matrix.mtx.gz
```

**File Format**:

!!! warning
    The `barcodes.tsv.gz` and `features.tsv.gz` in the hexagon-indexed SGE is a bit different from those in the transcript-indexed SGE illustrated in Rule [`dge2sdge`](./dge2sdge.md).

* `barcodes.tsv.gz`:
```
1_0.0_3059096.64_1620124.64_11
2_0.0_3727394.36_3208789.64_11
3_0.0_4140308.56_2215259.44_17
```
    * Column 1: hexagon IDs

* `features.tsv.gz`:
```
ENSMUSG00000029368	Alb	    Gene Expression
ENSMUSG00000002985	Apoe	  Gene Expression
ENSMUSG00000078672	Mup20 	Gene Expression
```
    * Column 1: Gene Ensemble ID
    * Column 2: Gene symbol
    * Column 3: Gene info

* `matrix.mtx.gz`:
```
%%MatrixMarket matrix coordinate integer general
%
33951 79179 11120678
826 1 1
13 1 1
3935 1 1
```
    * `Header`: Initial lines form the header, declaring the matrix's adherence to the [Market Matrix (MTX) format](https://math.nist.gov/MatrixMarket/formats.html), outlining its traits. This may include comments (lines beginning with `%`) for extra metadata, all marked by a “%”.
    * `Dimensions`: Following the header, the first line details the matrix dimensions: the count of rows (features), columns (barcodes), and non-zero entries.
    * `Data Entries`: Post-dimensions, subsequent lines enumerate non-zero entries in seven columns: row index (feature index), column index (barcode index), and five values (expression levels) corresponds to Gene, GeneFull, Spliced, Unspliced, and Ambiguous.

## Output Guidelines
The output file can serve as input for tools that require hexagon-indexed SGE in the 10x genomics format, such as Seurat.

## Parameters
```yaml
downstream:
  mu_scale: 1000        
 segment:
   hex_n_move: 1                              ## specify the sliding step in segmentation
   precision: 2                               ## specify the precision parameter for segmentation                   
   10x:                                       ## specify the parameters for creating hexagon-indexed SGE in 10x genomics format    
     min_pixel_per_unit: 10                   ## specify a minimum UMI count of hexagons
     char:                                    ## specify the characteristics for hexagon segmentation, including genomic feature, hexagon size and SGE filtering
       - solo_feature: gn                     ## genomic feature
         hexagon_width: 24                    ## hexagonal grid width
         quality_control: FALSE               ## if both gene-filtering and polygon-filtering should be applied
     # - ...                                  ## if more than 1 set of hexagon is needed ```
```

* **The `mu_scale` Parameter**
  Specify the coordinate-to-micron translation for hexagons. By default, the spatial digital gene expression (SGE) matrix is considered to be in nanometers.

* **The `segment` Field**
  * **The `hex_n_move` Parameter**
    Specify the sliding steps. When `hex_n_move` is set to 1, non-overlapping hexagon-indexed SGE will be created.
  * **The `precision` Parameter**
    Define the number of digits to store spatial location (in microns, 0 for integer).
  * **The `10x` Parameter**
    * **The `min_pixel_per_unit` Parameter**
      Set a minimum UMI count for output hexagons.
    * **The `char` Parameter**
      Specify the characteristics for the hexagons, including the genomic feature to create hexagons (`solo_feature`), the size of the hexagonal grid (`hexagon_width`), and whether gene-filtering and polygon-filtering should be applied (`quality_control`). This allows for multiple sets of parameters.

## Dependencies
When `quality_control` is enabled, Rule `sdgeAR_segment_10x` can only be executed after the completion of Rule `sdge2sdgeAR` and `sdgeAR_polygonfilter` along with their prerequisite rules. Otherwise, Rule `sdgeAR_segment_10x` can only be executed after the completion of `sdge2sdgeAR`, `sdgeAR_polygonfilter`, `sdgeAR_minmax`, and their prerequisite rules.

See an overview of the rule dependencies in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet
The code for this rule is provided in [`c04_sdgeAR_segment_10x.smk`](https://github.com/seqscope/NovaScope/blob/main/rules/c04_sdgeAR_segment_10x.smk).
