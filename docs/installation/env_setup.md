# Setup Environment YAML file

Create a `config_env.yaml` file for the environment setup, see our example [here](https://github.com/seqscope/NovaScope/blob/main/config_env.yaml).

Substitute the placeholders with your specific input variables to tailor it to your requirements.

```
## Tools 
## For tools that are not explicitly defined, the pipeline will automatically check if they are installed and include them in the system path for use. 
## This allows the pipeline to utilize these tools without needing manual configuration for each one.
tools:
  spatula: <path_to_the_spatula_bin_file> 		## Default: "spatula"
  samtools: <path_to_the_samtools_bin_file>		## Default: "samtools"
  star: <path_to_the_starsolo_bin_file> 		## Default: "STAR"

## HPC-specific configuration:
## Use this section exclusively for HPC execution mode to load the required software tools as modules.
## This setup is not necessary for local executions; you may skip this section if running the pipeline on your local machine.
envmodules:
  python: "python/3.9.12"
  gcc: "gcc/10.3.0"
  gdal: "gdal/3.5.1"
  imagemagick: "imagemagick/7.1.0-25.lua"

## Reference database for the alignment
## List all reference files you need here:
ref:
  align:
    <specie1>: <path_to_the_reference_genome_index_for_specie1>
	<specie2>: <path_to_the_reference_genome_index_for_specie2>
   #...

## Python environment
pyenv:
  <python_env1>: <path_to_the_python_environment1>
```