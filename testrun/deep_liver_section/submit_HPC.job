#!/bin/bash
####  Job name
#SBATCH --account=leeju0
#SBATCH --partition=standard
#SBATCH --job-name=full_section_deep
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2000m         # As a master job overseeing the status of each step, minimal memory is required.
#SBATCH --time=72:00:00             # Allocating an extended time limit is advisable due to its supervisory function, ensuring it exceeds the total process duration.
#SBATCH --mail-user=weiqiuc@umich.edu
#SBATCH --mail-type=END,FAIL,REQUEUE
#### where to write log files
#SBATCH --output=./logs/lda-%j_%x.out  # Log file path


# Paths
smk_dir="/path/to/NovaScope"                                            # [REPLACE] Path to the NovaScope pipeline repo.
job_dir="$smk_dir/testrun/full_section_deep"                            # Path to your Job directory, which should have a config_job.yaml file and will be used to save the log files.
slurm_params="--profile /path/to/the/slurm/configuration/directory"     # [REPLACE] Path to the SLURM parameter directory, which should include a config.yaml file. For example, if your snakemake is version v7.29.0, use `--profile $smk_dir/info/slurm/v7.29.0`

# Execute the NovaScope pipeline
snakemake $slurm_params --latency-wait 120 -s $smk_dir/NovaScope.smk -d $job_dir