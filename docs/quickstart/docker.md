Running [NovaScope](../index.md) with pre-built docker image requires a system you can run [docker](https://www.docker.com/) on. Typically you need a machine (e.g. Ubuntu Desktop or AWS EC2) you have a root access to, with >32GB memory and >64GB disk space.

It involves three main steps: (1) setting up docker in your system, (2) downloading example data and reference files, and (3) running the pipeline. We will assume that you have `/path/to/working/dir` as your working directory. We will use the minimal test run data as an example, but you may replace it with other datasets.

## Setting up docker in your system

If you are new to [Docker](https://www.docker.com/), please refer to the [Docker documentation](https://docs.docker.com/get-started/) for installation and basic usage. To ensure that Docker is installed in your system, you can run the following command:

```bash
## check the existence and version of docker
docker --version

## check if a docker container can be run
docker run hello-world
```

If the above commands do not run, you need to [install Docker](https://docs.docker.com/get-docker/) in your system. Currently, our docker image is built for Intel/AMD x86_64 architecture. 

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

## Running the NovaScope pipeline with example dataset

You may perform a dry-run to test whether the NovaScope pipeline with the minimal test example data is working properly. 

```bash
## Test the NovaScope pipeline with dry-run
## NOTE: make your to replace /path/to/working/dir/ with your working directory
docker run -it --rm -v /path/to/working/dir:/data hyunminkang/novascope \
    bash -c "snakemake -s /app/novascope/NovaScope.smk --rerun-incomplete -d data/output --configfile /app/novascope/testrun/minimal_test_run/config_job_docker.yaml --dry-run -p"
```

If the dry-run is successful, you may run the pipeline with the following command:

```bash
## Execute the NovaScope pipeline 
## NOTE: make your to replace /path/to/working/dir/ with your working directory
## --cores 10 can be replaced with the number of cores you want to use
docker run -it --rm -v /path/to/working/dir:/data hyunminkang/novascope \
    bash -c "snakemake -s /app/novascope/NovaScope.smk --rerun-incomplete -d data/output --configfile /app/novascope/testrun/minimal_test_run/config_job_docker.yaml -p --cores 10"
```

The pipeline will generate the output files in the `/path/to/working/dir/output` directory, typically in 10 minutes.

To run NovaScope with different datasets, you will need to modify the [Configuration File](https://github.com/seqscope/NovaScope/blob/main/testrun/minimal_test_run/config_job_docker.yaml) yourself and specify it as `--configfile` argument in the command. See detailed instructions in the [Job Configuration](../getting_started/job_config.md) section.
