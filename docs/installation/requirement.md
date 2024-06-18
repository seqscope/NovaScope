# Installing NovaScope

Installing [NovaScope](../index.md) involves multiple steps. This document provides instructions on how to install the necessary software tools and obtain reference datasets.

## Installing Snakemake 

[Snakemake](https://snakemake.readthedocs.io/en/stable/) orchestrates the workflow of [NovaScope](../index.md) pipeline. 

!!! info
	[NovaScope](../index.md) has been tested for compatibility with [Snakemake](https://snakemake.readthedocs.io/en/stable/) v7.29.0 and v8.6.0.


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

### Installing Snakemake Using Conda and Mamba

If you need to install [Snakemake](https://snakemake.readthedocs.io/en/stable/), below is a simplified sequence of instruction. Please refer to [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) for more detailed instructions.

!!! tip

	It is recommended to install [Snakemake](https://snakemake.readthedocs.io/en/stable/) using [conda](https://docs.conda.io/en/latest/) and/or [mamba](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html). 

!!! info
	If you do not have Python, it will be installed as part of setting up Miniconda.

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
## this step ensures that this version of Python is installed within the environment if it isn't already available
python_version=3.9		# replace 3.9 by your desired version
conda create -n snakemake-env python=$python_version

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
### Python 

!!! info
	[NovaScope](../index.md) has been tested for compatibility with [Python](https://www.python.org/) v3.9.12, v3.10, and v3.12.2.

If you don't have Python installed on your system and you follow the above [Snakemake installation instructions](#installing-snakemake-using-conda-and-mamba), Python of the specified version should be installed during the process. 

If you want to verify the installation or the version of Python on your system, run the following command:

```
python --version
```
### Python Environment

We recommend creating a new Python environment for [NovaScope](../index.md). If you already have an existing Python environment with all required packages (see [pyenv_req.txt](https://github.com/seqscope/NovaScope/blob/main/installation/pyenv_req.txt)), you may skip this step. Below is an example of creating a new Python environment:

```bash
## First, we recommend activating conda/mamba environment before setting up venv, using:
# eval "$(/path/to/miniconda3/bin/conda shell.bash hook)"
# conda activate snakemake-env

## set the path to the python virtual environment directory
pyenv_dir=/path/to/python/virtual/environment/directory  ## provide the path of venv
## pyenv_dir=./venvs   									 ## uncomment this line if you want to create virtual environment locally
pyenv_name=novascope_venv							     ## define the name of python environment 
smk_dir=/path/to/the/novascope/directory				 ## specify the path to novascope repository

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
* [ImageMagick](https://imagemagick.org/) (7.1.0-25.lua and 7.1.1-30)
* [GDAL](https://gdal.org/) (v3.5.1) (Optional, required for histology alignments)

We provide an [example work log](https://github.com/seqscope/NovaScope/blob/main/installation/requirement_install_log.md) documenting the installation of the aforementioned software tools.

## Installing NovaScope

To install [NovaScope](../index.md), clone the repository from GitHub using the following command. Use `--recursive` to initializes and updates each submodule in NovaScope.

```bash
git clone --recursive https://github.com/seqscope/NovaScope.git 
```

If you've already cloned NovaScope without its submodules (by forgetting to use the `--recursive` option), you can initialize and update the submodules afterwards with the following commands:

```bash
cd $smk_dir							## smk_dir=/path/to/the/novascope/directory
git submodule update --init
```

## Preparing Reference Genomes

The reference genome for the species of interest must be downloaded and indexed for alignment. [STARsolo](https://github.com/alexdobin/STAR) accepts the reference genomes prepared by [cellranger](https://www.10xgenomics.com/support/software/cell-ranger), therefore, one of the simplest way is to download the reference genome from the [cellranger download](https://www.10xgenomics.com/support/software/cell-ranger/downloads) page.

Given STAR index packaged by the [cellranger download](https://www.10xgenomics.com/support/software/cell-ranger/downloads) is outdated and will not be compatible with the latest version of STARsolo, we recommend indexing it using the latest version of STARsolo. For human and mouse, we provided examples below to prepare the reference genome. For other species, please follow the instructions provided by [cellranger](https://www.10xgenomics.com/support/software/cell-ranger/downloads) or [STARsolo](https://github.com/alexdobin/STAR) to prepare the reference genome. 

Please note that this indexing process will take A LOT OF TIME, typically a few to several hours.

???+ Mouse
	The recommended reference genome for mouse is GRCm39. 

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

???+ Human
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
