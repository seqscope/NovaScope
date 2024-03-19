# Welcome to NovaScope documentation

## Introduction

NovaScope is a [Snakemake](https://snakemake.readthedocs.io/en/stable/)-based pipeline that processes spatial transcriptomics data generated from the [Seq-Scope](https://doi.org/10.1016/j.cell.2021.05.010). Currently, it is tailored to process the spatial arrays generated from the Illumina [NovaSeq 6000](https://www.illumina.com/systems/sequencing-platforms/novaseq.html) platform.

The pipeline is designed to process raw sequencing data (1st-seq and 2nd-seq), align reads to the reference genome, and produce spatial gene expression at the submicron resolution. The pipeline is designed to be modular and flexible, allowing users to customize the pipeline to their specific needs. 

The pipeline is designed to be run on a Unix-based high-performance computing (HPC) system, either locally or through the [Slurm](https://slurm.schedmd.com/documentation.html) workload manager.

NovaScope consists of primarily two steps as shown in the figure below.

<figure markdown="span">
![Novascope Overview](images/novascope_overview.png){ width="100%" }
</figure>
**Figure 1: Overview of the NovaScope pipeline:** Step 1 processes the 1st-seq FASTQ files to generate spatial barcode maps for each "Chip", a 10x6 array of tiles. Step 2 processes the 2nd-seq FASTQ files, aligns reads to the reference genome, and produces spatial gene expression at submicron resolution.  
