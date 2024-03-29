# Setting up a Environment YAML File

[NovaScope](../index.md) requires a YAML file to configure the environment. This file is used to specify the paths to the required tools, reference databases, and Python environment. To create your own `config_env.yaml` file for the environment setup, you may copy from [our example available in our GitHub repository](https://github.com/seqscope/NovaScope/blob/main/info/config_env.yaml).

Below is a brief description of all the items in the YAML file. Replace the placeholders with your specific input variables to customize it according to your needs, and prepare your own `config_env.yaml`.

## Tools 

For tools that are not explicitly defined, the pipeline will automatically check if they are installed and include them in the system path for use. This allows the pipeline to utilize these tools without needing manual configuration for each one.

```yaml
tools:
  spatula: /path/to/spatula/bin/spatula                     ## Default: "spatula"
  samtools: /path/to/samtools/samtools	                    ## Default: "samtools"
  star: /path/to/STAR_2_7_11b/bin/Linux_x86_64_static/STAR  ## Default: "STAR"
```

* `samtools`: For users in High-Performance Computing (HPC) environments with `samtools` installed, it's feasible to use `envmodules` (see [Environment Modules](#environment-modules)) to load `samtools` rather than defining its path here.


## Environment Modules

For HPC users, use the `envmodules` section to load the required software tools as modules. If a tool is not listed in the `envmodules` section, the pipeline will assume it's installed system-wide. For local executions, you may remove this section if running the pipeline on your local machine.

Please specify the **version** information. 

```yaml
envmodules:
  python: "python/<version_information>"
  gcc: "gcc/<version_information>"
  gdal: "gdal/<version_information>"
  imagemagick: "imagemagick/<version_information>"
  # snakemake: "snakemake/<version_information>"
  # samtools: "Bioinformatics && samtools"
```

* `python`: If your Python environment was set up using a Python version accessed through a module, your environment depends on certain shared files from that module. Therefore, you must add the `python: "python/<version_information>"`  in the `envmodules` section to load the same module you initially used to establish your environment. But if you set up with a locally installed Python (not using `module load`), comment out or remove the module line `python: "python/<version_information>"`.
* `samtools`: Using `envmodules` to load `samtools` can be an alternative to specifying its path in [`tools`](#tools). The given example is designed for instances where `samtools` is integrated into the `Bioinformatics` module system, which necessitates loading the `Bioinformatics` module prior to loading `samtools`. In this case, provide all modules that required to be loaded in the correct order, joint by `&&`.

## Reference Genome Index

Please list every reference database used for alignment here. The reference data can be obtained via the [cellranger download](https://www.10xgenomics.com/support/software/cell-ranger/downloads) page. Example instructions to build STAR index from the reference file is described in the [Requirements](requirements.md) section.

Please ensure the reference genome indices correspond to the species of your input data. 

```yaml
ref:
  align:
    mouse: "/path/to/refdata-gex-GRCm39-2024-A/star_2.7_11b"
    human: "/path/to/refdata-gex-GRCh39-2024-A/star_2.7_11b"
   #...
```

## Python Environment

You also need to specify the path of python virtual environment by modifying the following line.

```yaml
pyenv: "/path/to/python/virtual/env"
```

