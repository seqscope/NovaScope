# Installing NovaScope

Installing [NovaScope](../index.md) involves multiple steps. This document provides instructions on how to install the necessary software tools and obtain reference datasets.

## Installing Snakemake 

[Snakemake](https://snakemake.readthedocs.io/en/stable/) orchestrates the workflow of [NovaScope](../index.md) pipeline. We recommend installing [Snakemake](https://snakemake.readthedocs.io/en/stable/) using [conda](https://docs.conda.io/en/latest/) and/or [mamba](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html). For detailed installation instructions of these tools, please refer to the [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html). 


### Checking Snakemake Installation
If you are unsure whether [Snakemake](https://snakemake.readthedocs.io/en/stable/) is installed in your system or not, you can check by running the following command:

```sh
snakemake --version
```

In some systems that supports `module`, you may be able to load the `snakemake` module using the following command:

```sh
## check if snakemake is available as a module
module avail snakemake

## load the available module (specify the version if necessary)
module load snakemake
``` 

[NovaScope](../index.md) has been tested for compatibility with [Snakemake](https://snakemake.readthedocs.io/en/stable/) v7.29.0 and v8.6.0.

### Installing Snakemake Using Conda and Mamba

If you need to install [Snakemake](https://snakemake.readthedocs.io/en/stable/), below is a simplified sequence of instruction. Please refer to [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) for more detailed instructions.

```sh
## download miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

## install miniconda
bash Miniconda3-latest-Linux-x86_64.sh
## Follow the on-screen instructions to complete the installation. 

## Activate the Miniconda installation:
## IMPORTANT: change /path/to/miniconda to the path you installed miniconda
eval "$(/path/to/miniconda3/bin/conda shell.bash hook)"

## If you included conda initialization in .bashrc the above line can be replaced with
## source ~/.bashrc

## create a new conda environment
conda create -n snakemake-env python=3.9

## activate the new environment
conda activate snakemake-env

## install mamba in the conda environment
conda install mamba -n snakemake-env

## activate the environment to ensure mamba is correctly set up
conda activate snakemake-env

## install snakemake using mamba
mamba install snakemake

## verify the installation of snakemake
snakemake --version
```

## Configuring Python Virtual Environment

We recommend creating a new Python environment for [NovaScope](../index.md) using the following steps. If you already have an existing Python environment all required packages (see [pyenv_req.txt](https://github.com/seqscope/NovaScope/blob/main/installation/pyenv_req.txt)), you may skip this step. 

You may create a new Python environment using the following commands:

```bash
## First, we recommend activating conda/mamba environment before setting up venv, using:
# eval "$(/path/to/miniconda3/bin/conda shell.bash hook)"
# conda activate snakemake-env
##
## set the path to the python virtual environment directory
pyenv_dir=/path/to/python/virtual/environment/directory  ## provide the path of venv
## pyenv_dir=./venvs   ## uncomment this line if you want to create virtual environment locally
pyenv_name=novascope_venv
smk_dir=/path/to/the/novascope/directory

## create the python virtual environment (need to be done only once)
mkdir -p ${pyenv_dir}
cd ${pyenv_dir}
python -m venv ${pyenv_name}

## activate the python environment (every time you want to use the environment)
source ${pyenv_name}/bin/activate

## install the required packages (need to be done only once)
pip install -r ${smk_dir}/installation/pyenv_req.txt
```

## Installing Other Dependent Tools

[NovaScope](../index.md) depends on a number of software tools, detailed below. The versions specified for each software tool have been verified for compatibility with our pipeline, though other versions may also be compatible.

* [STARsolo](https://github.com/alexdobin/STAR) (v2.7.11b)
* [samtools](https://www.htslib.org/) (v1.13; v1.14; v1.19)
* [spatula](https://seqscope.github.io/spatula/) (v0.1.0)
* [Python](https://www.python.org/) (v3.9.12, v3.10, or v3.12.2)
* [ImageMagick](https://imagemagick.org/) (7.1.0-25.lua and 7.1.1-30)
* [GDAL](https://gdal.org/) (v3.5.1) (Required for histology alignments)

We provide an [example work log](https://github.com/seqscope/NovaScope/blob/main/installation/requirement_install_log.md) documenting the installation of the aforementioned software tools.

## Installing NovaScope

To install [NovaScope](../index.md), clone the repository from GitHub using the following command:

```bash
git clone https://github.com/seqscope/NovaScope.git
```

## Preparing Reference Genomes

The reference genome for the species of interest must be downloaded and indexed for alignment. [STARsolo](https://github.com/alexdobin/STAR) accepts the reference genomes prepared by [cellranger](https://www.10xgenomics.com/support/software/cell-ranger), therefore, one of the simplest way is to download the reference genome from the [cellranger download](https://www.10xgenomics.com/support/software/cell-ranger/downloads) page.

The recommended reference genome for mouse is GRCm39.

However, the STAR index packaged by the
[cellranger download](https://www.10xgenomics.com/support/software/cell-ranger/downloads)
is outdated and will not be compatible with the latest version of STARsolo. Therefore, we recommend
indexing it using the latest version of STARsolo. 

Note that this process will take A LOT OF TIME, typically a few to several hours.

```bash
## download the reference genome package
curl -O "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCm39-2024-A.tar.gz"

## uncompressed the tar file
tar -xvf refdata-gex-GRCm39-2024-A.tar.gz
cd refdata-gex-GRCm39-2024-A

## uncompress GTF file
gzip -d genes/genes.gtf.gz

## index the reference genome
STARBIN=/path/to/STAR_2.7.11b/Linux_x86_64_static/STAR
${STARBIN} --runMode genomeGenerate \
	--runThreadN 1 \
	--genomeDir ./star_2_7_11b \
	--genomeFastaFiles ./fasta/genome.fa \
	--genomeSAindexNbases 14 \
	--genomeChrBinNbits 18 \
	--genomeSAsparseD 3 \
	--limitGenomeGenerateRAM 17179869184 \
	--sjdbGTFfile ./genes/genes.gtf
```

The recommended reference genome for human is GRCh38.

```bash
## download the reference genome package
curl -O "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2024-A.tar.gz"

## uncompressed the tar file
tar -xvf refdata-gex-GRCh38-2024-A.tar.gz
cd refdata-gex-GRCh38-2024-A

## uncompress GTF file
gzip -d genes/genes.gtf.gz

## index the reference genome
STARBIN=/path/to/STAR_2.7.11b/Linux_x86_64_static/STAR
${STARBIN} --runMode genomeGenerate \
	--runThreadN 1 \
	--genomeDir ./star_2_7_11b \
	--genomeFastaFiles ./fasta/genome.fa \
	--genomeSAindexNbases 14 \
	--genomeChrBinNbits 18 \
	--genomeSAsparseD 3 \
	--limitGenomeGenerateRAM 17179869184 \
	--sjdbGTFfile ./genes/genes.gtf
```

For other species, you may follow the instructions provided by [cellranger](https://www.10xgenomics.com/support/software/cell-ranger/downloads) or [STARsolo](https://github.com/alexdobin/STAR) to prepare the reference genome.

## (Optional) Install the historef Package from the whl File

If you want to align your histology images with the spatial gene expression data, you may install the [historef](https://github.com/seqscope/historef) package from the whl file. Below is an example instruction to download historef's latest version at document creation. To access the most recent version, please see [its GitHub repository](https://github.com/seqscope/historef?tab=readme-ov-file).

```bash
## activate the python environment
source ${pyenv_dir}/$pyenv_name/bin/activate

### download the historef package
wget -P ${smk_dir}/installation https://github.com/seqscope/historef/releases/download/v0.1.2/historef-0.1.2-py3-none-any.whl

## install the historef package
pip install ${smk_dir}/installation/historef-0.1.2-py3-none-any.whl
```

## (Optional) Install FICTURE
NovaScope provides additional features that allow users to convert their output into two different formats. Specifically, it allows the transformation of the spatial digital gene expression matrix (SGE) into a format compatible with [FICTURE](https://seqscope.github.io/ficture/). It also enables pixel organization into user-defined hexagonal grids, creating a hexagon-based SGE in the 10x genomics format. 

To utilize these features, users are advised to follow the [FICTURE](https://seqscope.github.io/ficture/) installation guidelines provided in its [tutorial](https://seqscope.github.io/ficture/install/).
