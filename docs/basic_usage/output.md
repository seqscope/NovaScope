# Expected Output from NovaScope

## Output Directory Structure

The directory passed through `output` paramter in the `config_job.yaml` will be organized as follows, 

```
├── align
├── histology
├── match
├── seq1st
└── seq2nd
```

### seq1st

The `seq1st` directory is structured for organizing 1st sequencing FASTQ files and spatial barcode maps. It includes:

* A `fastqs` subdirectory for all input 1st sequencing FASTQ files via symlink.
* Two subdirectories for spatial barcode maps:
    * `sbcds` for maps of individual tiles from the 1st sequencing,
    * `nbcds` for a map organized on a per-chip basis, used in later processing.

```
└── seq1st
    └── <flowcell_id>
        ├── fastqs
        |   └── <seq1st_id>.fastq.gz
        ├── nbcds
        |   └── <chip_id>
        |       ├── 1_1.sbcds.sorted.tsv.gz
        |       ├── 1_1.sbcds.sorted.png
        |       ├── dupstats.tsv.gz
        |       └── manifest.tsv
        └── sbcds
           └── <chip_id>
                └── ...    # spatial maps of individual tile, and a manifest file 

```

### seq2nd

The `seq2nd` directory is dedicated to managing all input 2nd sequencing FASTQ files via symlinks. Each pair will be organized in one folder named by the 2nd sequencing ID provided via the job configuration file.

The following example demonstrates the directory structure using two pairs of input 2nd sequencing FASTQ files:

```
└── seq2nd
    ├── <seq2nd_id1>
    |   ├── <seq2nd_id1>.R1.fastq.gz
    |   └── <seq2nd_id1>.R2.fastq.gz
    └── <seq2nd_id2>
        ├── <seq2nd_id2>.R1.fastq.gz
        └── <seq2nd_id2>.R2.fastq.gz
```

### match
The `match` directory houses the outcomes of aligning second sequencing reads with spatial barcodes for the corresponding chip section.

```
└── match
    └── <flowcell_id>
        └── <chip_id>
            └── <seq2nd_id1>
                ├── <seq2nd_id1>.R1.counts.tsv
                ├── <seq2nd_id1>.R1.match.png
                ├── <seq2nd_id1>.match.sorted.uniq.tsv.gz
                └── <seq2nd_id1>.summary.tsv
```

### histology

The `histology` directory is designated for holding both the input histology file and the histology images aligned with the spatial coordinates of the SGE.

```
└── histology
    └── <flowcell_id>
        └── <chip_id>
            ├── raw
            |   └── ...     # a raw histology file
            └── aligned
                └── ...     # aligned histology files
```

### align

The `align` directory encompasses several subdirectories, including: 

* `bam` for alignment outcomes such as the BAM file, summary metrics, and visualizations;
* `sge` for a spatial gene expression (SGE) matrix and visualizations; 

```
└── align
    └── <flowcell_id>
        └── <chip_id>
           └── <run_id>
                ├── bam
                |   └── ...     
               └── sge
                    └── ...     
```

### analysis

The `analysis` directory includes three subdirectory mainly for the reformatting SGE matrix:

* `sgeAR` for the SGE matrix before reformatting, where the "AR" stands for analysis-ready,
* `preprocess` for the reformatted and filtered SGE matrices, filtered feature file, and meta files for coordinates,
* `segment` for the hexagon-indexed SGE.

```
└── analysis
    └── <run_id>
        └── <unit_id>
            ├── preprocess
            |   └── ...  
            ├── segment
            |   └── ...  
            └── sgeAR
                └── ...  
```

??? Note "The `sgeAR` Subfolder and Manual Preprocess"
    The `sgeAR` subfolder is specifically designed to host input SGE matrix that require reformatting. This subfolder is particularly useful when users wish to manually preprocess SGE, such as applying boundary filtering, before they undergo reformatting.

    **To manually preprocess an SGE matrix:**
    
    - **Preprocess the SGE matrix:** Users must manually preprocess the SGE matrix according to their specific requirements.
    - **Name the dataset:** After preprocessing, the dataset should be named and referred to as `unit_id`.
    - **Save the preprocessed SGE matrix:** Place the manually preprocessed SGE matrix in the `sgeAR` subfolder.
    - **Preprare a coordinate meta file** Prepare a `barcodes.minmax.tsv` with the minimum and maximum of X and Y coordinates in the `sgeAR` subfolder.
    - **Update the job configuration file:** Provide the `unit_id` in the [job configuration file](../basic_usage/job_config.md) to ensure it is recognized in subsequent processing steps.

    **Automatic Handling:**
    If reformatting features are requested without manually preparing the SGE matrix in the `sgeAR` as outlined, NovaScope will automatically generate a `unit_id`. It will then link the original SGE matrix from the `sge` subdirectory to the `sgeAR`, facilitating seamless processing.


## Downstream Analysis 

The aligned sequenced reads can be directly used for tasks that require read-level information, such as allele-specific expression or somatic variant analysis. The SGE can also be analyzed with many software tools, such as Latent Dirichlet Allocation (LDA) and Seurat. 

An exemplary downstream analysis is provided at [NovaScope-exemplary-downstream-analysis](https://github.com/seqscope/NovaScope-exemplary-downstream-analysis).
