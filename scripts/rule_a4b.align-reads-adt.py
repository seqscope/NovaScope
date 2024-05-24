import os, sys, gzip, argparse, subprocess, random, shutil
from utils import read_maybe_gzip, check_iupac, revcomp

match_suffix = "match.tsv.gz"
match_uniq_suffix = "match.sorted.uniq.tsv.gz"
fq1_suffix = "R1.fastq.gz"
fq2_suffix = "R2.fastq.gz"

parser = argparse.ArgumentParser(description="Match ADT tags and build spatial DGEs")
key_params = parser.add_argument_group("Input/Output Files", "Key Input/Output Parameters")
key_params.add_argument("--tsv", type=str, required=False, help="Input tsv file containing FASTQ1, FASTQ2, smatch (optional) output")
key_params.add_argument("--tag", type=str, required=False, help="Input tsv file that contains ADT tag info")
key_params.add_argument("--sbcd", type=str, required=False, help="Directory containing sbcd output")
key_params.add_argument("--out", type=str, required=True, help="Output prefix to store output")

act_params = parser.add_argument_group("Actions to enable", "Actions to enables (opt-in to enable)")
act_params.add_argument("--match-tag", action="store_true", default=False, help="Perform matching tags")
act_params.add_argument("--search-tag", action="store_true", default=False, help="Perform searching tags")
act_params.add_argument("--merge-dge", action="store_true", default=False, help="Merge matched tags DGE")
act_params.add_argument("--build-sge", action="store_true", default=False, help="Build spatial DGE")
act_params.add_argument("--keep-temp", action="store_true", default=False, help="Keep temporary files")

aux_params = parser.add_argument_group("Auxilary Parameters", "Auxilary Parameters (default recommended, modify at yown risk)")
aux_params.add_argument("--bcd-pos", type=str, required=False, help="Barcode position")
aux_params.add_argument("--tag-pos", type=str, required=False, help="Tag position")
aux_params.add_argument("--umi-pos", type=str, required=False, help="UMI position (skip if UMI does not exist)")

aux_params.add_argument("--spatula", type=str, default="spatula", help="Path to spatula binary")
aux_params.add_argument("--gzip", type=str, default="gzip", help="Binary of gzip (e.g. you can replace it with pigz -p 10)")
aux_params.add_argument("--tmpdir", type=str, default="/tmp", help="Temporary directory to sort the file")
aux_params.add_argument("--sortmem", type=str, default="5G", help="Max memory to use for sorting")
aux_params.add_argument("--batch-size", type=int, default=10000000, help="Batch size in --write-match")

args = parser.parse_args()

## input sanity checking
if not (args.match_tag or args.search_tag or args.merge_dge or args.build_sge):
    raise ValueError("At least one of --match-tag, --search-tag, --merge-dge, and --build-sge parameters must be enabled")

if args.merge_dge and args.bcd_pos is None:
    raise ValueError("--bcd-pos is required with --match_tag or search_tag parameters")

if args.match_tag and args.tag_pos is None:
    raise ValueError("--tag-pos is required with --match_tag parameters")

if ( args.match_tag or args.search_tag or args.merge_dge ) and ( args.tag is None or args.tsv is None ):
    raise ValueError("--tag and --tsv option is required with --match_tag, --search_tag or --merge_dge parameters")

if ( args.match_tag and args.search_tag ):
    raise ValueError("--match_tag and --search_tag are exclusive options and cannot be used together.")

fqs = []
num_smatch = 0
if args.tsv is not None:
    with open(args.tsv, 'rt', encoding='utf-8') as fh:
        for line in fh:
            toks = line.rstrip().split()
            fqs.append([toks[0], toks[1], toks[2] if len(toks) > 2 else None])
            if len(toks) > 2:
                num_smatch += 1
if num_smatch == len(fqs): ## smatch exists
    if args.sbcd is not None:
        raise ValueError("--sbcds cannot be used when --tsv contains smatch files")
elif num_smatch == 0:
    if args.build_sge and args.sbcd is None:
        raise ValueError("--sbcd option is required with --build_sge parameters when --smatch is not provided")
#print(fqs, file=sys.stderr)

matchdir = args.out + "/match"
dgedir = args.out + "/dge"
if args.match_tag or args.search_tag:
    print("Starting --match-tag option..", file=sys.stderr);
    os.makedirs(matchdir, exist_ok=True)    
    for i in range(len(fqs)):
        options = []
        if args.umi_pos is not None:
            options.append(f"--umi-pos {args.umi_pos}")
        if fqs[i][2] is not None:
            options.append(f"--smatch {fqs[i][2]}")
        if args.match_tag:
            cmd = f"{args.spatula} match-tag --fq1 {fqs[i][0]} --fq2 {fqs[i][1]} --out {matchdir}/{i} --bcd-pos {args.bcd_pos} --tag-pos {args.tag_pos} --batch {args.batch_size} --tag {args.tag} " + " ".join(options)
        else:
            cmd = f"{args.spatula} search-tag --fq1 {fqs[i][0]} --fq2 {fqs[i][1]} --out {matchdir}/{i} --bcd-pos {args.bcd_pos} --batch {args.batch_size} --tag {args.tag} " + " ".join(options)
        res = subprocess.run(cmd, shell=True)
        if res.returncode != 0:
            raise OSError(f"Error in running command {cmd}")

        ## read the manifest file
        with open(f"{matchdir}/{i}.unsorted.manifest.tsv", 'rt', encoding='utf-8') as fh:
            with open(f"{matchdir}/{i}.sorted.manifest.tsv", 'wt', encoding='utf-8') as wh:
                for line in fh:
                    infile = line.rstrip()
                    outfile = infile.replace(".unsorted.tsv",".sorted.tsv.gz")
                    wh.write(outfile + "\n")
                    print(f"Sorting {infile} and writing {outfile} ", file=sys.stderr)
                    cmd = f"/bin/bash -c 'set -o pipefail; sort -T {args.tmpdir} -S {args.sortmem} {infile} | {args.gzip} -c > {outfile}'"
                    res = subprocess.run(cmd, shell=True)
                    if res.returncode != 0:
                        raise OSError(f"Error in running command {cmd}")
                    os.remove(infile)
    print("Finishing --write-match option..", file=sys.stderr)

if args.merge_dge:
    print("Starting --merge-matched-tag option..", file=sys.stderr);
    with open(f"{matchdir}/merged.sorted.manifest.tsv", 'wt', encoding='utf-8') as wh:    
        for i in range(len(fqs)):
            with open(f"{matchdir}/{i}.sorted.manifest.tsv", 'rt', encoding='utf-8') as fh:
                for line in fh:
                    wh.write(line)

    cmd = f"{args.spatula} merge-matched-tags --list {matchdir}/merged.sorted.manifest.tsv --tag {args.tag} --out {dgedir}"
    res = subprocess.run(cmd, shell=True)
    if res.returncode != 0:
        raise OSError(f"Error in running command {cmd}")
    print("Finished --merge-matched-tag option..", file=sys.stderr)

if args.build_sge:
    print("Starting --build-sge option..", file=sys.stderr)
    cmd = f"{args.spatula} dge2sdge --bcd {dgedir}/barcodes.tsv.gz --ftr {dgedir}/features.tsv.gz --mtx {dgedir}/umis.mtx.gz --mtx {dgedir}/reads.mtx.gz --mtx {dgedir}/pixels.mtx.gz --n-mtx-cols 5 --out {args.out}"
    if num_smatch == 0:
        cmd += (" --sbcd " + args.sbcd)
    else:
        for i in range(len(fqs)):
            if fqs[i][2] is not None:
                cmd += (" --match " + fqs[i][2])
    res = subprocess.run(cmd, shell=True)
    if res.returncode != 0:
        raise OSError(f"Error in running command {cmd}")
    if not args.keep_temp:
        print(f"Removing intermediate directory {matchdir}", file=sys.stderr)
        shutil.rmtree(matchdir)
        print(f"Removing intermediate directory {dgedir}", file=sys.stderr)
        shutil.rmtree(dgedir)    
    print("Finished --build-sge option..", file=sys.stderr)
print("Analysis Finished", file=sys.stderr);
