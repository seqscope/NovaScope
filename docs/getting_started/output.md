# Output

## 1. Output 

The output, of which the path was provided via the `config_job.yaml`, will be organized as follows, 

```
├── align
├── histology
├── seq1st
└── seq2nd
```

### 1.1 seq1st

The `seq1st` directory contains a subdirectory (`fastqs`) for organizing the 1st sequencing FASTQ files, along with three others for managing the spatial barcode maps: one for individual tiles (`sbcds`), and two related to chip sections (`sbcds.part` and `nbcds`). 
For a chip section, the `sbcds.part` hosts the spatial barcode maps organized on a per-tile basis, while the `nbcds` contains a spatial barcode map organzied on a per-chip basis, which is applied in subsequent processing phases. 

```
└── seq1st
    └── <flowcell_id>
        ├── fastqs
        ├── nbcds
        ├── sbcds
        └── sbcds.part
```

### 1.2 seq2nd

The seq2nd directory is dedicated to managing the second set of sequencing FASTQ files.

### 1.3 histology

The `histology` directory is designated for holding all histology input files.

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
