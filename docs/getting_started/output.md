# Output

## 1. Output Directory Structure

The directory passed through `output` paramter in the `config_job.yaml` will be organized as follows, 

```
├── align
├── histology
├── seq1st
└── seq2nd
```

### 1.1 seq1st

The seq1st directory is structured for organizing 1st sequencing FASTQ files and spatial barcode maps. It includes:

* `fastq`: A fastqs subdirectory for the 1st sequencing FASTQ files (`fastq`).
* Three subdirectories for spatial barcode maps:
    * sbcds for maps of individual tiles from the 1st sequencing,
    * sbcds.part for maps related to section chips, organized per tile,
    * nbcds for a map organized on a per-chip basis, used in later processing.

```
└── seq1st
    └── <flowcell_id>
        ├── fastqs
        ├── nbcds
        ├── sbcds
        └── sbcds.part
```

### 1.2 seq2nd

The seq2nd directory is dedicated to managing the 2nd sequencing FASTQ files.

### 1.3 histology

The `histology` directory is designated for holding all input histology files.

### 1.4 align

The `align` directory encompasses several subdirectories, including: 
(1) `match`, which houses the outcomes of aligning second sequencing reads with spatial barcodes for the corresponding chip section; 
(2) `bam`, where alignment outcomes such as the BAM file, summary metrics, and visualizations are stored; 
(3) `sge`, containing a spatial gene expression (SGE) matrix and its associated visualizations; 
(4) `histology`, which stores histology images aligned with the spatial coordinates of the SGE matrix.

```
align
└── <flowcell_id>
    └── <section_chip_id>
        ├── bam
        ├── histology
        ├── match
        └── sge
```

## 2. Usage

The aligned sequenced reads can be directly used for tasks that require read-level information, such as allele-specific expression or somatic variant analysis. The SGE matrix can also be analyzed with many software tools, such as Latent Dirichlet Allocation (LDA) and Seurat. 

An exemplary downstream analysis is provided at: https://github.com/seqscope/NovaScope-exemplary-downstream-analysis.
