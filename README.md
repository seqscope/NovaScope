# NovaScope

A pipeline to preprocess the spatial transcriptomics data from Novaseq.

Please find a detailed tutorial at: https://seqscope.github.io/NovaScope.

## Installation

To run NovaScope, please 
* follow [docs/installation/requirement.md](docs/installation/requirement.md) to install Novascope, snakemake and other dependent softwares, and download reference datasets;
* follow [docs/installation/env_setup.md](docs/installation/env_setup.md) to set up an environment configuration file;
* if you're an HPC user who prefers using SLURM for job management, consider checking out [docs/installation/slurm.md](docs/installation/slurm.md) to configure a job management profile.

## Examples

We provide two examples in the [testrun section](./testrun), complete with concise instructions for:
* [preparing the input data and configuration file](./docs/prep_input.md);
* [running NovaScope](./docs/execute.md);
* [understanding the output](./docs/output.md).