# Rule `sdgeAR_reformat`:

## Purpose
Reformat the spatial digital gene expression (SGE) matrix from the 10x Genomics format to a [FICTURE](https://seqscope.github.io/ficture/)-compatible TSV format.

## Input Files
* **Spatial Digital Gene Expression (SGE) Matrix and its Metadata File for Coordinates**
Required input files include a SGE matrix and its meta file for X Y coordinates. Those files are required to be stored in the `sgeAR` subfolder in the `analysis` directory. This could be generated by Rule [`sdge2sdgeAR`](./sdge2sdgeAR.md) or manually prepared by the users.

## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/analysis/<run_id>/<unit_id>/preprocess
```

### (1) An SGE in a FICTURE-compatible Format

**Description**: A transcript-indexed SGE in the FICTURE format is generated, which contains all information including the barcode information, features information, and count for each genomic feature.

**File Naming Convention**: 
```
<unit_id>.transcripts.tsv.gz
```

**File Format**:
```
#lane  tile  X     Y        gene_id             gene   gn  gt  spl  unspl  ambig
1      1     5982  1441004  ENSMUSG00000029368  Alb    1   1   1    0      0
1      1     8173  6873084  ENSMUSG00000053907  Mat2a  1   1   0    0      0
1      1     8729  6840669  ENSMUSG00000037071  Scd1   1   1   1    0      0
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

### (2) A Tab-delimited Feature File
**Description**: This include a feature file (`*.feature.tsv.gz`) that counts UMIs for each gene.

**File Naming Convention**:
```
<unit_id>.feature.tsv.gz 
```

**File Format**:

```
gene_id             gene     gn    gt   spl  unspl  ambig
ENSMUSG00000100764  Gm29155  3     3    1    0      2
ENSMUSG00000100635  Gm29157  0     0    0    0      0
ENSMUSG00000100480  Gm29156  0     0    0    0      0
```

 * `gene_id`: Gene Ensemble ID
 * `gene`: Gene symbol
 * `gn`: the count per gene per barcode for Gene
 * `gt`: the count per gene per barcode for GeneFull
 * `spl`: the count per gene per barcode for Spliced
 * `unspl`: the count per gene per barcode for Unspliced
 * `ambig`: the count per gene per barcode for Ambiguous

## Output Guidelines
The output file could be used as the input for [FICTURE](https://seqscope.github.io/ficture/).

## Parameters
No additional parameter is applied in this rule.

## Dependencies

Rule `sdgeAR_reformat` executes only after `sdge2sdgeAR` and its prerequisites are completed. See the [Workflow Structure](../../home/workflow_structure.md) for dependencies.

## Code Snippet
The code for this rule is provided in [`c02_sdgeAR_reformat.smk`](https://github.com/seqscope/NovaScope/blob/main/rules/c02_sdgeAR_reformat.smk).
