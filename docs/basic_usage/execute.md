
# Executing the NovaScope Pipeline

## Preliminary Steps 

!!! tip "A Dry Run"
    Before running NovaScope, performing a sanity check by executing a dry run is highly recommended. A dry run verifies that your `config_job.yaml` is properly configured, your working directory is not locked, and outlines the necessary jobs to be executed.

!!! tip "A Rule Graph / A Directed Acyclic Graph (DAG)"
    Additionally, you can create [a rule graph](../home/workflow_structure.md) that visually represents the structure of the workflow or a [Directed Acyclic Graph (DAG)](https://snakemake.readthedocs.io/en/stable/tutorial/basics.html#step-4-indexing-read-alignments-and-visualizing-the-dag-of-jobs) to view all jobs and their actual dependencies.

Below provides commands for a dry-run and visualization.

```bash
# paths
smk_dir=/path/to/the/novascope/repository
job_dir=/path/to/the/job/directory              # The job directory should has the `config_job.yaml` file.

## (recommended) start with a dry run
## - view all information:
snakemake -s $smk_dir/NovaScope.smk --rerun-incomplete -d $job_dir --dry-run -p

## - simply summarize the jobs to be executed without other information:
snakemake -s $smk_dir/NovaScope.smk --rerun-incomplete -d $job_dir --dry-run --quiet

## (optional) visualization:
## - (1) rulegraph
snakemake --rulegraph  -s $smk_dir/NovaScope.smk --rerun-incomplete -d $job_dir | dot -Tpdf > rulegraph.pdf

## - (2) DAG
snakemake --dag  -s $smk_dir/NovaScope.smk --rerun-incomplete -d $job_dir | dot -Tpdf > dag.pdf
```

## Execution Options

Below we applied:

* `--rerun-incomplete` to enable the pipeline to re-run any jobs the output of which is identified as incomplete, 
* `--latency-wait` to request the pipeline pauses for the defined time awaiting an output file if not instantly accessible after a job, compensating for filesystem delay.

Please note those options are OPTIONAL. For more options, please see the [A Rule Execution Guide](../fulldoc/execution_guide/core_concepts.md#execution-dynamics) and the [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/index.html).

### Option A: Local Execution

If your computing environment does not require a job scheduler such as SLURM, you can run the pipeline locally. An example script is provided below. Make sure to replace the variables to relevant paths, the number of cores, and the time to wait for latency. 

```bash
## path
smk_dir=/path/to/the/novascope/directory        # path to NovaScope repository
job_dir=/path/to/the/job/directory              # The job directory should has the `config_job.yaml` file.

## parameters
Ncores=<number_of_cores>                        # replace <number_of_cores> by the number of available CPU cores you wish to use
wait_time=<time_to_wait>                        # Replace <time_to_wait> with a specific duration in seconds, e.g., 120.

## execute the NovaScope pipeline
snakemake --latency-wait $wait_time -s ${smk_dir}/NovaScope.smk -d $job_dir --cores $Ncores --rerun-incomplete 
```

See the following examples to see how to execute the pipeline locally:

* [Minimal Test Run](https://github.com/seqscope/NovaScope/blob/main/testrun/minimal_test_run/submit_local.sh)
* [Shallow Liver Section](https://github.com/seqscope/NovaScope/blob/main/testrun/shallow_liver_section/submit_local.sh)
* [Deep Liver Section](https://github.com/seqscope/NovaScope/blob/main/testrun/deep_liver_section/submit_local.sh)

### Option B: SLURM using a Master Job

!!! tip "A Master Job"
    If your computing environment support a job scheduler such [SLURM](https://slurm.schedmd.com/documentation.html), a recommended approach to submit a 'Master Job' that oversees and manages the status of all jobs.

First, make sure you have the [SLURM configuration file](../installation/slurm.md) available. The `--latency-wait` and `--rerun-incomplete` are preset in the example SLURM configuration file, eliminating manual specification.

Now establish a master job to monitor the progress of all tasks and handle job submissions. Create a file similar to the information below. Note that the settings may vary based on your specific computing environment. 

!!! warning "Memory and Time Limits"
       The master job requires **minimal memory but an extended time limit** to ensure all related jobs are submitted and completed. Otherwise, NovaScope will exit and unfinished jobs will not be executed or tracked.

```bash
#!/bin/bash
####  Job configuration
#SBATCH --account=<account_name>               # Replace <account_name> with your account identifier
#SBATCH --partition=<partition_name>           # Replace <partition_name> with your partition name
#SBATCH --job-name=<job_name>                  # Replace <job_name> with a name for your job
#SBATCH --nodes=1                              # Number of nodes, adjust as needed
#SBATCH --ntasks-per-node=1                    # Number of tasks per node, adjust based on requirement
#SBATCH --cpus-per-task=1                      # Number of CPUs per task, adjust as needed
#SBATCH --mem-per-cpu=<memory_allocation>      # Memory per CPU, replace <memory_allocation> with value, e.g., "2000m"
#SBATCH --time=<time_limit>                    # Job time limit, replace <time_limit> with value, e.g., "72:00:00"
#SBATCH --mail-user=<your_email>               # Replace <your_email> with your email address
#SBATCH --mail-type=END,FAIL,REQUEUE           # Notification types for job status
#SBATCH --output=./logs/<log_filename>         # Replace <log_filename> with the log file name pattern

## path
smk_dir=/path/to/the/novascope/directory                             # path to NovaScope repository
job_dir=/path/to/the/job/directory                                   # The job directory should has the `config_job.yaml` file.

## SLURM profile
slurm_params="--profile /path/to/the/slurm/configuration/directory"  # The SLURM configuration directory should have the SLURM configuration file: `config.yaml`. 
                                                                     # For example, if your snakemake is version v7.29.0, use `--profile $smk_dir/info/slurm/v7.29.0`

## execute the NovaScope pipeline
snakemake $slurm_params -s ${smk_dir}/NovaScope.smk -d $job_dir 
```

Specific examples prepared for the three datasets are provided below:

* [Minimal Test Run](https://github.com/seqscope/NovaScope/blob/main/testrun/minimal_test_run/submit_HPC.job)
* [Shallow Liver Section](https://github.com/seqscope/NovaScope/blob/main/testrun/shallow_liver_section/submit_HPC.job)
* [Deep Liver Section](https://github.com/seqscope/NovaScope/blob/main/testrun/deep_liver_section/submit_HPC.job)

Then submit the master job through `sbatch`:

```bash
sbatch submit_HPC.job
```

### Option C: SLURM via Command Lines

For a small number of quick jobs, you can execute NovaScope with [SLURM](https://slurm.schedmd.com/documentation.html) using a single command line without a master job. 

This is similar to the local execution, but you need to specify the SLURM profile. Ensure the [SLURM configuration file](../installation/slurm.md) is ready before proceeding. The `--latency-wait` and `--rerun-incomplete` options are pre-configured in the example SLURM file.

!!! warning "Potential Disruptions"
    It is important to remember that if you are logged out before all jobs have been submitted to SLURM, any remaining jobs, i.e., those haven't been submitted, will not be submitted.

```bash
## path
smk_dir=/path/to/the/novascope/directory                             # path to NovaScope repository
job_dir=/path/to/the/job/directory                                   # The job directory should has the `config_job.yaml` file.

## SLURM profile
slurm_params="--profile /path/to/the/slurm/configuration/directory"  # The SLURM configuration directory should have the SLURM configuration file: `config.yaml`. 
                                                                     # For example, if your snakemake is version v7.29.0, use `--profile $smk_dir/info/slurm/v7.29.0`

## execute the NovaScope pipeline
snakemake $slurm_params -s ${smk_dir}/NovaScope.smk -d $job_dir
```