# 1. Software Installation

## 1.1 NovaScope.

```
git clone git@github.com:seqscope/NovaScope.git
```

## 1.2 Snakemake 

Snakemake orchestrates the workflow of this pipeline. We recommend installing Snakemake using Conda or Mamba. For detailed installation instructions, please refer to the [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

The NovaScope is created and tested using Snakemake v7.29.0 and v8.6.0.

## 1.3 Other Dependent Software Tools

The dependent software tools are listed below. The versions specified for each software tool have been verified for compatibility with our pipeline, though other versions may also be compatible.

	* STAR (v2.7.11a)
	* Samtools (v1.14 and v1.19)
	* spatula 
	* Python (v3.9.12, v3.10, and v3.12.2)
	* imagemagick (7.1.0-25.lua and 7.1.1-30)
	* gcc (v10.3.0) 
	* gdal (v3.5.1)

We provide an [example work log](https://github.com/seqscope/NovaScope/blob/main/installation/requirement_install_log.md) documenting the installation of the aforementioned software tools.

# 2. Reference Datasets
	
Please download the necessary reference datasets for STARsolo alignment. The versions listed below are those we utilized in our setup.

	* mouse: mm39
	* human: GRCh38
	* rat: mRatBN7
	* worm: WBcel235

# 3. Configure Python Environment

If you already have an existing Python environment with all required packages (see [pyenv_req.txt](https://github.com/seqscope/NovaScope/blob/main/installation/pyenv_req.txt)), skip 3.1.

## 3.1 Create a New Python Environment

```
pyenv_dir=<directory_of_python_environment>
pyenv_name=<name_of_python_environment>
smk_dir=<path_to_NovaScope_repository>

mkdir -p $pyenv_dir
cd $pyenv_dir

python -m venv $pyenv_name
source $pyenv_name/bin/activate
pip install -r $smk_dir/installation/pyenv_req.txt
```

## 3.2 Install the historef Package Using the whl File

Below are codes to download historef's latest version at document creation. To access the most recent version, please see [its GitHub repository](https://github.com/seqscope/historef?tab=readme-ov-file).

```
source $pyenv_dir/$pyenv_name/bin/activate
wget -P $smk_dir/installation https://github.com/seqscope/historef/releases/download/v0.1.1/historef-0.1.1-py3-none-any.whl
pip install $smk_dir/installation/historef-0.1.1-py3-none-any.whl
```

