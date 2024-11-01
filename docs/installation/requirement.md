# Installing NovaScope

This document provides instructions on how to install the necessary software tools and how to obtain reference datasets.

## Installing Snakemake

[Snakemake](https://snakemake.readthedocs.io/en/stable/) orchestrates the workflow of [NovaScope](../index.md) pipeline.

!!! info
	[NovaScope](../index.md) has been tested for compatibility with [Snakemake](https://snakemake.readthedocs.io/en/stable/) v7.29.0 and v8.6.0.


### Checking Snakemake Installation

If you are unsure if [Snakemake](https://snakemake.readthedocs.io/en/stable/) is installed, run:

```sh
snakemake --version
```

On systems that support the `module` command, you can load the `snakemake` module using:

```sh
## check if snakemake is available as a module
module avail snakemake

## load the available module (specify the version if necessary)
module load snakemake
``` 

### Installing Snakemake Using Conda and Mamba

To install [Snakemake](https://snakemake.readthedocs.io/en/stable/), follow the simplified steps below. For more details, refer to the [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/basic_usage/installation.html).

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

If you don't have Python installed and you follow the above [Snakemake installation instructions](#installing-snakemake-using-conda-and-mamba), Python of the specified version should be installed during the process.

To verify the installation or the version, run:

```bash
python --version
```

### Python Environment

We recommend creating a new Python environment for [NovaScope](../index.md) with [all required packages](https://github.com/seqscope/NovaScope/blob/main/installation/pyenv_req.txt). Below is an example:

```bash
## First, we recommend activating conda/mamba environment before setting up venv, using:
# eval "$(/path/to/miniconda3/bin/conda shell.bash hook)"
# conda activate snakemake-env

## set the path to the python virtual environment directory
pyenv_dir=/path/to/python/virtual/environment/directory  ## provide the path of venv
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
* [GDAL](https://gdal.org/) (v3.5.1): Optional. Only required for histology alignment.

We provide an [example work log](https://github.com/seqscope/NovaScope/blob/main/installation/requirement_install_log.md) documenting the installation of the aforementioned software tools.

## Installing NovaScope

To install [NovaScope](../index.md), clone the repository from GitHub with the following command, use `--recursive` to initialize and update all submodules.

```bash
git clone --recursive https://github.com/seqscope/NovaScope.git 
```

If you've already cloned NovaScope without its submodules (by forgetting to use the `--recursive` option), initialize and update submodules by running:

```bash
smk_dir=/path/to/the/novascope/directory
cd $smk_dir
git submodule update --init
```

## Preparing Reference Genomes

To align sequences, download and index the reference genome for your species. [STARsolo](https://github.com/alexdobin/STAR) accepts reference genomes prepared by [cellranger](https://www.10xgenomics.com/support/software/cell-ranger). One of the easiest ways is to download the genome from the [cellranger download page](https://www.10xgenomics.com/support/software/cell-ranger/downloads).

However, the STAR index from cellranger may be outdated and incompatible with the latest STARsolo version. We recommend indexing it using the latest STARsolo. For human and mouse, see the examples below. For other species, follow the instructions from [cellranger](https://www.10xgenomics.com/support/software/cell-ranger/downloads) or [STARsolo](https://github.com/alexdobin/STAR).

Note: This indexing process takes several hours.

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
