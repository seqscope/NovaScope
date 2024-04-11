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

The seq1st directory is structured for organizing 1st sequencing FASTQ files and spatial barcode maps. It includes:

* A `fastqs` subdirectory for all input 1st sequencing FASTQ files via symlink.
* Two subdirectories for spatial barcode maps:
    * `sbcds` for maps of individual tiles from the 1st sequencing,
    * `nbcds` for a map organized on a per-chip basis, used in later processing.

```
└── seq1st
    └── <flowcell_ID>
        ├── fastqs
        |   └── <seq1st_id>.fastq.gz
        ├── nbcds
        |   └── <chip_ID>
        |       └── ...    # spatial maps of individual tile, and a manifest file 
        └── sbcds
            └── <chip_ID>
                ├── 1_1.sbcds.sorted.tsv.gz
                ├── 1_1.sbcds.sorted.png
                ├── dupstats.tsv.gz
                └── manifest.tsv
```

### seq2nd

The `seq2nd` directory is dedicated to managing all input 2nd sequencing FASTQ files via symlinks. Each pair will be organized in one folder named by the 2nd sequencing ID provided via the job configuration file.

The following example demonstrates the directory structure using two pairs of input 2nd sequencing FASTQ files:

```
└── seq2nd
    ├── <seq2nd_ID1>
    |   ├── <seq2nd_ID1>.R1.fastq.gz
    |   └── <seq2nd_ID1>.R2.fastq.gz
    └── <seq2nd_ID2>
        ├── <seq2nd_ID2>.R1.fastq.gz
        └── <seq2nd_ID2>.R2.fastq.gz
```

### match
The `match` directory houses the outcomes of aligning second sequencing reads with spatial barcodes for the corresponding chip section.

```
└── match
    └── <flowcell_ID>
        └── <chip_ID>
            └── <seq2nd_ID1>
                ├── <seq2nd_ID1>.R1.counts.tsv
                ├── <seq2nd_ID1>.R1.match.png
                ├── <seq2nd_ID1>.match.sorted.uniq.tsv.gz
                └── <seq2nd_ID1>.summary.tsv
```

### histology

The `histology` directory is designated for holding both the input histology file and the histology images aligned with the spatial coordinates of the SGE.

```
└── histology
    └── <flowcell_ID>
        └── <chip_ID>
            ├── raw
            |   └── ...     # a raw histology file
            └── aligned
                └── ...     # aligned histology files
```

### align

The `align` directory encompasses several subdirectories, including: 
(1) `bam`, where alignment outcomes such as the BAM file, summary metrics, and visualizations are stored; 
(2) `sge`, containing a spatial gene expression matrix (SGE) and its associated visualizations; 

```
align
└── <flowcell_ID>
    └── <chip_ID>
        └── <run_ID>
            ├── bam
            |   └── ...     
            └── sge
                └── ...     
```

### analysis

The `analysis` directory includes a `preprocess` subdirectory for FICTURE-compatible SGE, and a `segment` subdirectory for the hexagon-based SGE in the 10x genomics format.

```
analysis
└── <run_ID>
    └── <unit_ID>
        ├── preprocess
        |   └── ...  
        ├── segment
        |   └── ...  
        └── sgeAR
            └── ...  
```
## Downstream Analysis 

The aligned sequenced reads can be directly used for tasks that require read-level information, such as allele-specific expression or somatic variant analysis. The SGE can also be analyzed with many software tools, such as Latent Dirichlet Allocation (LDA) and Seurat. 

An exemplary downstream analysis is provided at [NovaScope-exemplary-downstream-analysis](https://github.com/seqscope/NovaScope-exemplary-downstream-analysis).
