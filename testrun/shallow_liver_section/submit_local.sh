# Paths
smk_dir="/path/to/NovaScope" # Path to the NovaScope pipeline repo.
job_dir="$smk_dir/testrun/shallow_liver_section"                  # Path to your Job directory, which should have a config_job.yaml file and will be used to save the log files.
Ncores=8                                                     # Number of cores to use

# Execute the NovaScope pipeline locally
snakemake --latency-wait 120 -s $smk_dir/NovaScope.smk -d $job_dir --cores $Ncores