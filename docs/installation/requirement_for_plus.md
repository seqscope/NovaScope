# Additional Installations

!!! info
	The installations listed below are **OPTIONAL** and are **ONLY** necessary for users who looking to utilize the [additional functionalities](../index.md#functionality). 
	
	If you are solely processing raw sequencing data into a spatial gene expression matrix, you may skip this step.


## (Optional) Install the historef Package
!!! info 
	Only required if you want to align your histology images with the spatial gene expression data. 

Below is an example instruction to install the [historef](https://github.com/seqscope/historef) package in the same python environment you built in [Configuring Python Virtual Environment](#configuring-python-virtual-environment).

To access the most recent version, please see [its GitHub repository](https://github.com/seqscope/historef?tab=readme-ov-file).

```bash
### activate your python environment
### Both the $pyenv_dir and $pyenv_name were defined in Configuring Python Virtual Environment.
source ${pyenv_dir}/$pyenv_name/bin/activate

### download the historef package
wget -P ${smk_dir}/installation https://github.com/seqscope/historef/releases/download/v0.1.2/historef-0.1.2-py3-none-any.whl

## install the historef package
pip install ${smk_dir}/installation/historef-0.1.2-py3-none-any.whl
```

## (Optional) Install the FICTURE Package
!!! info 
	Only required if you want to apply the NovaScope additional reformat features.

NovaScope additional reformat features including the transformation of the spatial digital gene expression matrix (SGE) into a format compatible with [FICTURE](https://seqscope.github.io/ficture/), and the pixel organization into user-defined hexagonal grids in the 10x genomics format. To utilize these reformatting features, you must install the [**stable** branch of FICTURE](https://github.com/seqscope/ficture/tree/stable), which NovaScope has already included as a submodule. However, it is essential to install the dependencies of FICTURE into the Python virtual environment you previously created [here](#python-environment).

Clone the stable branch of FICTURE:
```bash
git clone -b stable https://github.com/seqscope/ficture
```

```bash
## set the path to the python virtual environment directory
pyenv_dir=/path/to/python/virtual/environment/directory  ## provide the path of venv
pyenv_name=novascope_venv							     ## provide the name of the environment you created before

smk_dir=/path/to/the/novascope/directory

## activate the python environment (every time you want to use the environment)
source ${pyenv_dir}/${pyenv_name}/bin/activate

## install the required packages (need to be done only once)
pip install -r ${smk_dir}/submodules/ficture/requirements.txt
```