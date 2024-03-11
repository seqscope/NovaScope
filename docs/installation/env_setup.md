# Setup Environment Directory

Create a `env_setup.yaml` file for the environment setup, see our example at `${smk_dir}/installation/env_setup.yaml`. 


Use the following commands to configure your environment. The `env_setup.py` will help organize all softwares and reference datasets you provided. 

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


