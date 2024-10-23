# Setting Up a Environment YAML File

[NovaScope](../index.md) requires a YAML file to configure the environment. This file (e.g., `config_env.yaml`) specifies paths to tools, reference databases, and the Python environment.

Below is a brief description of all the items in the YAML file.

!!! tip
    To create your own `config_env.yaml` file for the environment setup, you may copy from [our example available in our GitHub repository](https://github.com/seqscope/NovaScope/blob/main/info/config_env.yaml). Remember to replace the placeholders with your specific input variables to customize it according to your needs.

## Tools

The pipeline detects and includes undefined tools in the system path automatically.

```yaml
tools:
  spatula: /path/to/spatula/bin/spatula                     ## Default: "spatula"
  samtools: /path/to/samtools/samtools	                    ## Default: "samtools"
  star: /path/to/STAR_2_7_11b/bin/Linux_x86_64_static/STAR  ## Default: "STAR"
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
    If your Python environment was set up using a Python accessed through a module, specify the same Python module in the `envmodules` section to maintain the environment. If using a local Python installation (not through `module load`), DO NOT INCLUDE any Python module here.

??? note "`samtools`"
    Using `envmodules` to load `samtools` can be an alternative to specifying its path in [`tools`](#tools).

    The given example is designed for instances where `samtools` is integrated into the `Bioinformatics` module system, which necessitates loading the `Bioinformatics` module prior to loading `samtools`. In this case, provide all modules that required to be loaded in the correct order, joint by `&&`.

## Reference Databases

Define all necessary reference databases for the input species in the `ref` field.

### (1) Reference Genome Index for Alignment
Specify the alignment reference genome index in the `align` field. Reference genome indices can be accessed via the [cellranger download](https://www.10xgenomics.com/support/software/cell-ranger/downloads) page. Users can also generate their own reference genome index. Detailed instructions for building the STAR index are provided in the [Requirements](./requirement.md) section.

### (2) (Optional) Reference Gene List Files for Spatial Expression Visualization

!!! info
    By default, NovaScope requires reference gene list files to visualize the spatial expression for gene sets. If the reference files are not available, users could skip the visualization by set `action` in `draw_sge` as `False`.

The `genelists` field should point to the directory containing species-specific gene lists, which are crucial for visualizing spatial expression patterns in Rule [sdge_visual](../fulldoc/rules/sdge_visual.md). This directory must include files named `<gene_group>.genes.tsv` (e.g., `MT.genes.tsv`), with each file listing gene names line-by-line.

NovaScope provides precompiled gene lists for [mouse (version: mm39)](https://github.com/seqscope/NovaScope/tree/main/info/genelists/mm39) and [human (version: hg38)](https://github.com/seqscope/NovaScope/tree/main/info/genelists/hg38). If the `genelists` field is not specified in the `config_env.yaml`, NovaScope defaults to using these files. Alternatively, users may provide their own custom gene list files.

### (3) (Optional) Reference Gene Information for Gene Filtering 

!!! info
    Gene information files are necessary only if additional functionalities of NovaScope are utilized.

The `geneinfo` field specifies the path of gene information files needed for gene filtering. 

By Default, NovaScope use the precompiled gene information files, including one for [mouse (version: mm39)](https://github.com/seqscope/NovaScope/blob/dev/info/geneinfo/Mus_musculus.GRCm39.107.names.tsv.gz), one for [human (version: hg38)](https://github.com/seqscope/NovaScope/blob/dev/info/geneinfo/Homo_sapiens.GRCh38.107.names.tsv.gz), and one for [chick (version: g6a)](https://github.com/seqscope/NovaScope/blob/dev/info/geneinfo/Gallus_gallus.GRCg6a.106.names.tsv.gz). I

Only under the following conditions, users need to prepare and specify a gene information file in the `geneinfo` field: a. the input datasets are from species other than human or mouse; b. the version of the dataset is different from that of the precompiled files (human: hg38; mouse: mm39, chick: g6a).

!!! tip
    Ensure that the reference files match the species of your input data.

```yaml
ref:
  align:
    mouse: "/path/to/refdata-gex-GRCm39-2024-A/star_2.7_11b"
    human: "/path/to/refdata-gex-GRCh39-2024-A/star_2.7_11b"
    #...
  genelists:
    mouse: "/path/to/ref_gene_list_directory_for_mouse"
    human: "/path/to/ref_gene_list_directory_for_human"
    #...
  #geneinfo:                                        ## (optional) no need to define the geneinfo if the users prefer to use the precompiled files from FICTURE
    #mouse: "/path/to/ref_gene_info_file_for_mouse"
    #human: "/path/to/ref_gene_info_file_for_human"
    #...
```

## Python Environment

Specify the path of Python virtual environment by modifying the following line:

```yaml
pyenv: "/path/to/python/virtual/env"
```

## (Optional) Computing Capabilities

!!! info
    Only applicable to HPC environments.

NovaScope provides two methods for specifying resources for the alignment process:

* **Option `stdin`** allows users to define resources manually in the [job configuration file](../basic_usage/job_config.md/#a-template-of-the-config-file).
* **Option `filesize`** allows NovaScope to automatically allocate resources based on the size of the input files and the available computational resources defined in this environment configuration file. **ONLY** when using Option `filesize` must users specify the computing resources available. 

For more information on activating Option `stdin` or `filesize` and the resource allocation strategy for Option `filesize`, visit the [Job Configuration](../basic_usage/job_config.md/#upstream) page.

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
