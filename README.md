# NovaScope

NovaScope is a [Snakemake](https://snakemake.readthedocs.io/en/stable/)-based pipeline that processes spatial transcriptomics data generated from the [Seq-Scope](https://doi.org/10.1016/j.cell.2021.05.010). Currently, it is tailored to process the spatial arrays generated from the Illumina [NovaSeq 6000](https://www.illumina.com/systems/sequencing-platforms/novaseq.html) platform.

Please find a detailed tutorial at: https://seqscope.github.io/NovaScope.

The preprint is available at: [DOI: 10.1101/2024.03.29.587285](https://www.biorxiv.org/content/10.1101/2024.03.29.587285v1).

## Installation

To run NovaScope, please 
* follow [this instruction](https://seqscope.github.io/NovaScope/installation/requirement/) to install Novascope, snakemake and other dependent softwares, and download reference database;
* follow [this instruction](https://seqscope.github.io/NovaScope/installation/env_setup/) to set up an environment configuration file;
* if you're an HPC user who prefers using SLURM for job management, consider checking out [this instruction](https://seqscope.github.io/NovaScope/installation/slurm/) to configure a job management profile.

## Examples

We provide three examples in the [testrun folder](./testrun), complete with [concise instructions](https://seqscope.github.io/NovaScope/basic_usage/intro/), including:
* [Accessing Example Datasets](https://seqscope.github.io/NovaScope/basic_usage/access_data/);
* [Configuring a NovaScope Run](https://seqscope.github.io/NovaScope/basic_usage/job_config/);
* [Executing the NovaScope Pipeline](https://seqscope.github.io/NovaScope/basic_usage/execute/);
* [Understanding the Output](https://seqscope.github.io/NovaScope/basic_usage/output/).