
# Execute NovaScope Pipeline

## 1 Preliminary Steps

Performing a dry run and generating a rule graph are essential preliminary steps. They ensure your config_job.yaml is correctly set up, visualize the workflow's structure, and summarize required jobs.

```
## First, define $smk_dir is the location of NovaScope repository
smk_dir=/nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope

cd $smk_dir

## (Recommended) Start with a dry run
## - View all information:
snakemake --dry-run -p --latency-wait 120 -s NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir
## - Simply summarize the jobs to be executed without other information:
snakemake --dry-run -p --latency-wait 120 -s NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir --quiet -n

## (Optional) Visualize the required steps and their dependencies:
snakemake --rulegraph -s NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir | dot -Tpdf > rulegraph.pdf

```

## 2 Execution Options

### Option A: SLURM using a Master Job
This approach involves utilizing a master SLURM job to oversee and manage the status of all other jobs. Initially, you need to establish the master job. Typically, this job requires minimal memory because its primary role is to monitor the progress of all tasks, handle job submissions based on dependencies and available resources. However, it's crucial for the master job to have an extended time limit, ensuring it remains active longer than the total time required to complete all associated jobs.

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
smk_dir="<path_to_NovaScope_repo>"             # Replace <path_to_NovaScope_repo> with the path to the NovaScope repository
job_dir="$smk_dir/<job_directory>"             # Replace <job_directory> with your specific job directory path
slurm_params="--profile $smk_dir/slurm"        # Directory of the SLURM configuration file, adjust if your config.yaml is located elsewhere

# Execute the NovaScope pipeline
snakemake $slurm_params --latency-wait 120 -s $smk_dir/NovaScope.smk --rerun-triggers

```

Create a file with the above information, e.g. submit_Novascope_example.job, and then submit this file to SLURM using the following command:

```
sbatch submit_Novascope_example.job
```
  

### Option B: SLURM via Command Line


For a small number of quick tasks, you can submit them with a single command line. However, it's important to remember that if you log out before all jobs have been submitted to SLURM, any remaining jobs, i.e., those haven't been submitted, will not be submitted.

```
smk_dir="<path_to_NovaScope_repo>"             # Replace <path_to_NovaScope_repo> with the path to the NovaScope repository
job_dir="$smk_dir/<job_directory>"             # Replace <job_directory> with your specific job directory path
slurm_params="--profile $smk_dir/slurm"        # Directory of the SLURM configuration file, adjust if your config.yaml is located elsewhere

snakemake $slurm_params --latency-wait 120 -s ${smk_dir}/NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir
```

### Option C: Local Execution
Run the pipeline locally, specifying the number of cores.

```
smk_dir="<path_to_NovaScope_repo>"             # Replace <path_to_NovaScope_repo> with the path to the NovaScope repository
job_dir="$smk_dir/<job_directory>"             # Replace <job_directory> with your specific job directory path
slurm_params="--profile $smk_dir/slurm"        # Directory of the SLURM configuration file, adjust if your config.yaml is located elsewhere

Ncores=1 # Number of CPU cores

snakemake --latency-wait 120 -s ${smk_dir}/NovaScope.smk --rerun-triggers mtime --rerun-incomplete -d $job_dir --cores $Ncores
```
