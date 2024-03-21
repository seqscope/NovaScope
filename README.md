# NovaScope

NovaScope is a [Snakemake](https://snakemake.readthedocs.io/en/stable/)-based pipeline that processes spatial transcriptomics data generated from the [Seq-Scope](https://doi.org/10.1016/j.cell.2021.05.010). Currently, it is tailored to process the spatial arrays generated from the Illumina [NovaSeq 6000](https://www.illumina.com/systems/sequencing-platforms/novaseq.html) platform.

Please find a detailed tutorial at: https://seqscope.github.io/NovaScope.

## Installation

To run NovaScope, please 
* follow [this instruction](https://seqscope.github.io/NovaScope/installation/requirement/) to install Novascope, snakemake and other dependent softwares, and download reference datasets;
* follow [this instruction](https://seqscope.github.io/NovaScope/installation/env_setup/) to set up an environment configuration file;
* if you're an HPC user who prefers using SLURM for job management, consider checking out [this instruction](https://seqscope.github.io/NovaScope/installation/slurm/) to configure a job management profile.

## Examples

We provide two examples in the [testrun section](./testrun), complete with concise instructions for:
* [preparing the input data and configuration file](https://seqscope.github.io/NovaScope/getting_started/prep_input/);
* [running NovaScope](https://seqscope.github.io/NovaScope/getting_started/execute/);
* [understanding the output](https://seqscope.github.io/NovaScope/getting_started/output/).