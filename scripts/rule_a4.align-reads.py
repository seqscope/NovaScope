import os, sys, gzip, argparse, subprocess, random, glob
from utils import read_maybe_gzip, check_iupac, revcomp

star_default_options= "--limitOutSJcollapsed 5000000 --soloCellFilter None --soloBarcodeReadLength 0 --outFilterScoreMinOverLread 0 --outSAMtype BAM SortedByCoordinate --soloType CB_UMI_Simple --soloCBstart 1"
match_uniq_suffix = "match.sorted.uniq.tsv.gz"
default_star_indices = {"mouse" : "/nfs/turbo/sph-hmkang/ref/cellranger/refdata-gex-mm10-2020-A/star_2_7_10a",
                        "human" : "/nfs/turbo/sph-hmkang/ref/cellranger/refdata-gex-GRCh38-2020-A/star_2_7_10a",
                        "human_mouse" : "/nfs/turbo/sph-hmkang/ref/cellranger/refdata-gex-GRCh38-and-mm10-2020-A/star_2_7_10a",
                        "rat" : "/nfs/turbo/sph-hmkang/ref/cellranger/refdata-gex-mRatBN7-custom/star_2_7_10a/"}
whitelist_suffix = ".whitelist.txt"
fifo_R1_suffix = ".R1.fq"
fifo_R2_suffix = ".R2.fq"

parser = argparse.ArgumentParser(description="Align spatially barcoded mRNA reads with STARsolo")
key_params = parser.add_argument_group("Input/Output Files", "Key Input/Output Parameters")
key_params.add_argument("--fq1", type=str, nargs='+', required=True, help="FASTQ file (Read 1)")
key_params.add_argument("--fq2", type=str, nargs='+', required=True, help="FASTQ file (Read 2)")
key_params.add_argument("--out", type=str, required=True, help="Output directory to store the output files")
key_params.add_argument("--prefix", type=str, default="sttools", help="Prefix of output files generated by STARsolo")
key_params.add_argument("--whitelist-sbcd", type=str, required=False, help="Use whitelist from sbcd directory")
key_params.add_argument("--whitelist-match", type=str, nargs='*', required=False, help="Use whitelist from match file")
key_params.add_argument("--filter-match", type=str, nargs='*', required=False, help="Filter FASTQs based on match file")
key_params.add_argument("--star-index", type=str, required=True, help="STAR genome index file")

aln_params = parser.add_argument_group("Aligner options", "Key actions to decide for alignment")
aln_params.add_argument("--run-dir-perm", type=str, default="User_RWX", help="Directory permission of output file")
aln_params.add_argument("--threads", type=int, default=6, help="Number of threads to be used for STARsolo aligner")
aln_params.add_argument("--sam-attr", type=str, default="NH HI nM AS CR UR CB UB GX GN sS sQ sM", help="--outSAMsttributes parameter for STARsolo aligner")
aln_params.add_argument("--clip3p-seq", type=str, default="polyA", help="--clip3pAdapterSeq parameter for STARsolo aligner")
aln_params.add_argument("--clip3p-mmp", type=float, default=0.1, help="--clip3pAdapterMMp parameter for STARsolo aligner")
aln_params.add_argument("--solo-features", type=str, default="Gene GeneFull SJ Velocyto", help="--soloFeatures parameter for STARsolo aligner")
aln_params.add_argument("--min-match-len", type=int, default=0, help="--outFilterMatchNmin option as a minimum number of matching bases")
aln_params.add_argument("--min-match-frac", type=float, default=0, help="--outFilterMatchNminOverLread option as a minimum fraction of matching bases")
aln_params.add_argument("--star-add-options", type=str, help="Additional options to add to STARsolo alignment")
aln_params.add_argument("--star-bin", type=str, default="/nfs/turbo/sph-hmkang/bin/STAR_2_7_10a_v3", help="STAR binary path")

aux_params = parser.add_argument_group("Auxilary Parameters", "Auxilary Parameters (default recommended, modify at your own risk)")
aux_params.add_argument("--spatula", type=str, default="spatula", help="Path to spatula binary")
aux_params.add_argument("--samtools", type=str, default="samtools", help="Path to samtools binary")
aux_params.add_argument("--gzip", type=str, default="gzip", help="Binary of gzip (e.g. you can replace it with pigz -p 10)")
aux_params.add_argument("--match-len", type=int, default=27, help="Length of spatial barcode considered to be a perfect match (max is 27)")
aux_params.add_argument("--skip-sbcd", type=int, default=0, help="Skip first bases in spatial barcode (in Read 1) to be copied to output FASTQ file (Read 1)")
aux_params.add_argument("--len-sbcd", type=int, default=30, help="Length of spatial barcode (in Read 1) to be copied to output FASTQ file (Read 1)")
aux_params.add_argument("--len-umi", type=int, default=9, help="Length of UMI barcode (in Read 2) to be copied to output FASTQ file (Read 1)")
aux_params.add_argument("--len-r2", type=int, default=101, help="Length of read 2 after trimming (including randomers)")
aux_params.add_argument("--tmpdir", type=str, default="/tmp", help="Temporary directory to sort the file")
aux_params.add_argument("--sortmem", type=str, default="5G", help="Max memory to use for sorting")
aux_params.add_argument("--batch-size", type=int, default=300000000, help="Batch size in --write-match")
aux_params.add_argument("--skip-existing", action='store_true', default=False, help="Skip rerunning command if the output file already exists")
aux_params.add_argument("--overwrite-existing", action='store_true', default=False, help="Overwrite the output file if it already exists")
aux_params.add_argument("--keep-temp-files", action='store_true', default=False, help="Keep intermediate files for debugging purpose")

args = parser.parse_args()

## function definitons
## Update: added a overwriteFlag
def execute_with_flag(cmd, outfile, skipFlag=False, overwriteFlag=False):
    file_exists = os.path.exists(outfile)
    if skipFlag and file_exists:
        action = "Skipping"
    elif overwriteFlag and file_exists:
        action = "Overwriting"
        os.remove(outfile)
    else:
        action = "Executing" 
    print(f"{action} command: {cmd}\nOutput file: {outfile}", file=sys.stderr)
    if action != "Skipping":
        res = subprocess.run(cmd, shell=True)  
        if res.returncode != 0: # Or use `check=True` in subprocess.run to automatically raise an exception on non-zero returncode.
            raise OSError(f"Error in running command {cmd}")

## function definitons
def make_whitelist_from_match(matchf, outf):
    if len(matchf) == 1:
        cmd = f"/bin/bash -c 'set -o pipefail; {args.gzip} -cd {matchf[0]} | cut -c 1-{args.len_sbcd} | uniq > {outf}'"
        execute_with_flag(cmd, outf, args.skip_existing, args.overwrite_existing)    
    elif len(matchf) > 0:
        matchfs = " ".join(matchf)
        cmd = f"/bin/bash -c 'set -o pipefail; {args.gzip} -cd {matchfs} | cut -c 1-{args.len_sbcd} | sort -T {args.tmpdir} -S {args.sortmem} | uniq > {outf}'"
        execute_with_flag(cmd, outf, args.skip_existing, args.overwrite_existing)    
    else:
        raise ValueError(f"Cannot process {matchf}")

## function definitons
def make_whitelist_from_sbcd(sbcdf, outf):
    if os.path.exists(outf): ## if the file exists, remove first
        if args.keep_temp_files:
            print(f"WARNING: Output file {outf} exists. Overwriting it..", file=sys.stderr)
        else:
            os.remove(outf)
    with open(f"{sbcdf}/manifest.tsv","rt",encoding='utf-8') as fh:
        hdrs = fh.readline().rstrip().split('\t')
        icol = -1
        for (i, v) in enumerate(hdrs):
            if v == "filepath":
                icol = i
                break
        if icol < 0:
            raise ValueError(f"Cannot find filepath column in {sbcdf}/manifest.tsv")
        if args.skip_existing and os.path.exists(outf):
            print("Skipping the following command because output file {outfile} exitsts:\n{cmd}", file=sys.stderr)
        else:
            for line in fh:
                toks = line.rstrip().split('\t')
                filepath = toks[icol]
                print(f"Processing {sbcdf}/{filepath}...", file=sys.stderr)
                cmd = f"/bin/bash -c 'set -o pipefail; {args.gzip} -cd {sbcdf}/{filepath} | cut -c 1-{args.len_sbcd} >> {outf}'"
                execute_with_flag(cmd, outf, False, False)

## sanity checking on the input files
if len(args.fq1) != len(args.fq2):
    raise ValueError("The number of --fq1 and --fq2 inputs do not match")

if args.whitelist_match is not None and len(args.whitelist_match) > 0 and len(args.whitelist_match) != len(args.fq1):
    raise ValueError("--whitelist-match is expected for each FASTQ file")

if args.filter_match is not None and len(args.filter_match) > 0 and len(args.filter_match) != len(args.fq1):
    raise ValueError("--filter-match is expected for each FASTQ file")

## create directory
if os.path.exists(args.out):
    print(f"WARNING: Writing files to the existing folder {args.out}. Files may be overwritten..", file=sys.stderr)
else:
    os.makedirs(args.out)

## produce whitelist
outprefix = os.path.join(args.out, args.prefix)
if args.keep_temp_files:
    print(f"WARNING: Keeping intermediate files for debugging purpose..", file=sys.stderr)
else:
    if os.path.exists(f"{outprefix}{fifo_R1_suffix}"):
        os.remove(f"{outprefix}{fifo_R1_suffix}")
    if os.path.exists(f"{outprefix}{fifo_R2_suffix}"):
        os.remove(f"{outprefix}{fifo_R2_suffix}")    

## Write whitelist file    
if args.whitelist_sbcd is not None:
    if args.whitelist_match is not None and len(args.whitelist_match) > 0:
        raise ValueError("Only one of --whitelist-sbcd or --whitelist-match parameter is required")
    else: ## whitelist-match is available
        ## make whitelist from args.sbcd
        make_whitelist_from_sbcd(args.whitelist_sbcd, outprefix + whitelist_suffix)
elif args.whitelist_match is not None and len(args.whitelist_match) > 0: ## whitelist-match is available
    ## make whitelist from args.match
    make_whitelist_from_match(args.whitelist_match, outprefix + whitelist_suffix)
else:
   raise ValueError("Either --whitelist-sbcd or --whitelist-match parameter is required")    
    
## perform STARsolo alignment with pipe
fq1s = " ".join(args.fq1)
fq2s = " ".join(args.fq2)

## command to write FASTQ files
cmd_writefq = f"{args.spatula} reformat-fastqs --fq1 <({args.gzip} -cd {fq1s}) --fq2 <({args.gzip} -cd {fq2s}) --skip-sbcd {args.skip_sbcd} --len-match {args.match_len} --len-sbcd {args.len_sbcd} --len-umi {args.len_umi} --len-r2 {args.len_r2} --out1 {outprefix}{fifo_R1_suffix} --out2 {outprefix}{fifo_R2_suffix}"
if args.filter_match is not None and len(args.filter_match) > 0:
    for matchf in args.filter_match:
        cmd_writefq += f" --match-tsv {matchf}"

execute_with_flag(f"/bin/bash -c '{cmd_writefq}'", f"{outprefix}{fifo_R1_suffix}", args.skip_existing, args.overwrite_existing)

## command to align with STARsolo
cmd_star = f"{args.star_bin} --genomeDir {args.star_index} --readFilesIn {outprefix}{fifo_R2_suffix} {outprefix}{fifo_R1_suffix} --runDirPerm {args.run_dir_perm} --outFileNamePrefix {outprefix} --soloCBlen {args.len_sbcd} --soloUMIstart {args.len_sbcd+1} --soloUMIlen {args.len_umi} --soloCBwhitelist {outprefix}{whitelist_suffix} --runThreadN {args.threads} --outSAMattributes {args.sam_attr} --clip3pAdapterSeq {args.clip3p_seq} --clip3pAdapterMMp {args.clip3p_mmp} --soloFeatures {args.solo_features} --outFilterMatchNmin {args.min_match_len} --outFilterMatchNminOverLread {args.min_match_frac} {star_default_options}"
if args.star_add_options is not None:
    cmd_star += f" {args.star_add_options}"

execute_with_flag(cmd_star, f"{outprefix}Aligned.sortedByCoord.out.bam", args.skip_existing, args.overwrite_existing)

## command to index the BAM file
cmd_bai = f"{args.samtools} index -@ {args.threads} {outprefix}Aligned.sortedByCoord.out.bam"
execute_with_flag(cmd_bai, f"{outprefix}Aligned.sortedByCoord.out.bam.bai", args.skip_existing, args.overwrite_existing)

## command to gzip the output files
cmd_gzip = "ls %sSolo.out/*/raw/*.{mtx,tsv} | grep -v SJ/raw/feature | xargs -I {} -P %d gzip -f {}" % (outprefix, args.threads)
execute_with_flag(f"/bin/bash -c '{cmd_gzip}'", f"{outprefix}Solo.out/Gene/raw/matrix.mtx.gz", args.skip_existing, args.overwrite_existing)

if not args.keep_temp_files:
    os.remove(f"{outprefix}{fifo_R1_suffix}")
    os.remove(f"{outprefix}{fifo_R2_suffix}")
    os.remove(f"{outprefix}{whitelist_suffix}")

print("Analysis Finished", file=sys.stderr)