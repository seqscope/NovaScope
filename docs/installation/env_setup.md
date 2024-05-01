# Setting up a Environment YAML File

[NovaScope](../index.md) requires a YAML file to configure the environment. This environment configuration file (`config_env.yaml`) is used to specify the paths to the required tools, reference databases, and Python environment. 

Below is a brief description of all the items in the YAML file. 

!!! tip
    To create your own `config_env.yaml` file for the environment setup, you may copy from [our example available in our GitHub repository](https://github.com/seqscope/NovaScope/blob/main/info/config_env.yaml). Remember to replace the placeholders with your specific input variables to customize it according to your needs.

## Tools 

The pipeline automatically detects and includes undefined tools in the system path, allowing for their use without manual configuration.

```yaml
tools:
  spatula: /path/to/spatula/bin/spatula                     ## Default: "spatula"
  samtools: /path/to/samtools/samtools	                    ## Default: "samtools"
  star: /path/to/STAR_2_7_11b/bin/Linux_x86_64_static/STAR  ## Default: "STAR"
  ficture: /path/to/ficture/repository                      ## (Optional) Default: "ficture"	 
```
??? note "`samtools`"
    For users in High-Performance Computing (HPC) environments with `samtools` installed, it's feasible to use `envmodules` (see [Environment Modules](#environment-modules)) to load `samtools` rather than defining its path here.


## (Optional) Environment Modules
  
!!! info
    Only applicable to HPC environments. For local executions, remove this section from `config_env.yaml`.

For HPC users, it is feasible to use the `envmodules` section to load the required software tools as modules. If a tool is not listed in the `envmodules` section, the pipeline will assume it's installed system-wide. 

!!! tip
    The **version** information is required.

```yaml
envmodules:
  python: "python/<version_information>"
  gcc: "gcc/<version_information>"
  gdal: "gdal/<version_information>"
  imagemagick: "imagemagick/<version_information>"
  # snakemake: "snakemake/<version_information>"
  # samtools: "Bioinformatics && samtools"
```

??? note "`python`"
    If your Python environment was set up using a Python accessed through a module, specify the same Python module in the envmodules section to maintain the environment. If using a local Python installation (not through `module load`), DO NOT INCLUDE any Python module here.

??? note "`samtools`"
    Using `envmodules` to load `samtools` can be an alternative to specifying its path in [`tools`](#tools). The given example is designed for instances where `samtools` is integrated into the `Bioinformatics` module system, which necessitates loading the `Bioinformatics` module prior to loading `samtools`. In this case, provide all modules that required to be loaded in the correct order, joint by `&&`.

## Reference

Please list every reference database used for alignment and the reference gene list files for visualization here. 

The reference genome index for alignment can be obtained via the [cellranger download](https://www.10xgenomics.com/support/software/cell-ranger/downloads) page. Example instructions to build STAR index from the reference file is described in the [Requirements](./requirement.md) section.

Currently NovaScope provides reference gene list files for mouse (version: mm39) and human (version: hg38) in ["info"](https://github.com/seqscope/NovaScope/tree/info/genelists) folder. When `genelists` is absent in the `config_env.yaml`, NovaScope will leverage the default files from the [info](https://github.com/seqscope/NovaScope/tree/info/genelists) folder.

!!! tip
    Please ensure the reference files correspond to the species of your input data. 

```yaml
ref:
  align:
    mouse: "/path/to/refdata-gex-GRCm39-2024-A/star_2.7_11b"
    human: "/path/to/refdata-gex-GRCh39-2024-A/star_2.7_11b"
   #...
  genelists:
    mouse: "/path/to/ref_gene_list_for_mouse"
    human: "/path/to/ref_gene_list_for_human"

```

## Python Environment

You also need to specify the path of Python virtual environment by modifying the following line.

```yaml
pyenv: "/path/to/python/virtual/env"
```

## (Optional) Computing Capabilities

!!! info

    Only applicable to HPC environments.

NovaScope provides two methods for specifying resources for the alignment process:

* **Option `stdin`** allows users to define resources manually in the [job configuration file](../getting_started/job_config.md/#a-template-of-the-config-file).
* **Option `filesize`** allows NovaScope to automatically allocate resources based on the size of the input files and the available computational resources defined in this environment configuration file. **ONLY** when using Option `filesize` must users specify the computing resources available. 

For more information on activating Option `stdin` or `filesize` and the resource allocation strategy for Option `filesize`, visit the [Job Configuration](../getting_started/job_config.md/#upstream) page.

An example of how to configure these settings.

```yaml
available_nodes:
  - partition: standard     # partition name
    max_n_cpus: 20          # the maximum number of CPUs per node
    mem_per_cpu: 7g         # the memory allocation per CPU 
  - partition: largemem
    max_n_cpus: 10
    mem_per_cpu: 25g
```
