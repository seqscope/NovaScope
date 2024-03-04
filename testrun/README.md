# NovaScope Pipeline Test Run Guide

This guide outlines the steps for a test run of the NovaScope pipeline using a small region from NovaSeq data.

## 1: Download Sequencing Data
Download the first and second sequencing data sets for the test run.

Note: This is a tentative link.


## 2: Configure config_job.yaml

Prepare the config_job.yaml file to specify all inputs, outputs, and parameters. Modify the existing config_job.yaml file to suit your specific task and input data requirements.

## 3: Execute NovaScope Pipeline

### 3.1 Preliminary Steps

Performing a dry run and generating a rule graph are essential preliminary steps. They ensure your config_job.yaml is correctly set up and visualize the workflow's structure.

    ```
    # First, define $smk_dir is the location of NovaScope repository
    smk_dir=/nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope

    cd $smk_dir

    # Define the $job_dir, which has the config_job.yaml file created at the 2nd step. This will be used to store the log files.
    job_dir="$smk_dir/testrun"  

    # (Optional but recommended) Give a dry run first.
    snakemake --dry-run -p --latency-wait 120 -s NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir

    # (Optional) Visualize the required steps and their dependencies.
    snakemake --rulegraph -s NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir | dot -Tpdf > rulegraph.pdf

    ```

### 3.2 Execution Options

Option A: SLURM Master Job
For managing jobs via SLURM, revise and submit the submit_Novascope_example.job file.
Utilizing SLURM for job management is recommended due to the extended duration of steps. Additionally, SLURM aids in organizing log files by creating rule-specific subdirectories within the job's log directory, each holding its own output and error files.

    ```
    cd $job_dir
    sbatch submit_Novascope_example.job
    ```

Option B: SLURM via Command Line
Execute the pipeline using SLURM with specified parameters.

    ```
    slurm_params="--profile ${smk_dir}/slurm" # SLURM config directory path
    snakemake $slurm_params --latency-wait 120 -s ${smk_dir}/NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir
    ```

Option C: Local Execution
Run the pipeline locally, specifying the number of cores.

    ```
    Ncores=1 # Number of CPU cores
    snakemake --latency-wait 120 -s NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir --cores $Ncores
    ```