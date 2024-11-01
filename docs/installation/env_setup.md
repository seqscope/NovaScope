# Setting Up a Environment YAML File

[NovaScope](../index.md) requires a YAML file to configure the environment. This file (e.g., `config_env.yaml`) specifies paths to tools, reference databases, and the Python environment.

Below is a brief description of all the items in the YAML file.

!!! tip
    To create your own `config_env.yaml` file for the environment setup, you may copy from [our example](https://github.com/seqscope/NovaScope/blob/main/info/config_env.yaml). 
    
    Please replace the placeholders with your specific input variables.

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

!!! tip
    Ensure that the reference files match the species of your input data.

Define all necessary reference databases for the input species in the `ref` field.

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
  #geneinfo:                                        ## (optional) skip if the users prefer to use precompiled files
    #mouse: "/path/to/ref_gene_info_file_for_mouse"
    #human: "/path/to/ref_gene_info_file_for_human"
    #...
```

### (1) Reference Genome Index for Alignment

Specify the alignment reference genome index in the `align` field. Reference genome indices can be accessed via the [cellranger download](https://www.10xgenomics.com/support/software/cell-ranger/downloads) page. Users may also generate their own genome index, with detailed instructions for building a STAR index provided in the [Requirements](./requirement.md) section.

### (2) (Optional) Reference Gene List Files for Spatial Expression Visualization

!!! tip
    By default, NovaScope requires reference gene list files for visualizing spatial expression patterns. If these files are unavailable, users can disable this feature by setting `action` in `draw_sge` to `False`.

The `genelists` field should specify the directory containing species-specific gene lists, which are essential for visualizing spatial expression in Rule [sdge_visual](../fulldoc/rules/sdge_visual.md). Each file in this directory must be named `<gene_group>.genes.tsv` (e.g., `MT.genes.tsv`) and list gene names line by line.

NovaScope provides precompiled gene lists for [mouse (mm39)](https://github.com/seqscope/NovaScope/tree/main/info/genelists/mm39) and [human (hg38)](https://github.com/seqscope/NovaScope/tree/main/info/genelists/hg38). If not specified, these defaults will be used. Users may also supply custom gene lists or disable the visualization of gene sets.

### (3) (Optional) Reference Gene Information for Gene Filtering 

Gene information files are needed for if additional functionalities are utilized, specified in the `geneinfo` field for filtering. The `geneinfo` field should point to the gene information file used for gene filtering. By default, NovaScope uses precompiled files for: [mouse (mm39)](https://github.com/seqscope/NovaScope/blob/dev/info/geneinfo/Mus_musculus.GRCm39.107.names.tsv.gz), [human (hg38)](https://github.com/seqscope/NovaScope/blob/dev/info/geneinfo/Homo_sapiens.GRCh38.107.names.tsv.gz), and [chick (g6a)](https://github.com/seqscope/NovaScope/blob/dev/info/geneinfo/Gallus_gallus.GRCg6a.106.names.tsv.gz)

Users need to specify a gene information file in the `geneinfo` field only if:

- The dataset is from a species other than human or mouse.
- The dataset version differs from the precompiled files.

## Python Environment

Specify the path of Python virtual environment by modifying the following line:

```yaml
pyenv: "/path/to/python/virtual/env"
```

## (Optional) Computing Capabilities

!!! info
    Only applicable to HPC environments and when the `filesize` resource allocation method is applied.

NovaScope offers two resource allocation methods for alignment:

* **`stdin`**: Manually define resources in the [job configuration file](../basic_usage/job_config.md/#a-template-of-the-config-file).
* **`filesize`**: Automatically allocate resources based on input file size and available computational resources, which must be specified in `available_nodes` when using this option (see an example below):
    ```yaml
    available_nodes:
      - partition: standard     # partition name
        max_n_cpus: 20          # the maximum number of CPUs per node
        mem_per_cpu: 7g         # the memory allocation per CPU 
      - partition: largemem
        max_n_cpus: 10
        mem_per_cpu: 25g
    ```

For details on activating `stdin` or `filesize` and understanding the `filesize` strategy, see the [Job Configuration](../basic_usage/job_config.md/#upstream) page. 
