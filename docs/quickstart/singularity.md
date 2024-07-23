Running [NovaScope](../index.md) with pre-built docker image through singularity requires a system that has [Singularity](https://sylabs.io/docs/) installed. Unlike [Docker](https://www.docker.com/), running singularity does not necessarily require a root permission and can be often found in HPC environment. We still recommend a system that has >32GB memory and >64GB disk space.

Running [NovaScope](../index.md) using singularity involves three main steps: (1) setting up singularity in your system, (2) downloading example data and reference files, and (3) running the pipeline. We will assume that you have `/path/to/working/dir` as your working directory. We will use the minimal test run data as an example, but you may replace it with other datasets.

## Setting up singularity in your system

If you are new to [Singularity](https://sylabs.io/docs/), please refer to the [Singularity documentation](https://docs.sylabs.io/guides/4.1/user-guide/quick_start.html) for installation and basic usage. To ensure that singularity is installed in your system, you can run the following command:

```bash
## check the existence and version of singularity
singularity --version
```

In some systems, you may need to load the singularity module before running the above command.
For example, in the HPC environment, you may need to run the following command:

```bash
## load the singularity module
module load singularity
```

If the above commands do not run, you need to [install singularity](https://docs.sylabs.io/guides/4.1/admin-guide/installation.html) in your system. Currently, our images are built for Intel/AMD x86_64 architecture. 

## Download example data and reference files

You may download the minimal test run data and STAR mouse reference index by running the following commands:

```bash
## change the directory to your working directory
## NOTE: make your to replace /path/to/working/dir/ with your working directory
cd /path/to/working/dir/

## download the minimal test run data (takes 1-5 mins) 
wget https://zenodo.org/records/10835761/files/B08Csub_20240318_raw.tar.gz
tar xzvf B08Csub_20240318_raw.tar.gz

## download the STAR mouse reference index (take 10-20 mins)
wget https://zenodo.org/records/11181586/files/GRCm39_star_2_7_11b.tar.gz
tar xzvf GRCm39_star_2_7_11b.tar.gz
```

## Pulling the docker image and converting it to singularity image

You will need to pull the docker image and convert it to a singularity image. You can do this by running the following command:

```bash
singularity pull docker://hyunminkang/novascope
```

If successful, this will create a file named `novascope_latest.sif` in your working directory.

## Running the NovaScope pipeline

You may perform a dry-run to test whether the NovaScope pipeline with the minimal test example data is working properly. 

```bash
## Test the NovaScope pipeline with dry-run
## NOTE: make your to replace /path/to/working/dir/ with your working directory
singularity exec --bind /path/to/working/dir:/data novascope_latest.sif \
    snakemake -s /app/novascope/NovaScope.smk \
    --rerun-incomplete -d data/output \
    --configfile /app/novascope/testrun/minimal_test_run/config_job_docker.yaml \
    --dry-run -p
```

If the dry-run is successful, you may run the pipeline with the following command:

```bash
## Execute the NovaScope pipeline 
## NOTE: make your to replace /path/to/working/dir/ with your working directory
## --cores 10 can be replaced with the number of cores you want to use
singularity exec --bind /path/to/working/dir:/data novascope_latest.sif \
    snakemake -s /app/novascope/NovaScope.smk \
    --rerun-incomplete -d data/output \
    --configfile /app/novascope/testrun/minimal_test_run/config_job_docker.yaml \
    -p --cores 10
```

The pipeline will generate the output files in the `/path/to/working/dir/output` directory, typically in 10 minutes.

To run NovaScope with different datasets, you will need to modify the [Configuration File](https://github.com/seqscope/NovaScope/blob/main/testrun/minimal_test_run/config_job_docker.yaml) yourself and specify it as `--configfile` argument in the command. See detailed instructions in the [Job Configuration](../basic_usage/job_config.md) section.