# Snakemake with SLURM

Snakemake can automate the process of submitting your jobs to the SLURM scheduler. Utilizing SLURM for job management is recommended due to the extended duration of steps. 

In NovaScope, we used a configuration profile to specify the sbatch information. For more details, please refers the official Snakemake documentation for the [Executor Plugin for HPC Clusters using the SLURM Batch System](https://github.com/snakemake/snakemake-executor-plugin-slurm/blob/main/docs/further.md)

## Integrating a configuration profile with snakemake

Using a configuration profile is recommended for its consistency and time-saving benefits. 

 To implement this, start by creating a configuration profile with all settings, for example, `<path_to_NovaScope_repository>/slurm/config.yaml`. Then, apply this configuration by referencing its parent directory in your Snakemake command like so: `snakemake --profile <path_to_NovaScope_repository>/slurm`.

The configuration profile utilized in NovaScope was crafted with inspiration from the [smk-simple-slurm](https://github.com/jdblischak/smk-simple-slurm) repository. Below are the specifics of our settings. 

Please substitute the placeholders below, marked with <>, to suit your specific case.

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


## General Snakemake settings

jobs: <max_number_of_jobs>               # Replace <max_number_of_jobs> with your desired maximum number of concurrent jobs, e.g., 10
latency-wait: <latency_seconds>          # Replace <latency_seconds> with the number of seconds to wait if job output is not present, e.g., 120
local-cores: <local_core_count>          # Replace <local_core_count> with the max number of cores to use locally, e.g., "20"
restart-times: <restart_attempts>        # Replace <restart_attempts> with the number of times to retry failing jobs, e.g., "0" for no retries
max-jobs-per-second: <job_submission_rate> # Replace <job_submission_rate> with the limit on how many jobs can be submitted per second, e.g., "20"
keep-going: <continue_after_failure>     # Replace <continue_after_failure> with True or False to indicate whether to continue executing other jobs after a failure
rerun-incomplete: <rerun_incomplete_jobs> # Replace <rerun_incomplete_jobs> with True or False to decide if incomplete jobs should be rerun
printshellcmds: <print_commands>         # Replace <print_commands> with True or False to specify if shell commands should be printed before execution


## Scheduler settings

#scheduler: greedy      


## Conda environment settings

use-conda: <True_or_False>               # Enable use of Conda environments
conda-frontend: conda                    # Specify Conda as the package manager frontend
```