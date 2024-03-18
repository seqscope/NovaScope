# Snakemake with SLURM

It is recommended to integrate SLURM scheduler with Snakemake, which can automate the process of submitting your jobs.

Please be aware that Snakemake introduced significant updates for cluster Configuration starting from **version 8**. Thus, we advise checking to verify your Snakemake version using `snakemake --version`. 

In NovaScope, we utilized a cluster configuration profile to define the details of the cluster and resources given its consistency and time-saving benefits. More details are provided below. Those files were crafted with inspiration from the [smk-simple-slurm](https://github.com/jdblischak/smk-simple-slurm) repository.

## A Cluster Configuration file for Snakemake v7.29.0

Create a `config.yaml` with the following settings. Please substitute the placeholders below, marked with <>, to suit your specific case. Please see our example file at [slurm/v7.29.0/config.yaml](https://github.com/seqscope/NovaScope/blob/main/slurm/v7.29.0/config.yaml). 

```
## Cluster Configuration
## The following setting also aids in organizing log files by creating rule-specific subdirectories within the job's log directory, each holding its own output and error files.
cluster:
  mkdir -p logs/{rule}/ &&
  sbatch
    --job-name={rule}_{wildcards}
    --output=logs/{rule}/{rule}___{wildcards}___%j.out
    --error=logs/{rule}/{rule}___{wildcards}___%j.err
    --account={resources.account}
    --partition={resources.partition}
    --mem={resources.mem}
    --time={resources.time}
    --cpus-per-task={threads}
    --parsable
    --nodes={resources.nodes}

## Default Resources for Jobs
default-resources:
  - partition=<your_default_partition>    # Replace <your_default_partition> with your actual partition name
  - mem=<default_memory_allocation>       # Replace <default_memory_allocation> with memory, e.g., "4G"
  - time=<default_time_limit>             # Replace <default_time_limit> with time, e.g., "01:00:00"
  - nodes=<default_number_of_nodes>       # Replace <default_number_of_nodes> with nodes, e.g., "1"
  - account=<default_account_information> # Replace <default_account_information> with your account info

## General Snakemake Settings
jobs: <max_number_of_jobs>               # Replace <max_number_of_jobs> with your desired maximum number of concurrent jobs, e.g., 10
latency-wait: <latency_seconds>          # Replace <latency_seconds> with the number of seconds to wait if job output is not present, e.g., 120
local-cores: <local_core_count>          # Replace <local_core_count> with the max number of cores to use locally, e.g., "20"
restart-times: <restart_attempts>        # Replace <restart_attempts> with the number of times to retry failing jobs, e.g., "0" for no retries
max-jobs-per-second: <job_submission_rate> # Replace <job_submission_rate> with the limit on how many jobs can be submitted per second, e.g., "20"
keep-going: <continue_after_failure>     # Replace <continue_after_failure> with True or False to indicate whether to continue executing other jobs after a failure
rerun-incomplete: <rerun_incomplete_jobs> # Replace <rerun_incomplete_jobs> with True or False to decide if incomplete jobs should be rerun
printshellcmds: <print_commands>         # Replace <print_commands> with True or False to specify if shell commands should be printed before execution

## Scheduler Settings
#scheduler: greedy      

## Conda Environment Settings
use-conda: <True_or_False>               # Enable use of Conda environments
conda-frontend: conda                    # Specify Conda as the package manager frontend
```

## A Cluster Configuration file for Snakemake v8.6.0

Please first install the Snakemake executor plugin "cluster-generic":

```
pip install snakemake-executor-plugin-cluster-generic
```

Then, create the cluster configuration file with below. Please substitute the placeholders below, marked with <>, to suit your specific case. Please see our example file at [slurm/v8.6.0/config.yaml](https://github.com/seqscope/NovaScope/blob/main/slurm/v8.6.0/config.yaml). 

```
executor: "cluster-generic"
cluster-generic-submit-cmd: "mkdir -p logs/{rule}/ &&
  sbatch
    --job-name={rule}_{wildcards} \
    --output=logs/{rule}/{rule}___{wildcards}___%j.out \
    --error=logs/{rule}/{rule}___{wildcards}___%j.err \
    --partition={resources.partition} \
    --mem={resources.mem} \
    --time={resources.time} \
    --cpus-per-task={threads} \
    --parsable \
    --nodes={resources.nodes} "

default-resources:
  - partition="main"
  - mem="6500MB"
  - time="05:00:00"
  - nodes=1


jobs: 10                       
latency-wait: 120              
local-cores: 20                
restart-times: 0               
max-jobs-per-second: 20
keep-going: True
rerun-incomplete: True
printshellcmds: True

software-deployment-method: conda
```

## Additional functions
If you encounter situations where your jobs fail without any warnings, it is feasible to using a cluster status script to keep track of your jobs. See details [here](https://github.com/jdblischak/smk-simple-slurm/tree/main/extras).