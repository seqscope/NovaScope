# Setting up a Environment YAML File

[NovaScope](../index.md) requires a YAML file to configure the environment. This file is used to specify the paths to the required tools, reference databases, and Python environment. To create your own `config_env.yaml` file for the environment setup, you may copy from [our example available in our GitHub repository](https://github.com/seqscope/NovaScope/blob/main/info/config_env.yaml).

Below is a brief description of all the items in the YAML file. Replace the placeholders with your specific input variables to customize it according to your needs, and prepare your own `config_env.yaml`.

## Tools 

For tools that are not explicitly defined, the pipeline will automatically check if they are installed and include them in the system path for use. This allows the pipeline to utilize these tools without needing manual configuration for each one.
```
tools:
  spatula: /path/to/spatula/bin/spatula                     ## Default: "spatula"
  samtools: /path/to/samtools/samtools	                    ## Default: "samtools"
  star: /path/to/STAR_2_7_11b/bin/Linux_x86_64_static/STAR  ## Default: "STAR"
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
  #snakemake: "snakemake/<version_information>"
```

* `python`: If your Python environment was set up using a Python version accessed through a module, your environment depends on certain shared files from that module. Therefore, you must add the `python: "python/<version_information>"`  in the `envmodules` section to load the same module you initially used to establish your environment. But if you set up with a locally installed Python (not using `module load`), comment out or remove the module line `python: "python/<version_information>"`.
* It is also feasible to use `envmodules` to load other tools, such as `samtools` instead of defining its path in `tools`.

## Reference Database

Please list every reference database used for alignment here. For instructions on preparing reference data, please consult the section on [Installing NovaScope](./requirement.md/#preparing-reference-genomes). 

It is imperative to ensure the reference database matches to the species of your input data. 

```
ref:
  align:
    mouse: "/path/to/refdata-gex-GRCm39-2024-A/star"
    human: "/path/to/refdata-gex-GRCh39-2024-A/star"
   #...
```

## Python Environment

You also need to specify the path of python virtual environment by modifying the following line.

```
pyenv: "/path/to/python/virtual/env"
```

