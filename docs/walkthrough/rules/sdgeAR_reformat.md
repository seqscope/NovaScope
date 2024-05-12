# Rule `sdgeAR_reformat`:

## Purpose
The `sdgeAR_reformat` prepares the spatial digital gene expression matrix (SGE) in [FICTURE](https://seqscope.github.io/ficture/)-compatible format. This rule also offers gene-filtering function, when preparing the [FICTURE](https://seqscope.github.io/ficture/)-compatible SGE, depends on the user-defined parameters in the job configuration file.

## Input Files
* **Spatial Digital Gene Expression Matrix (SGE) and its Metadata File for Coordinates**
Required input files include a SGE file and its meta file for X Y coordinates. Those files are required to be stored in the `sgeAR` subfolder in the `analysis` directory. This could be generated by Rule [`sdge2sdgeAR`](./sdge2sdgeAR.md) or manually prepared by the users.

## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/analysis/<run_id>/<unit_id>/preprocess
```

### (1) FICTURE-compatible SGE

**Description**: A SGE in the FICTURE format is generated, which contains all informations including the barcode information, features information, and count for each genomic feature. 

**File Naming Convention**: 
```
<unit_id>.merged.matrix.tsv.gz
```

**File Format**:
```
#lane  tile  X      Y        gene_id             gene    gn  gt  spl  unspl  ambig
1      1     5982   1439022  ENSMUSG00000029368  Alb     1   1   1    0      0
1      1     8173   6863206  ENSMUSG00000053907  Mat2a   1   1   0    0      0
1      1     8729   6830792  ENSMUSG00000037071  Scd1    1   1   1    0      0
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

### (2) Two Tab-delimited Feature Files
**Description**: This include a feature file (`*.feature.tsv.gz `) that contains information for all features and another feature file (`*.feature.clean.tsv.gz `) that contains information for features aftering the gene-filtering.

**File Naming Convention**:
```
<unit_id>.feature.tsv.gz 
<unit_id>.feature.clean.tsv.gz
```

**File Format**:
Those two feature files share the same format:

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
```yaml
downstream:               
  gene_filter:            
   keep_gene_type: "protein_coding,lncRNA"    # genes to keep
   rm_gene_regex: "^Gm\\d+|^mt-|^MT-"         # genes to remove
```

* **The `keep_gene_type` Parameter**
Specifies the types of genes to retain during gene filtering. 

* **The `rm_gene_regex` Parameter**
Defines the types of genes to be excluded during gene filtering. 

!!! info
    It is important to note that both parameters utilizes regular expressions.

## Dependencies
Given `sdgeAR_reformat` requires input from Rule `sdge2sdgeAR`, Rule `sdgeAR_reformat` can only execute after `sdge2sdgeAR` and its prerequisite rules have successfully completed their operations. See an overview of the rule dependencies in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet
The code for this rule is provided in [`a07_sdgeAR_reformat.smk`](https://github.com/seqscope/NovaScope/blob/main/rules/a07_sdgeAR_reformat.smk).