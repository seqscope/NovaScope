
# Executing NovaScope Pipeline

## 1 Preliminary Steps 

Executing a dry run is a critical initial step. It verifies that your `config_job.yaml` is properly configured and outlines the necessary jobs to be executed. 

Additionally, you can create a rule graph that visually represents the structure of the workflow or a DAG (Directed Acyclic Graph) to view all jobs and their actual dependency structure.

```
# Paths
smk_dir="<path_to_NovaScope_repo>"    # Replace <path_to_NovaScope_repo> with the path to the NovaScope repository
job_dir="<job_directory>"             # Replace <job_directory> with your specific job directory path, which has the `config_job.yaml` file.

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

## 2 Execution Options

### Option A: SLURM using a Master Job
This approach involves utilizing a master SLURM job to oversee and manage the status of all other jobs. 

First, you need to establish the master job. The primary role of this job is to monitor the progress of all tasks, handle job submissions based on dependencies and available resources. Thus, it requires minimal memory but an extended time limit. Its time limit should be longer than the total time required to complete all associated jobs.

Below is an example:
```
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
smk_dir="<path_to_NovaScope_repo>"                  # Replace <path_to_NovaScope_repo> with the path to the NovaScope repository
job_dir="<path_to_the_job_directory>"               # Replace <path_to_the_job_directory> with your specific job directory path
slurm_params="--profile <path_to_slurm_directory>"  # Replace <path_to_slurm_directory> with your directory of the SLURM configuration file

# Execute the NovaScope pipeline
snakemake $slurm_params --latency-wait 120 -s $smk_dir/NovaScope.smk --rerun-triggers
```

Create a file with the above information, e.g. submit_Novascope_example.job, and then submit this file:

```
sbatch submit_Novascope_example.job
```

### Option B: SLURM via Command Line


For a small number of quick tasks, you can submit them with a single command line. 

However, it's important to remember that if you log out before all jobs have been submitted to SLURM, any remaining jobs, i.e., those haven't been submitted, will not be submitted.

```
smk_dir="<path_to_NovaScope_repo>"                  # Replace <path_to_NovaScope_repo> with the path to the NovaScope repository
job_dir="<path_to_the_job_directory>"               # Replace <path_to_the_job_directory> with your specific job directory path
slurm_params="--profile <path_to_slurm_directory>"  # Replace <path_to_slurm_directory> with your directory of the SLURM configuration file

snakemake $slurm_params --latency-wait 120 -s ${smk_dir}/NovaScope.smk --rerun-incomplete -d $job_dir
```

### Option C: Local Execution
Run the pipeline locally, specifying the number of cores.

```
smk_dir="<path_to_NovaScope_repo>"             # Replace <path_to_NovaScope_repo> with the path to the NovaScope repository
job_dir="<path_to_the_job_directory>"          # Replace <job_directory> with your specific job directory path

Ncores=1 # Number of CPU cores

snakemake --latency-wait 120 -s ${smk_dir}/NovaScope.smk --rerun-incomplete -d $job_dir --cores $Ncores
```
