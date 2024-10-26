# Rule `sdgeAR_segment_ficture`:

## Purpose
The `sdgeAR_segment_ficture` transforms transcript-indexed SGEs into hexagon-indexed SGEs by aggregating pixels into hexagonal grids, the size of which is determined by the user. This hexagon-indexed SGEs will be in a TSV format that is compatible for FICTURE.

## Input Files
* **A SGE matrix in a FICTURE-compatible Format and Correspondings Files**
The necessary input files include a FICTURE-compatible SGE matrix and its corresponding meta file for X and Y coordinates. If the user requests filtered hexagon-indexed SGE matrix (i.e., `quality_control` field in the [job configuration](../../basic_usage/job_config.md) file is `TRUE`), this rule uses the filtered SGE matrix and its meta file for coordinates from Rule [`sdgeAR_polygonfilter`](./sdgeAR_polygonfilter.md). Otherwise, it uses the raw SGE matrix created by Rule [`sdgeAR_reformat`](./sdgeAR_reformat.md) and its meta file for coordinates from Rule [`sdgeAR_minmax`](./sdgeAR_minmax.md). 

* **(Optional) A Strict Boundary GEOJSON File**
When segmenting a filtered SGE matrix, the strict boundary GEOJSON file from Rule [`sdgeAR_polygonfilter`](./sdgeAR_polygonfilter.md) will be applied.


## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/analysis/<run_id>/<unit_id>/segment/gn.<sge_qc>.d_<hexagon_width>/10x
```
* `<sge_qc>` stands for whether gene-filtering and polygon-filtering have been applied to the SGE matrix. For filtered SGE, `<sge_qc>` is set to `filtered`. Otherwise, `<sge_qc>` is `raw`.
* `<hexagon_width>` represents the hexagon size.

### (1) hexagon-indexed SGE

**Description**: This output consists of an SGE formatted by segmenting pixels into hexagonal units. The size of the hexagons is defined by the user. This SGE is in TSV format compatible to FICTURE.

**File Naming Convention**: 
```
<unit_id>.<solo_feature>.<sge_qc>.d_<hexagon_width>.hexagon.tsv.gz
```

**File Format**:
```
random_index        X        Y        gene           gn  gt  spl  unspl  ambig
000000883847207954  6066.00  3180.05  1600014C10Rik  1   1   1    0      0
000000883847207954  6066.00  3180.05  Abcb11         1   1   1    0      0
000000883847207954  6066.00  3180.05  Acaa2          1   1   1    0      0
```

* `random_index`: Hexagon IDs.
* `X`: X-coordinates.
* `Y`: Y-coordinates.
* `gene`: Gene names.
* `gn`:  The number of UMI counts for Gene per hexagon.
* `gt`:  The number of UMI counts for GeneFull per hexagon.
* `spl`:  The number of UMI counts for Spliced per hexagon.
* `unspl`:  The number of UMI counts for Unspliced per hexagon.
* `ambig`:  The number of UMI counts for Ambiguous per hexagon.

## Output Guidelines
The output file can serve as input for Latent Dirichlet Allocation in FICTURE.

## Parameters
```yaml
downstream:
  mu_scale: 1000        
  segment:
   hex_n_move: 1                              ## specify the sliding step in segmentation
   precision: 2                               ## specify the precision parameter for segmentation                   
   ficture:                                   ## specify the parameters for creating hexagon-indexed SGE in FICTURE-compatible format    
     min_density: 0.3                         ## specify a minimum density of UMIs for hexagon
     char:                                    ## specify the characteristics for hexagon segmentation, including genomic feature, hexagon size and SGE filtering
       - solo_feature: gn                     ## genomic feature
         hexagon_width: 24                    ## hexagonal grid width
         quality_control: TRUE                ## if both gene-filtering and polygon-filtering should be applied
     # - ...                                  ## if more than 1 set of hexagon is needed ```
```

* **The `mu_scale` Parameter**
  Specify the coordinate-to-micron translation for hexagons. By default, the spatial digital gene expression (SGE) matrix is considered to be in nanometers.

* **The `segment` Field**
  * **The `hex_n_move` Parameter**
    Specify the sliding steps. When `hex_n_move` is set to 1, non-overlapping hexagon-indexed SGE will be created.
  * **The `precision` Parameter**
    Define the number of digits to store spatial location (in microns, 0 for integer).
  * **The `ficture` Parameter**
    * **The `min_density` Parameter**
      Set a minimum density of UMI counts when creating hexagon
    * **The `char` Parameter**
      Specify the characteristics for the hexagons, including the genomic feature to create hexagons (`solo_feature`), the size of the hexagonal grid (`hexagon_width`), and whether gene-filtering and polygon-filtering should be applied (`quality_control`). This allows for multiple sets of parameters.
      
## Dependencies
When `quality_control` is enabled, Rule `sdgeAR_segment_ficture` can only be executed after the completion of Rule `sdge2sdgeAR` and `sdgeAR_polygonfilter` along with their prerequisite rules. Otherwise, Rule `sdgeAR_segment_ficture` can only be executed after the completion of `sdge2sdgeAR`, `sdgeAR_polygonfilter`, `sdgeAR_minmax`, and their prerequisite rules. 

See an overview of the rule dependencies in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet
The code for this rule is provided in [`c04_sdgeAR_segment_ficture.smk`](https://github.com/seqscope/NovaScope/blob/main/rules/c04_sdgeAR_segment_ficture.smk).
