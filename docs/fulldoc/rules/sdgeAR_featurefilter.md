# Rule `sdgeAR_featurefilter`:

## Purpose
The `sdgeAR_featurefilter` filters the transcript-indexed spatial digital gene expression matrix (SGE) by gene types, gene names, or number of UMIs.

## Input Files

* **A Tab-delimited Feature File**
Required the feature file from Rule [`sdgeAR_reformat`](./sdgeAR_reformat.md).

## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/analysis/<run_id>/<unit_id>/preprocess
```

### (1) A Tab-delimited Clean Feature File

**Description**: A clean feature file (`*.feature.clean.tsv.gz`) that counts UMIs for features aftering gene-filtering.

**File Naming Convention**:
```
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
No action is required.

## Parameters
```yaml
downstream:               
 gene_filter:                                 
   keep_gene_type: "protein_coding|lncRNA"    
   rm_gene_regex: "^Gm\\d+|^mt-|^MT-"         
   min_ct_per_feature: 50                     
```

* **The `keep_gene_type` Parameter**
Specifies the types of genes to retain during gene filtering. 

* **The `rm_gene_regex` Parameter**
Defines the types of genes to be excluded during gene filtering. 

* **The `min_ct_per_feature` Parameter**
Defines the minimal UMI count for genes. Genes of which number of UMI is smaller than this cutoff will be removed.

!!! info
    It is important to note that both `keep_gene_type` and `rm_gene_regex` parameters utilizes regular expressions.

## Dependencies
Given `sdgeAR_featurefilter` requires input from Rule `sdgeAR_reformat`, Rule `sdgeAR_featurefilter` can only execute after `sdgeAR_reformat` and its prerequisite rules have successfully completed their operations. See an overview of the rule dependencies in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet
The code for this rule is provided in [`c03_sdgeAR_featurefilter.smk`](https://github.com/seqscope/NovaScope/blob/main/rules/c03_sdgeAR_featurefilter.smk).
