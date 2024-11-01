# (Optional) Additional Installations

!!! info
	The installations below are only necessary for who looking to utilize the [additional functionalities](../home/workflow_structure.md#plus-workflow). 
	
	To solely utilize the [main functionalities](../home/workflow_structure.md#main-workflow), skip this step.

## Install the historef Package
!!! info
	Only required if you want to align your histology images with the spatial digital gene expression (SGE) matrix.

Install the [historef](https://github.com/seqscope/historef) package in [your Python environment](./requirement.md#configuring-python-virtual-environment). For the most recent version, please see [its GitHub repository](https://github.com/seqscope/historef?tab=readme-ov-file).

```bash
### activate your python environment
### Both the $pyenv_dir and $pyenv_name were defined in Configuring Python Virtual Environment.
source ${pyenv_dir}/$pyenv_name/bin/activate

### download the historef package
wget -P ${smk_dir}/installation https://github.com/seqscope/historef/releases/download/v0.1.3/historef-0.1.3-py3-none-any.whl

## install the historef package
pip install ${smk_dir}/installation/historef-0.1.3-py3-none-any.whl
```

## Install the FICTURE Package
!!! info 
	Only required if you want to apply the SGE matrix filtering, reformatting or segmentation functionalities.

NovaScope has already included [FICTURE](https://github.com/seqscope/ficture) as a submodule, but it is essential to install [FICTURE](https://github.com/seqscope/ficture) and its dependencies into [your Python virtual environment](./requirement.md#configuring-python-virtual-environment). For more details, please consult [FICTURE's instructions](https://seqscope.github.io/ficture/install/).

```bash
## set the path to the python virtual environment directory
pyenv_dir=/path/to/python/virtual/environment/directory  ## provide the path of venv
pyenv_name=novascope_venv							     ## provide the name of the environment you created before

smk_dir=/path/to/the/novascope/directory

## activate the python environment (every time you want to use the environment)
source ${pyenv_dir}/${pyenv_name}/bin/activate

## install the required packages (need to be done only once)
pip install -r ${smk_dir}/submodules/ficture/requirements.txt

## install FICTURE
pip install ficture
```