# Rule `align`

## Purpose
The purpose of the `align` rule is to map the reads from 2nd-seq FASTQ files to the reference genome, focusing on a per-chip approach. For a chip associated with multiple pairs of 2nd-seq FASTQ files, NovaScope executes the `align` rule once utilizing all file pairs.

Specifically, the process involves 1) combining all FASTQ files from 2nd-seq that are related to this chip, 2) discarding any 2nd-seq reads from that do not possess a spatial barcode sequence (HDMI) identified in 1st-seq, 3) mapping 2nd-seq reads to the reference genome utilizing [STARsolo](https://github.com/alexdobin/STAR/tree/master).

## Input Files
* **2nd-seq FASTQ file**
All pairs of 2nd-seq FASTQ files that are associated to the given chip are designed as input.

* **Matched Spatial Barcode Files**
Matched Spatial barcode files for all pairs of 2nd-seq FASTQ files, which are produced by Rule [`smatch`](./smatch.md).

## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/align/<flowcell_id>/<chip_id>/<run_id>/bam
```

### (1) A Binary Alignment Map (BAM) File

**Description**: A [Binary Alignment Map (BAM)](https://en.wikipedia.org/wiki/Binary_Alignment_Map) file contains the aligned reads, sorted by genomic coordinates. The BAM file is accompanied by a BAM index (BAI) file.

**File Naming Convention**:

* The BAM file: `sttoolsAligned.sortedByCoord.out.bam`
* The BAI file: `sttoolsAligned.sortedByCoord.out.bam.bai`

**File Format**:
For detailed information on the file formats for BAM and BAI files, please refer to the [Format Specification](https://samtools.github.io/hts-specs/SAMv1.pdf) provided by Samtools.

### (2) Alignment summary metrics

**Description**: A table file containing metrics such as the total number of input reads, average length of input reads, and summary statistics for unique, multi-mapping, unmapped, and chimeric reads.

**File Naming Convention**:
`sttoolsLog.final.out`

**File Format**:
```
                                 Started job on |       Apr 01 18:32:36
                             Started mapping on |       Apr 01 18:33:47
                                    Finished on |       Apr 01 18:51:55
       Mapping speed, Million of reads per hour |       275.83

                          Number of input reads |       83363295
                      Average input read length |       68
                                    UNIQUE READS:
                   Uniquely mapped reads number |       44728786
                        Uniquely mapped reads % |       53.66%
                          Average mapped length |       86.51
                       Number of splices: Total |       4221113
            Number of splices: Annotated (sjdb) |       4108506
                       Number of splices: GT/AG |       4174922
                       Number of splices: GC/AG |       13282
                       Number of splices: AT/AC |       581
               Number of splices: Non-canonical |       32328
                      Mismatch rate per base, % |       0.92%
                         Deletion rate per base |       0.03%
                        Deletion average length |       1.56
                        Insertion rate per base |       0.01%
                       Insertion average length |       1.20
                             MULTI-MAPPING READS:
        Number of reads mapped to multiple loci |       9853625
             % of reads mapped to multiple loci |       11.82%
        Number of reads mapped to too many loci |       1330676
             % of reads mapped to too many loci |       1.60%
                                  UNMAPPED READS:
  Number of reads unmapped: too many mismatches |       0
       % of reads unmapped: too many mismatches |       0.00%
            Number of reads unmapped: too short |       4764703
                 % of reads unmapped: too short |       5.72%
                Number of reads unmapped: other |       22685505
                     % of reads unmapped: other |       27.21%
                                  CHIMERIC READS:
                       Number of chimeric reads |       0
                            % of chimeric reads |       0.00%
```

### (3) Digital Gene Expression Matrices (DGEs)

**Description**: A digital gene expression matrix (DGE) is generated for each genomic feature, including Gene, GeneFull, splice junctions (SJ), and Velocyto. The DGE for Gene counts reads match the gene transcript while the DGE for GeneFull counts all reads overlapping the exons and introns of the gene.

**File Naming Convention**: For each genomic feature, a DGE, which is composed of `barcodes.tsv.gz`, `features.tsv.gz`, and `matrix.mtx.gz`, is stored in a directory named after the genomic feature.

**File Format**:

* `barcodes.tsv.gz`: A single-column file with Unix line endings and no header, where each row lists a barcode.
```
AAAAAAAATAGTTCTGCTAGCTGGTAAGCT
AAAAAAAGTGATCAGAGGTGATATTATGCT
AAAAAAAGTTCGCACTATACGAACAGGGAT
```

* `features.tsv.gz`: Each row includes the following three columns without header: feature ID (column 1), feature name (column 2), and type of feature (column 3).
```
ENSMUSG00000100764	Gm29155	Gene Expression
ENSMUSG00000100635	Gm29157	Gene Expression
ENSMUSG00000100480	Gm29156	Gene Expression
```

* `matrix.tsv.gz`: A compressed sparse matrix file format storing non-zero gene expression values across spatial locations or barcodes in spatial transcriptomics data.
```
%%MatrixMarket matrix coordinate integer general
%
33989 17641021 17801209
9677 1 1
20305 2 1
23800 2 1
```
    - `Header`: Initial lines form the header, declaring the matrix's adherence to the [Market Matrix (MTX) format](https://math.nist.gov/MatrixMarket/formats.html), outlining its traits. This section may include comments (lines beginning with `%`) for extra metadata, all marked by a “%”.
    - `Dimensions`: Following the header, the first line details the matrix dimensions: the count of rows (features), columns (barcodes), and non-zero entries.
    - `Data Entries`: Post-dimensions, subsequent lines enumerate non-zero entries in triplet form: row index (feature index), column index (barcode index), and value (expression level).

## Output Guidelines
It is suggested to review the summary metrics to confirm the total read count, the percentage of reads aligned to genomes and genes, library saturation, the count of aligned spatial barcodes, and the count of unique transcripts.

## Parameters

The following parameter in the [job configuration](../../basic_usage/job_config.md) file will be applied in this rule.

```yaml
upstream:
  smatch:                   
    skip_sbcd: 1            
    match_len: 27           
  align:                    
     min_match_len: 30      
     min_match_frac: 0.66   
     len_sbcd: 30            
     len_umi: 9              
     len_r2: 101             
     exist_action: overwrite
     resource:               
       assign_type: stdin
       stdin:
         partition: standard
         threads: 10
         memory: 70000m
```

* **Reformat FASTQ Paramaters**

     Parameters in `smatch` and three parameters in `align` (including `len_sbcd`, `len_umi`, and `len_r2`) are used to pass values to the [`reformat-fastqs`](https://seqscope.github.io/spatula/tools/reformat_fastqs/) function in [spatula](https://seqscope.github.io/spatula/). Below, for each parameter, the corresponding parameter in [spatula](https://seqscope.github.io/spatula/), description, and the default value in NovaScope are provided.

     | Parameter     | `spatula` parameter | Description                                                                        | Default Value     |
     |---------------|---------------------|------------------------------------------------------------------------------------|-------------------|
     | `skip_sbcd`   | `--skip-sbcd`       | The number of initial bases to omit from the read.                                 | 1                 |
     | `match_len`   | `--match-len`       | The length of the spatial barcode to be considered as a perfectmatch.              | 27                |
     | `len_sbcd`    | `--len_sbcd`        | The length of the spatial barcode sequence to be copied in Read 1                  | 30                |
     | `len_umi`     | `--len_umi`         | The length of the UMI sequence (randomer) to be copied from Read 2 (beginning) to Read 1 (after spatial barcode) | 9       |
     | `len_r2`      | `--len_r2`          | The length of Read 2 sequences to be trimmed                                       | 101               |

     * `skip_sbcd`: This is useful if the 1st-seq spatial barcode lacks sufficient bases. When absent in the [job configuration](../../basic_usage/job_config.md) file, NovaScope determines `skip_sbcd` following the [`format`](./fastq2sbcd.md#parameters) in `fastq2sbcd`: 1 for DraI31 and 0 for DraI32.

* **Alignment Paramaters**

     Four parameters in `align` (including `len_sbcd`, `len_umi`, `min_match_len`, and `min_match_frac`) are used to pass values to [STARsolo](https://github.com/alexdobin/STAR/tree/master). Below, for each parameter, the corresponding parameter in [STARsolo](https://github.com/alexdobin/STAR/tree/master), description, and the default value in NovaScope are provided.

     | Parameter         | `STARsolo` parameter           | Description                                                                        | Default Value     |
     |-------------------|--------------------------------|------------------------------------------------------------------------------------|-------------------|
     | `len_sbcd`        | `--soloCBlen`                  | The cell barcode length                                                            | 30                |
     |                   | `--soloUMIstart`               | Defined as `len_sbcd + 1`, this indicates UMI sequence (randomer) start base.      | 31                |
     | `len_umi`         | `--soloUMIlen`                 | The length of UMI sequence (randomer) start base.                                  | 9                 |
     | `min_match_len`   | `--outFilterMatchNmin`         | An alignment is only output if the count of matched bases >= this value.           | 30                |
     | `min_match_frac`  | `--outFilterMatchNminOverLread`| Similar to `min_match_len`, normalized to the read length                          | 0.66              |

* **The `exist_action` Parameter**

     The `exist_action` parameter within `align` provides two choices for handling existing intermediate or output files: "`skip`" tells NovaScope to bypass these files, whereas "`overwrite`" instructs NovaScope to replace them.

* **The `resource` Parameter**

     The `resource` parameters, specific to HPC users, determine the partitions, CPU count, and memory allocation for the alignment process. Details for the `resource` parameters in `align` are provided in the [`upstream` parameters](../../basic_usage/job_config.md/#upstream) in [Job Configuration](../../basic_usage/job_config.md).

     *  `assign_type`: two available options for how NovaScope allocates resources for alignment. The options include `"stdin"` (recommended) and `"filesize"`. Details for each option are provided in the blocks below. 
     * ??? note "Option `stdin`"
          **Advantages:**
          - Directly allocates resources as specified in the `stdin` field, bypassing calculations for precision in resource management.
          - Enables customization of resources for different datasets in the job configuration file, allowing for optimization of costs based on file size.
          **Disadvantages:**
          - Requires users to specify resources for each job unless default settings (partition name, threads, memory) fit the computing environment. An example is provided in the [template](#a-template-of-the-config-file).

     * ??? note "Option `filesize`"
          **Advantages:**
          - Automatically allocates resources based on the total size of input 2nd-seq FASTQ files and specified computing resources in the [environment configuration file](../../installation/env_setup.md).
          - Once computing resources are specified in the environment file, they automatically apply to all jobs, simplifying the setup.
          **Disadvantages:**
          - Requires computing time to calculate the total size of input files, potentially delaying the start of data processing.

            The resource allocation strategy is as follows:

            | Total File Size (GB) | Memory Allocated for Alignment (GB) |
            |----------------------|-------------------------------------|
            | Under 200            | 70                                  |
            | 200 to 400           | 140                                 |
            | Over 400             | 330                                 |
     
## Dependencies
Rule `align` requires the matched spatial barcode files from Rule [`smatch`](./smatch.md) generates. Hence, if the [input files](#input-files) are not available, `align` relies on the successful completion of [`smatch`](./smatch.md) for proper operation. See an overview of the rule dependencies in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet
The code for this rule is provided in [a04_align.smk](https://github.com/seqscope/NovaScope/blob/main/rules/a04_align.smk)
