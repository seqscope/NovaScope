If you want to prepare your own dataset to run the pipeline with [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/docs/), the process is similar to the examples provided, except that you will need to modify the `--configfile` parameter to your own version. 

## Preparing the job config file

Typically, you may want to locate your config file in your working directory and specify it in the command. For example, if your config file is located at `${working_dir}/config_job.yaml`, assuming that the working directory is mounted to `/data` in the container as given in the example, you can run the pipeline with `--configfile /data/config_job.yaml` argument.

The full instruction on how to prepare your job config file is provided in the [Job Configuration](../getting_started/job_config.md) section. If you are using NovaScope using [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/docs/) container, here are some tips to modify your job config file:

* It would be easiest to start with the [Shallow Liver Section Configuration File](testrun/shallow_liver_section/config_job.yaml).
* We recommend placing the input FASTQ files in the `${working_dir}/input` directory and the output files in the `${working_dir}/output` directory, and mount the `${working_dir}` to `/data` in the container.
* Modify `env_yml` to the config file that already exists in the container: `/app/novascope/info/config_env_docker.yaml`, so that you do not have to set up your own environment file.
* Please see [Job Configuration](../getting_started/job_config.md) section to understand how to update the rest of the input parameters.

## Running the Docker/Singularity container

You may perform a dry-run to test whether the NovaScope pipeline with your own data is working properly. 

For example, if you are running a [Docker](https://www.docker.com/) container,

```bash
## Test the NovaScope pipeline with dry-run
## NOTE: make your to replace /path/to/working/dir/ with your working directory
docker run -it --rm -v /path/to/working/dir:/data hyunminkang/novascope \
    bash -c "snakemake -s /app/novascope/NovaScope.smk --rerun-incomplete -d data/output --configfile /data/config_job.yaml --dry-run -p"
```

If you are running a [Singularity](https://sylabs.io/docs/) container,

```bash
## Test the NovaScope pipeline with dry-run
## NOTE: make your to replace /path/to/working/dir/ with your working directory
singularity exec --bind /path/to/working/dir:/data novascope_latest.sif \
    snakemake -s /app/novascope/NovaScope.smk \
    --rerun-incomplete -d data/output \
    --configfile /data/config_job.yaml \
    --dry-run -p
```

If the dry-run is successful, you may run the full pipeline by substituting `--dry-run` with `--cores [num-cpus]`