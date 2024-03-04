## 1. Install snakemake 

## 2. Set up your environment

### 2.1 Install the following softwares.	
	* STAR (v2.7.11)
	* Samtools (v1.14)
	* Python (v3.9)
	* spatula
	* imagemagick()
	* gcc(v10.3.0) 
	* gdal(v3.5.1)
		
### 2.2 Download the reference datasets.
	
	(1) Reference dataset for STARsolo alignment in NovaScope:

	* mouse: mm39
	* human: GRCh38
	* rat: mRatBN7
	* worm: WBcel235

	(2) (Optional) Reference dataset for gene information for downstream analysis:
	 
	* mouse: Mus_musculus.GRCm39.107
	* human: Homo_sapiens.GRCh38.107

	
### 2.3 Set up the environment directory.

Provide the above files in a YAML file, for example `env_setup.yaml`. Then run 

	```	
	# $smk_dir is the location of NovaScope repository
	smk_dir=/nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope

	# $env_dir is the location of the environment for Novascope
	env_dir=/nfs/turbo/sph-hmkang/index/data/weiqiuc/env_test

	python ${smk_dir}/scripts/env_setup.py \
		--yaml_file ${smk_dir}/installation/env_setup.yaml \
		--work_path ${env_dir} 
	``` 
	The env_setup.py will store all above environmental information using soft links.


### 2.4 Create python environment. 

2.4.1 Install python external libraries.

Option 1. Use an existing python environment with the required external libraries (see [py39_req.txt](py39_req.txt)).

	```
	pyenv=$env_dir/pyenv
	mkdir -p $pyenv
	
	# define your existing python environment below
	existing_pyenv=/nfs/turbo/sph-hmkang/index/data/weiqiuc/misc/smk_env_39
	
	ln -s $existing_pyenv $pyenv/py39
	```

Option 2. Install a python environment for Novascope.
		
	* Install external Libraries.

	```
	pyenv=$env_dir/pyenv
	mkdir -p $pyenv

	cd $pyenv

	python -m venv py39
	source py39/bin/activate
	
	pip install -r $smk_dir/installation/py39_req.txt
	```

2.4.2 Install the historef package using the whl file

    ```
	source $pyenv/py39/bin/activate
	pip install $smk_dir/installation/historef-0.1.1-py3-none-any.whl
	```
