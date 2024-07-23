# NovaScope

NovaScope is a [Snakemake](https://snakemake.readthedocs.io/en/stable/)-based pipeline designed for processing spatial transcriptomics data generated from [Seq-Scope](https://doi.org/10.1016/j.cell.2021.05.010). Currently, it is optimized for handling spatial arrays produced by the Illumina [NovaSeq 6000](https://www.illumina.com/systems/sequencing-platforms/novaseq.html) platform.

For a detailed tutorial, please visit [NovaScope Tutorial](https://seqscope.github.io/NovaScope).

You can find the preprint at [DOI: 10.1101/2024.03.29.587285](https://www.biorxiv.org/content/10.1101/2024.03.29.587285v1).

## Installation

To install and set up NovaScope, please follow these steps:
* Refer to [this guide](https://seqscope.github.io/NovaScope/installation/requirement/) to install NovaScope, Snakemake, and other required software, and to download the reference database.
* Follow [this guide](https://seqscope.github.io/NovaScope/installation/env_setup/) to set up an environment configuration file.
* If you are an HPC user preferring to use SLURM for job management, please check [this guide](https://seqscope.github.io/NovaScope/installation/slurm/) to configure a job management profile.

## Examples and Basic Usage

We provide three examples in the [testrun folder](./testrun), complete with [concise instructions](https://seqscope.github.io/NovaScope/basic_usage/intro/), including:
* [Accessing Example Datasets](https://seqscope.github.io/NovaScope/basic_usage/access_data/)
* [Configuring a NovaScope Run](https://seqscope.github.io/NovaScope/basic_usage/job_config/)
* [Executing the NovaScope Pipeline](https://seqscope.github.io/NovaScope/basic_usage/execute/)
* [Understanding the Output](https://seqscope.github.io/NovaScope/basic_usage/output/)

## Full Documentation

The Full Documentation serves as a comprehensive overview of NovaScope's functionality, featuring: 
* [A Rule Execution Guide](https://seqscope.github.io/NovaScope/fulldoc/execution_guide/core_concepts/)
* [A Detailed Instruction for Each Rule](https://seqscope.github.io/NovaScope/fulldoc/rules/fastq2sbcd/)


## Exemplary Downstream Analysis

For the spatial digital gene expression matrix created by NovaScope, we provide an exemplary downstream analysis at [NovaScope-exemplary-downstream-analysis (NEDA)](https://seqscope.github.io/NovaScope-exemplary-downstream-analysis/). NEDA demonstrates (1) how to identify spatial factors at a pixel-level resolution and (2) how to identify cell-type clusters by aggregating the SGE matrix at the cellular level according to histology files.
