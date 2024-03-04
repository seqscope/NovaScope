import os, sys, gzip, argparse, subprocess, random
from utils import read_maybe_gzip, check_iupac, revcomp

parser = argparse.ArgumentParser(description="Process 1st-seq FASTQ to build spatial barcodes")
parser.add_argument("--fq", type=str, required=True, help="FASTQ file")
parser.add_argument("--format", type=str, default="DraI32", help="Expected format of HDMI barcode")
parser.add_argument("--platform", type=str, default="Illumina", help="Expected format of platform to parse the readnames of the FASTQ files")
parser.add_argument("--force-lane", type=int, default=0, help="Force the lane number (only for Salus platforms)")
parser.add_argument("--out", type=str, required=True, help="Output directory name to store output")
parser.add_argument("--tmpdir", type=str, default="/tmp", help="Temporary directory to sort the file")
parser.add_argument("--sortmem", type=str, default="5G", help="Max memory to use for sorting")
parser.add_argument("--spatula", type=str, default="spatula", help="Path to spatula binary")
parser.add_argument("--gzip", type=str, default="gzip", help="Binary of gzip (e.g. you can replace it with pigz -p 10)")
parser.add_argument("--skip-sort", action="store_true", default=False, help="skip sorting process")
args = parser.parse_args()

lt2fh = {}
lt2cnts = {}

## create directory
if os.path.exists(args.out):
    print(f"WARNING: Writing files to the existing folder {args.out}. Files may be overwritten..", file=sys.stderr)
else:
    os.makedirs(args.out)

if args.platform.startswith("Salus"):
    if args.force_lane == 0:
        raise ValueError(f"Positive value for --force-lane is required for --platform {args.platform}")

optional_arg = ""
if args.force_lane > 0:
    optional_arg += f" --force-lane {args.force_lane}"
cmd = f"{args.spatula} build-sbcds --fq {args.fq} --out {args.out} --format {args.format} --platform {args.platform}{optional_arg}"
res = subprocess.run(cmd, shell=True)
if res.returncode != 0:
    raise OSError(f"Error in running command {cmd}")
    
if not args.skip_sort:
    print(f"Sorting each tile individually", file=sys.stderr)
    with open(f"{args.out}/manifest.tsv","rt",encoding='utf-8') as fh:
        hdr = fh.readline()
        for line in fh:
            toks = line.rstrip().split('\t')
            lt = toks[0]
            print(f"Processing {toks[0]}", file=sys.stderr)       
            cmd = f"sort -T {args.tmpdir} -S {args.sortmem} {args.out}/{lt}.sbcds.unsorted.tsv | {args.gzip} -c > {args.out}/{lt}.sbcds.sorted.tsv.gz"
            res = subprocess.run(cmd, shell=True)
            if res.returncode != 0:
                raise OSError(f"Error in running command {cmd}")
            os.remove(f"{args.out}/{lt}.sbcds.unsorted.tsv")

    print("Finished sorting all tiles");
else:
    print("Skipped sorting all tiles");
