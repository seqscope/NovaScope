
# Executing the NovaScope Pipeline

## Preliminary Steps 

Before running the full pipeline, performing a sanity check by
executing a dry run is highly recommended. A dry run verifies that your `config_job.yaml` is properly configured and outlines the necessary jobs to be executed. 

Additionally, you can create a rule graph that visually represents the structure of the workflow or a DAG (Directed Acyclic Graph) to view all jobs and their actual dependency structure.

```bash
# Paths
smk_dir="<path_to_NovaScope_repository>"    # Replace <path_to_NovaScope_repository> with the path to the NovaScope repository
job_dir="<job_directory>"                   # Replace <job_directory> with your specific job directory path, which has the `config_job.yaml` file.

## (Recommended) Start with a dry run
## - View all information:
snakemake -s $smk_dir/NovaScope.smk --rerun-incomplete -d $job_dir --dry-run -p

## - Simply summarize the jobs to be executed without other information:
snakemake -s $smk_dir/NovaScope.smk --rerun-incomplete -d $job_dir --dry-run --quiet

## (Optional) Visualization.
## - (1) Rulegraph
snakemake --rulegraph  -s $smk_dir/NovaScope.smk --rerun-incomplete -d $job_dir | dot -Tpdf > rulegraph.pdf

## - (2) DAG
snakemake --dag  -s $smk_dir/NovaScope.smk --rerun-incomplete -d $job_dir | dot -Tpdf > dag.pdf
```

## Execution Options

### Option A: Local Execution

If your computing environment does not require a job scheduler such as Slurm, you can run the pipeline locally. You will need to specify the number of cores.

An example script is provided below. Make sure to replace the variables to relevant paths and the number of cores.

```bash
smk_dir="<path_to_NovaScope_repository>"  # Replace <path_to_NovaScope_repository> with the path to the NovaScope repository
job_dir="<path_to_the_job_directory>"     # Replace <job_directory> with your specific job directory path that contains the `config_job.yaml` file

Ncores=8                                  # Replace to the number of available CPU cores you wish to use

snakemake --latency-wait 120 -s ${smk_dir}/NovaScope.smk -d $job_dir --cores $Ncores --rerun-incomplete 
```


See the following examples to see how to execute the pipeline locally:

* [Minimal Test Run](https://github.com/seqscope/NovaScope/blob/main/testrun/minimal_test_run/submit_local.sh)
* [Shallow Liver Section](https://github.com/seqscope/NovaScope/blob/main/testrun/shallo_liver_section/submit_local.sh)
* [Deep Liver Section](https://github.com/seqscope/NovaScope/blob/main/testrun/deep_liver_section/submit_local.sh)


### Option B: Slurm using a Master Job

If your computing environment expects to run jobs via a job scheduler such [Slurm](https://slurm.schedmd.com/documentation.html), a recommended approach to submit a 'Master Job' that oversees and manage the status of all other jobs. 

First, you need to establish the master job. The primary role of this job is to monitor the progress of all tasks, handle job submissions based on dependencies and available resources. Thus, it requires minimal memory but an extended time limit. Its time limit should be longer than the total time required to complete all associated jobs.

Create a file similar to the information below. Note that the details of the contents may vary based on your specific computing environment. 

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

# Paths
smk_dir="<path_to_NovaScope_repository>"            # Replace <path_to_NovaScope_repository> with the path to the NovaScope repository
job_dir="<path_to_the_job_directory>"               # Replace <path_to_the_job_directory> with your specific job directory path
slurm_params="--profile <path_to_slurm_directory>"  # Replace <path_to_slurm_directory> with your directory of the SLURM configuration file

# Execute the NovaScope pipeline
snakemake $slurm_params  --latency-wait 120  -s ${smk_dir}/NovaScope.smk  -d $job_dir 
```

Specific examples prepared for the three datasets are provided below:

* [Minimal Test Run](https://github.com/seqscope/NovaScope/blob/main/testrun/minimal_test_run/submit_HPC.job)
* [Shallow Liver Section](https://github.com/seqscope/NovaScope/blob/main/testrun/shallow_liver_section/submit_HPC.job)
* [Deep Liver Section](https://github.com/seqscope/NovaScope/blob/main/testrun/deep_liver_section/submit_HPC.job) test runs.

Then submit the master job through `sbatch`:

```
sbatch submit_HPC.job
```

### Option C: SLURM via Command Line

For a small number of quick jobs, you can submit them with a single command line without submitting a master job through [Slurm](https://slurm.schedmd.com/documentation.html).

This is similar to the local execution, but you need to specify the Slurm parameters.

It is important to remember that if you are logged out before all jobs have been submitted to Slurm, any remaining jobs, i.e., those haven't been submitted, will not be submitted.

```bash
smk_dir="<path_to_NovaScope_repository>"            # Replace <path_to_NovaScope_repository> with the path to the NovaScope repository
job_dir="<path_to_the_job_directory>"               # Replace <path_to_the_job_directory> with your specific job directory path
slurm_params="--profile <path_to_slurm_directory>"  # Replace <path_to_slurm_directory> with your directory of the SLURM configuration file

snakemake $slurm_params --latency-wait 120 -s ${smk_dir}/NovaScope.smk -d $job_dir 
```

