# Rule `sdgeAR_polygonfilter`:

## Purpose
The `sdgeAR_polygonfilter` filters the transcript-indexed spatial digital gene expression (SGE) matrix by UMI density in polygons.

## Input Files
* **A SGE in FICTURE-compatible Format**
A transcript-indexed SGE in the FICTURE format, which is generated by Rule [`sdgeAR_reformat`](./sdgeAR_reformat.md).

* **A Tab-delimited Clean Feature File**
Required the clean feature file from Rule [`sdgeAR_featurefilter`](./sdgeAR_featurefilter.md).

* **A Metadata File for X Y Coordinates**
A meta file for the minimum and maximum X Y coordinates to determine the major axis. This will be generated by Rule [`dge2sdgeAR`](./sdge2sdgeAR.md) or by the user manually.

## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/analysis/<run_id>/<unit_id>/preprocess
```

### (1) A Filtered SGE Matrix in FICTURE-compatible Format 
**Description**: A filtered SGE matrix in FICTURE-compatible TSV format.

**File Naming Convention**: 
```
<unit_id>.<solo_feature>.filtered.transcripts.tsv.gz
```
* `<solo_feature>`: Genomic feature.

**File Format**:
```
#lane  tile  X        Y        gene_id             gene      gn  gt  spl  unspl  ambig
1      1     3786011  3653012  ENSMUSG00000107002  Ncbp2as2  1   1   1    0      0
1      1     3786011  3660560  ENSMUSG00000020743  Mif4gd    1   1   1    0      0
1      1     3786533  3650195  ENSMUSG00000039323  Igfbp2    1   1   1    0      0
```

 * `#lane`: lane ID
 * `tile`: tile ID
 * `X`: X-coordinate
 * `Y`: Y-coordinate
 * `gene_id`: Gene Ensemble ID
 * `gene`: Gene symbol
 * `gn`: the count per gene per barcode for Gene
 * `gt`: the count per gene per barcode for GeneFull
 * `spl`: the count per gene per barcode for Spliced
 * `unspl`: the count per gene per barcode for Unspliced
 * `ambig`: the count per gene per barcode for Ambiguous

### (2) Two Filtered Tab-delimited Feature Files
**Description**: Two feature files representing genes filtered by the strict boundary and by the lenient boundary, respectively.

**File Naming Convention**:
```
<unit_id>.<solo_feature>.filtered.feature.lenient.tsv.gz 
<unit_id>.<solo_feature>.filtered.feature.strict.tsv.gz 
```
* `<solo_feature>`: Genomic feature.

**File Format**:
Those two feature files share the same format:

```
gene            gene_id             gn      gt      spl     unspl  ambig
0610005C13Rik   ENSMUSG00000109644  3967    3979    3530    8      432
0610009B22Rik   ENSMUSG00000007777  208     262     208     0      0
0610030E20Rik   ENSMUSG00000058706  342     371     339     0      2
```

 * `gene_id`: Gene Ensemble ID
 * `gene`: Gene symbol
 * `gn`: the count per gene per barcode for Gene
 * `gt`: the count per gene per barcode for GeneFull
 * `spl`: the count per gene per barcode for Spliced
 * `unspl`: the count per gene per barcode for Unspliced
 * `ambig`: the count per gene per barcode for Ambiguous


### (3) Two Boundary JSON Files
**Description**: One strict boundary file and one lenient boundary file. Both are demonstrated by coordinates in JSON files.

**File Naming Convention**:
```
<unit_id>.<solo_feature>.filtered.boundary.lenient.geojson 
<unit_id>.<solo_feature>.filtered.boundary.strict.geojson
```
* `<solo_feature>`: Genomic feature.

**File Format**:
See details for JSON files at: https://en.wikipedia.org/wiki/JSON.

### (4) A Metadata File for X Y Coordinates
**Description**: This file contains the minimum and maximum X Y coordinates for the filtered SGE matrix.

**File Naming Convention**:
```
<unit_id>.<solo_feature>.filtered.coordinate_minmax.tsv
```
* `<solo_feature>`: Genomic feature.

**File Format**:
```
xmin	-27.973391144511698
xmax	8699.068916753664
ymin	-26.25
ymax	5144.932078838597
```
- `xmin`: The minimum x-coordinate in micrometers across all barcodes in the filtered SGE matrix.
- `xmax`: The maximum x-coordinate in micrometers across all barcodes in the filtered SGE matrix.
- `ymin`: The minimum y-coordinate in micrometers across all barcodes in the filtered SGE matrix.
- `ymax`: The maximum y-coordinate in micrometers across all barcodes in the filtered SGE matrix.


## Output Guidelines
The output file could be used as the input for [FICTURE](https://seqscope.github.io/ficture/).

## Parameters
```yaml
downstream:               
 polygon_density_filter:          
   radius: 15               
   hex_n_move: 1            
   polygon_min_size: 500    
   quartile: 2
```

* **The `radius` Parameter**
The radius refers to the circumradius (the radius of the circumscribed circle around the polygon). The radius will be used to calcualte the polygon diameter as well as the polygon area.

* **The `hex_n_move` Parameter**
Define n moves when collapse to polygon. When `hex_n_move` is 1, non-overlapping polygons will be applied. Otherwise, use overlapping polygons.

* **The `polygon_min_size` Parameter**
If provided, remove small and isolated polygons (squared um)

* **The `quartile` Parameter**
Specify which quartiles of the data should be considered for polygon-filtering. The `quartile` will be used to define the strict density cutoff. The `quartile` have four options: 0, 1, 2, 3, which corresponds to minimal, first quartile, median, and third quartile.

## Dependencies
Rule `sdgeAR_polygonfilter` executes only after `sdge2sdgeAR`, `sdgeAR_reformat`, `sdgeAR_featurefilter`, and their prerequisites are completed. See the [Workflow Structure](../../home/workflow_structure.md) for dependencies.

## Code Snippet
The code for this rule is provided in [`c03_sdgeAR_polygonfilter.smk`](https://github.com/seqscope/NovaScope/blob/main/rules/c03_sdgeAR_polygonfilter.smk).