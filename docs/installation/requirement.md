# Installation Guide

## 1. Software Installation

### 1.1 NovaScope.

```
git clone git@github.com:seqscope/NovaScope.git
```

### 1.2 Snakemake 

Snakemake orchestrates the workflow of this pipeline. We recommend installing Snakemake using Conda or Mamba. For detailed installation instructions, please refer to the [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

The NovaScope is created and tested using Snakemake v7.29.0.

### 1.3 Other required Software 

The required software tools are listed below. The versions specified for each software tool have been verified for compatibility with our pipeline, though other versions may also be compatible.

	* STAR (v2.7.11)
	* Samtools (v1.14)
	* spatula
	* Python (v3.9.12)
	* imagemagick (7.1.0-25.lua)
	* gcc (v10.3.0) 
	* gdal (v3.5.1)
		
## 2. Reference datasets
	
Please download the necessary reference datasets for STARsolo alignment. The versions listed below are those we utilized in our setup.

	* mouse: mm39
	* human: GRCh38
	* rat: mRatBN7
	* worm: WBcel235


### 3. Configure Python Environment

If you already have an existing python environment with all required packages (see `./installation/py39_req.txt`), skip 3.1.

#### 3.1 Create a New Environment**
		
```
pyenv=$env_dir/pyenv
mkdir -p $pyenv
cd $pyenv

python -m venv py39
source py39/bin/activate
pip install -r $smk_dir/installation/py39_req.txt
```

#### 3.2 Install the historef package using the whl file

Below are codes to download historef's latest version at document creation. To access the most recent version, please see [its GitHub repository](https://github.com/seqscope/historef?tab=readme-ov-file).

```
source $pyenv/py39/bin/activate
wget -P $smk_dir/installation https://github.com/seqscope/historef/releases/download/v0.1.1/historef-0.1.1-py3-none-any.whl
pip install $smk_dir/installation/historef-0.1.1-py3-none-any.whl
```

### 4. Setup Environment Directory

Create a `env_setup.yaml` file for the environment setup, see our example at `${smk_dir}/installation/env_setup.yaml`. 


Use the following commands to configure your environment:

```	
## Define paths
smk_dir=<path_to_NovaScope_repository>
env_dir=<path_to_environment_directory>
env_yml=<path_to_environment_setup_yaml_file>

## Run setup script
python ${smk_dir}/scripts/env_setup.py \
	--yaml_file ${env_yml} \
	--work_path ${env_dir}

## If you are using an existing python environment, link it to this $env_dir.
# pyenv=$env_dir/pyenv
# mkdir -p $pyenv
# existing_pyenv=<path_to_existing_environment>
# ln -s $existing_pyenv $pyenv/py39
```

