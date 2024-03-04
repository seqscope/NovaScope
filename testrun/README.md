
## 1 Download Input Data

### Example 1 - Regional Section Test Run

The input data originates from a specific, limited region of a section. 

Download the first and second sequencing data sets from [here](https://www.dropbox.com/scl/fi/3egsr9nqc559e9hb45vik/B08Csub_20240301_raw.tar.gz?rlkey=z06xwb3v6ku19dp6br6mlsgkm&dl=0).

No histology files is provided for this testrun.

```
# Define the $job_dir, with config_job.yaml and the downloaded input data.
job_dir="$smk_dir/testrun/regional_section"  

mkdir -p  $job_dir && cd $job_dir

```

### Example 2 - Full Section Shallow Sequencing Test Run 

The input data is from a full section.

Download the first and second sequencing data sets from here. *TBC: Add the download link*

```
# Define the $job_dir, with config_job.yaml and the downloaded input data.
job_dir="$smk_dir/testrun/full_section_shallow"  

mkdir -p  $job_dir && cd $job_dir

# Download histology file
wget https://historef-sample-data.s3.amazonaws.com/sample/b08c/histology.tif
```

### Example 3 - Full Section Deep Sequencing Test Run 

The input data is from a full section and it has been deeply sequenced.

Download the first and second sequencing data sets from here. *TBC: Add the download link*

## 2 Configure config_job.yaml

Prepare the `config_job.yaml` file to specify all inputs, outputs, and parameters. Modify the existing `config_job.yaml` file to suit your specific task and input data requirements.

## 3 Execute NovaScope Pipeline

### 3.1 Preliminary Steps

Performing a dry run and generating a rule graph are essential preliminary steps. They ensure your config_job.yaml is correctly set up and visualize the workflow's structure.

    ```
    # First, define $smk_dir is the location of NovaScope repository
    smk_dir=/nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope

    cd $smk_dir

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
