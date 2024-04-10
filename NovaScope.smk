#=============================================
#
# import functions and env
#
#==============================================

# import modules
import os, sys, gzip, argparse, subprocess, random, yaml, snakemake, re, logging
import pandas as pd
from collections import defaultdict
from snakemake.io import glob_wildcards, Wildcards
import datetime
import logging.handlers

# snakemake dir and job dir
smk_name="NovaScope"
smk_dir = os.path.dirname(workflow.snakefile)  
#smk_dir="/nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope"
job_dir = os.getcwd()

local_scripts   = os.path.join(smk_dir,"scripts")
sys.path.append(local_scripts)
from bricks import setup_logging, end_logging, configure_pandas_display, load_configs
from bricks import check_input, check_path, create_dict, create_symlink, create_dirs_and_get_paths, get_last5_from_md5
from bricks import list_outputfn_by_request
from rule_general import assign_resource_for_align, get_envmodules_for_rule
from rule_general import get_skip_sbcd, link_sdge_to_sdgeAR, find_major_axis
from pipe_utils_upstream import read_config_for_runid, read_config_for_unitid, read_config_for_analysis, read_config_for_hist, read_config_for_seq1, read_config_for_seq2

# set up display and log
configure_pandas_display()

setup_logging(job_dir, smk_name+"-preprocess")

logging.info(f"1. Reading input:")
logging.info(f" - Current job path: {job_dir}")

# config: job
logging.info(f" - Loading config file:")
config = load_configs(job_dir, [("config_job.yaml", True)])

# config: env
env_configfile = check_path(config.get("env_yml", os.path.join(smk_dir, "info", "config_env.yaml")),job_dir, strict_mode=True, flag="The environment config file")
env_config = load_configs(None, [(env_configfile, True)])

module_config = env_config.get("envmodules", None)
logging.info(f" - envmodules: ")
logging.info(f"     {module_config}")

# - ref  
sp2alignref = env_config.get("ref", {}).get("align", None)
sp2geneinfo = env_config.get("ref", {}).get("geneinfo", None)

# - python env (py3.10 and py3.9)
pyenv  = env_config.get("pyenv", None)
assert pyenv is not None, "Please provide a valid python environment."
assert os.path.exists(pyenv), f"Python environment does not exist: {pyenv}"

python = os.path.join(pyenv, "bin", "python")
assert os.path.exists(python), f"Python does not exist in your python environment: {python}"

# - tools
spatula  = env_config.get("tools", {}).get("spatula",   "spatula")
samtools = env_config.get("tools", {}).get("samtools",  "samtools")
star     = env_config.get("tools", {}).get("star",      "STAR")
ficture  = env_config.get("tools", {}).get("ficture",   "ficture")

#==============================================
#
# basic config
#
#==============================================

logging.info(f"\n")
logging.info(f"2. Processing config files.")

# output
main_root = config["output"]
assert main_root is not None, "Provide a valid output directory."
main_dirs = create_dirs_and_get_paths(main_root, ["seq1st", "seq2nd", "match", "align", "histology", "analysis"])
logging.info(f" - Output root: {main_root}")

# flowcell
flowcell = config["input"]["flowcell"]
assert flowcell is not None, "Provide a valid Flowcell."
logging.info(f" - Flowcell: {flowcell}")

# chip
chip = config["input"]["chip"]
assert chip is not None, "Provide a valid Section Chip."
logging.info(f" - Section Chip: {chip}")

# species
species = check_input(config["input"]["species"], {"human", "human_mouse", "mouse", "rat", "worm"}, "species", lower=False)
logging.info(f" - Species: {species}")

# request
request=check_input(config.get("request",["sge-per-run"]),
                    {   "sbcd-per-flowcell", 
                        "sbcd-per-chip", "smatch-per-chip", 
                        "align-per-run", "sge-per-run", "hist-per-run", 
                        "segment-per-unit"
                    },
                     "request", lower=False)
logging.info(f" - Request(s): {request}")

#==============================================
#
# Process input
#
#==============================================
logging.info(f"\n")
logging.info(f"3. Processing input by requests.")

output_filename_conditions = []

# per-unit or per-run:
if any(task in request for task in ["align-per-run", "sge-per-run", "hist-per-run", "segment-per-unit"]):
    run_id, rid2seq2 = read_config_for_runid(config, job_dir)

if "segment-per-unit" in request:
    # run ID: to distinguish different input 2nd-seq data for the same flowcell and chip.
    run_id, rid2seq2 = read_config_for_runid(config, job_dir)

    # unit ID: to distinguish the default sge and the sge with manual boundary filtering.
    unit_id, unit_ann, boundary = read_config_for_unitid(config, job_dir, run_id)

    # analysis info (multiple pairs)
    df_analysis, mu_scale = read_config_for_analysis(config, run_id, unit_id)
else:
    df_analysis = pd.DataFrame({
        'run_id': pd.Series(dtype='object'),
        'unit_id': pd.Series(dtype='object'),
        'solofeature': pd.Series(dtype='object'),
        'trainwidth': pd.Series(dtype='int64'),  
        'segmentmove': pd.Series(dtype='int64'), 
    })

if "hist-per-run" in request:
    hist_std_prefix = read_config_for_hist(config, job_dir, main_dirs["histology"])
else:
    hist_std_prefix = None

# per-chip:
# - smatch-per-chip, sbcd-per-chip (and above)
if any(task in request for task in ["smatch-per-chip", "sbcd-per-chip", "align-per-run", "sge-per-run", "hist-per-run", "segment-per-unit"]):
    # seq2 info (multiple pairs)
    df_seq2 = read_config_for_seq2(config, job_dir, log_option=True)
else:
    df_seq2 = pd.DataFrame({
        'flowcell': pd.Series(dtype='object'),
        'chip': pd.Series(dtype='object'),
        'seq2_id': pd.Series(dtype='object'),
    })

# - all requests will need seq1 info
seq1_id, seq1_fq_raw, sc2seq1 = read_config_for_seq1(config, job_dir)

# STD fq files  (TO-DO: do this only when the std file is needed)
logging.info(f" - Standardzing fastq file names.")

logging.info("     Creating symlinks to standardize the file names for seq1.")
seq1_fq_std=os.path.join(main_dirs["seq1st"], flowcell, "fastqs", seq1_id+".fastq.gz")
os.makedirs(os.path.dirname(seq1_fq_std), exist_ok=True)
create_symlink(seq1_fq_raw, seq1_fq_std, silent=True)

logging.info("     Creating symlinks to standardize the file names for seq2.")
df_seq2["seq2_fqr1_std"]=df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_id"], row["seq2_id"]+".R1.fastq.gz"), axis=1)
df_seq2["seq2_fqr2_std"]=df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_id"], row["seq2_id"]+".R2.fastq.gz"), axis=1)
for _, row in df_seq2.iterrows():
    os.makedirs(os.path.dirname(row["seq2_fqr1_std"]), exist_ok=True)
    create_symlink(row["seq2_fqr1_raw"], row["seq2_fqr1_std"],silent=True)
    create_symlink(row["seq2_fqr2_raw"], row["seq2_fqr2_std"],silent=True)

#==============================================
#
# Rule all
#
# - If all variable in the zip_args is a list of one element, it's ok to use the list directly. Otherwise, use a dataframe will be safer to avoid wrong combination.
#   Currently, only the df_seq2 and df_analysis are in the dataframe format.
# - Please note that The order of results affects the order of execution.
#
#==============================================

logging.info(f"\n")
logging.info(f"4. Required output filenames.")

output_filename_conditions = [
    # sbcd-per-flowcell
    {
        'flag': 'sbcd-per-flowcell',
        'root': main_dirs["seq1st"],
        'subfolders_patterns': [
                                (["{flowcell}", "sbcds", "{seq1_id}", "manifest.tsv"], None),
        ],
        'zip_args': {
            'flowcell':     [flowcell],
            'seq1_id':      [seq1_id],
        },
    },
    # sbcd-per-chip
    {
        'flag': 'sbcd-per-chip',
        'root': main_dirs["seq1st"],
        'subfolders_patterns': [
                                (["{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.tsv.gz"], None),
                                (["{flowcell}", "nbcds", "{chip}", "manifest.tsv"], None),
                                (["{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.png"], None),
        ],
        'zip_args': {
            'flowcell':      [flowcell],
            'chip':          [chip],
        },
    },
    # smatch-per-chip
    {
        'flag': 'smatch-per-chip',
        'root': main_dirs["match"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.match.sorted.uniq.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.summary.tsv"], None),
                                (["{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.counts.tsv"], None),
                                (["{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.match.png"], None),
        ],
        'zip_args': {
            'flowcell':      df_seq2["flowcell"].values,
            'chip':          df_seq2["chip"].values,
            'seq2_id':       df_seq2["seq2_id"].values,  
        },
    },
    # align-per-run
    {
        'flag': 'align-per-run',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "barcodes.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "features.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Gene",     "raw", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "spliced.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "unspliced.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "ambiguous.mtx.gz"], None),
        ],
        'zip_args': {
            'flowcell':  [flowcell],
            'chip':      [chip],
            'run_id':    [run_id],  
        },
    },
    # sge-per-run
    {
        'flag': 'sge-per-run',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "features.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.gene_full_mito.png"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_match_sbcd.png"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.gene_visual.tar.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.minmax.tsv"], None),
        ],
        'zip_args': {
            'flowcell':  [flowcell],
            'chip':      [chip],
            'run_id':    [run_id],  
        },
    },
    # hist-per-run
    {
        'flag': 'hist-per-run',
        'root': main_dirs["histology"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "aligned", "{run_id}", "{hist_std_prefix}.tif"], None),
                                (["{flowcell}", "{chip}", "aligned", "{run_id}", "{hist_std_prefix}-fit.tif"], None),
        ],
        'zip_args': {
            'flowcell':         [flowcell],
            'chip':             [chip],
            'run_id':           [run_id],  
            'hist_std_prefix':  [hist_std_prefix],
        },
    },
    # segment-per-unit
    {
            'flag': 'segment-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "raw_{seg_nmove}",      "barcodes.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "raw_{seg_nmove}",      "features.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "raw_{seg_nmove}",      "matrix.mtx.gz"  ], None),
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "filtered_{seg_nmove}", "barcodes.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "filtered_{seg_nmove}", "features.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "filtered_{seg_nmove}", "matrix.mtx.gz"  ], None),                              
            ],
            'zip_args': {
                'run_id':       df_analysis["run_id"].values,  
                'unit_id':      df_analysis["unit_id"].values,
                'sf':           df_analysis["solofeature"].values,
                'tw':           df_analysis["trainwidth"].values,
                'seg_nmove':    df_analysis['segmentmove'].values,
            },
    },
]

requested_files=list_outputfn_by_request(output_filename_conditions, request, debug=True)

rule all:
    input:
        requested_files

end_logging()

#==============================================
#
#  Specific rules
#
#==============================================

include: "rules/a01_fastq2sbcd.smk"
include: "rules/a02_sbcd2chip.smk"
include: "rules/a03_smatch.smk"
include: "rules/a04_align.smk"
include: "rules/a05_dge2sdge.smk"
include: "rules/b01_gene_visual.smk"

if "hist-per-run" in request:
    include: "rules/b02_historef.smk"

if "segment-per-unit" in request:
    include: "rules/a06_sdge2sdgeAR.smk"
    include: "rules/a07_sdgeAR_reformat.smk"
    include: "rules/a08_sdgeAR_QC.smk"
    include: "rules/a09_sdgeAR_segment.smk"
