# Setup A Environment YAML File

Create a `config_env.yaml` file for the environment setup, see our example [here](https://github.com/seqscope/NovaScope/blob/main/info/config_env.yaml).

Below is a brief description of all the items in the YAML file. Replace the placeholders with your specific input variables to customize it according to your needs, and provide it via your `config_job.yaml`.

## Tools 
For tools that are not explicitly defined, the pipeline will automatically check if they are installed and include them in the system path for use. This allows the pipeline to utilize these tools without needing manual configuration for each one.
```
tools:
  spatula: <path_to_the_spatula_bin_file> 		## Default: "spatula"
  samtools: <path_to_the_samtools_bin_file>		## Default: "samtools"
  star: <path_to_the_starsolo_bin_file> 		  ## Default: "STAR"
```

## HPC-specific Configuration:

For HPC users, use the `envmodules` section to load the required software tools as modules. If a tool is not listed in the envmodules section, the pipeline will assume it's installed system-wide. For local executions, you may remove this section if running the pipeline on your local machine.

Please specify the **version** information. 

```
envmodules:
  python: "python/<version_information>"
  gcc: "gcc/<version_information>"
  gdal: "gdal/<version_information>"
  imagemagick: "imagemagick/<version_information>"
  #Bioinformatics: "Bioinformatics"
  #samtools: "samtools/1.13-fwwss5n"
```
* `python`: If your python environment was set up using a Python version accessed through a module, your environment depends on certain shared files from that module. Therefore, you must add the `python: "python/<version_information>"`  in the `envmodules` section to load the same module you initially used to establish your environment. But if you set up with a locally installed Python (not using `module load`), comment out or remove the module line `python: "python/<version_information>"`.
* `Bioinformatics` and `samtools`: It is also feasible to use `envmodules` to load samtools instead of defining its path in `tools`.

## Reference Database

Please list every reference database used for alignment here. The reference data are provided via . *TODO: add the download link*

Please Ensure the reference database corresponds to the species of your input data. 

```
ref:
  align:
    <specie1>: <path_to_the_reference_genome_index_for_specie1>
    <specie2>: <path_to_the_reference_genome_index_for_specie2>
   #...
```

## Python Environment

```
pyenv: <path_to_the_python_environment1>
```

