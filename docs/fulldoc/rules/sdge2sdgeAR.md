# Rule `sdge2sdgeAR`:

## Purpose
The `dge2sdgeAR` rule is designed to facilitate the utilization of the transcript-indexed spatial digital gene expression (SGE) matrix in NovaScope's reformatting features. The main function of Rule `dge2sdgeAR` is creating a link from the original SGE located at `<output_directory>/align/<flowcell_id>/<chip_id>/<run_id>/sge` to the directory `<output_directory>/analysis/<run_id>/<unit_id>/sgeAR`. 

The use of the `sgeAR` subfolder instead of the direct `sge` directory allows for any necessary manual preprocessing of the SGE before reformatting. For more details, see [The `sgeAR` Subfolder and Manual Preprocess](../../basic_usage/output.md#analysis).

## Input Files
* **Spatial Digital Gene Expression (SGE) Matrix and relevant files**
Required input files include a SGE, its related visualizations, and the meta file for X Y coordinates, which are created by Rule [`dge2sdge`](./dge2sdge.md).

## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/analysis/<run_id>/<unit_id>/sgeAR
```

These output files are identical to those produced by the [`dge2sdge`](./dge2sdge.md) rule, as `dge2sdgeAR` does not modify the files but merely relocates them for easier access and further processing.

## Output Guidelines
No action is required.

## Parameters
No additional parameter is applied in this rule.

## Dependencies
Given the input from Rule `dge2sdge` serve as the input for `sdge2sdgeAR`, Rule `sdge2sdgeAR` can only execute if the input SGE is available or the dependent rules have successfully completed their operations. See an overview of the rule dependencies in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet
The code for this rule is provided in [`c01_sdge2sdgeAR.smk`](https://github.com/seqscope/NovaScope/blob/main/rules/c01_sdge2sdgeAR.smk).
