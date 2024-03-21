# Expected Output from NovaScope

## Output Directory Structure

The directory passed through `output` paramter in the `config_job.yaml` will be organized as follows, 

```
├── align
├── histology
├── seq1st
└── seq2nd
```

### seq1st

The seq1st directory is structured for organizing 1st sequencing FASTQ files and spatial barcode maps. It includes:

* A `fastqs` subdirectory for all input 1st sequencing FASTQ files via symlink.
* Two subdirectories for spatial barcode maps:
    * `sbcds` for maps of individual tiles from the 1st sequencing,
    * `nbcds` for a map organized on a per-chip basis, used in later processing.

```
└── seq1st
    └── <flowcell_ID>
        ├── fastqs
        ├── nbcds
        └── sbcds
```

### seq2nd

The `seq2nd` directory is dedicated to managing all input 2nd sequencing FASTQ files via symlinks.
The directory structure is as follows:

```
└── seq2nd
    ├── <prefix1>
    |   ├── <prefix1>.R1.fastq.gz
    |   └── <prefix1>.R2.fastq.gz
    └── <prefix2>
        ├── <prefix2>.R1.fastq.gz
        └── <prefix2>.R2.fastq.gz
```

### histology

The `histology` directory is designated for holding all input histology files.

### align

The `align` directory encompasses several subdirectories, including: 
(1) `match`, which houses the outcomes of aligning second sequencing reads with spatial barcodes for the corresponding chip section; 
(2) `bam`, where alignment outcomes such as the BAM file, summary metrics, and visualizations are stored; 
(3) `sge`, containing a spatial gene expression (SGE) matrix and its associated visualizations; 
(4) `histology`, which stores histology images aligned with the spatial coordinates of the SGE matrix.

```
align
└── <flowcell_ID>
    └── <section_chip_ID>
        ├── bam
        ├── histology
        ├── match
        └── sge
```

## Downstream Analysis 

The aligned sequenced reads can be directly used for tasks that require read-level information, such as allele-specific expression or somatic variant analysis. The SGE matrix can also be analyzed with many software tools, such as Latent Dirichlet Allocation (LDA) and Seurat. 

An exemplary downstream analysis is provided at [NovaScope-exemplary-downstream-analysis](https://github.com/seqscope/NovaScope-exemplary-downstream-analysis).
