# mark
#=============================================
#
# 1. Import functions and env
#
#==============================================

# Import modules
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
from bricks import check_input, check_path, create_dict, create_symlink, create_dirs_and_get_paths
from bricks import list_outputfn_by_request

# Set up display and log
configure_pandas_display()

setup_logging(job_dir,smk_name+"-preprocess")

logging.info(f"1. Reading input:")
logging.info(f" - Current job path: {job_dir}")

# Config
logging.info(f" - Loading config files.")
config_files = [
    ("config_job.yaml", True),              # True indicates this file is required
]
config = load_configs(job_dir, config_files)

# Env
env_dir=config.get("env", os.path.join(smk_dir, "env"))
if not os.path.exists(env_dir):
    raise ValueError(f"The environment path ({env_dir}) does not exist. Please provide a valid environment path in the config file or create a environment directory within the pipeline directory.")

logging.info(f" - Environment path: {env_dir}")

# - ref 
ref_dir   = os.path.join(env_dir, "ref")

# - python env (py3.10 and py3.9)
py310_env = os.path.join(env_dir,   "pyenv", "py310")
py310     = os.path.join(py310_env, "bin",   "python")
py39_env  = os.path.join(env_dir,   "pyenv", "py39")
py39      = os.path.join(py39_env,  "bin",   "python")

# - tools
spatula   = os.path.join(env_dir, "tools", "spatula")
samtools  = os.path.join(env_dir, "tools", "samtools")
star      = os.path.join(env_dir, "tools", "star")

#==============================================
#
# 2. basic config
#
#==============================================
logging.info(f"\n")
logging.info(f"2. Processing Config files.")

# Output
main_root = config["output"]
main_dirs = create_dirs_and_get_paths(main_root, ["seq1st", "seq2nd", "align", "histology"])
logging.info(f" - Output root: {main_root}")

# Flowcell
flowcell = config["input"]["flowcell"]
assert flowcell is not None, "Provide a valid Flowcell."
logging.info(f" - Flowcell: {flowcell}")

# Section
section = config["input"]["section"]
assert section is not None, "Provide a valid Section."
logging.info(f" - Section: {section}")

# Specie
specie = check_input(config["input"]["specie"], {"human","human_mouse","mouse","rat","worm"}, "specie", lower=False)
logging.info(f" - Specie: {specie}")

# Request
request=check_input(config.get("request",["nge-per-section"]),{"nge-per-section","hist-per-section"}, "request", lower=False)
logging.info(f" - Request: {request}")

# Label: if not provided, use specie as label, else use {specie}_{label}
label = config["input"].get("label", None)
label = f"{specie}_{label}" if label is not None else specie
logging.info(f" - Label: {label}")

# Seq1 
logging.info(f" - Seq1")

df_seq1 = pd.DataFrame({
    'flowcell': [flowcell],
    'section': [section],
    'seq1_prefix': [config.get('input', {}).get('seq1st', {}).get('prefix', pd.NA)],
    'seq1_fq_raw': [config.get('input', {}).get('seq1st', {}).get('fastq', pd.NA)],
})

if pd.isna(df_seq1["seq1_prefix"]).any():
    df_seq1["lane"] = config.get('input', {}).get('lane', {"A": "1", "B": "2", "C": "3", "D": "4"}.get(section[-1], pd.NA))
    if pd.isna(df_seq1["lane"]).any():
        raise ValueError("There are sections missing lane.")
    df_seq1["seq1_prefix"] = df_seq1["seq1_prefix"].fillna("L" + df_seq1["lane"].astype(str)) # Prefix, imputed by lane

df_seq1['seq1_fq_raw'] = df_seq1['seq1_fq_raw'].apply(lambda x: check_path(x, job_dir)) # Check path for each fastq file and update the path when it is a relative path. 

sc2seq1     = create_dict(df_seq1, key_col="section", val_cols="seq1_prefix", dict_type="val", val_type="str")

logging.info("     Seq1 input summary table:\n%s", df_seq1)

# Seq2
logging.info(f" - Seq2")
df_seq2 = pd.DataFrame({
    'flowcell': flowcell,
    'section': section,
    'seq2_prefix': [seq2.get('prefix') for seq2 in config.get('input', {}).get('seq2nd', [])],
    'seq2_fqr1_raw': [check_path(seq2.get('fastq_R1'), job_dir) for seq2 in config.get('input', {}).get('seq2nd', [])],
    'seq2_fqr2_raw': [check_path(seq2.get('fastq_R2'), job_dir) for seq2 in config.get('input', {}).get('seq2nd', [])],
    "specie_with_seq2v": label
})

sc2seq2 = create_dict(df_seq2, key_col="section", val_cols="seq2_prefix",  dict_type="set", val_type="str")

logging.info("     Seq2 input summary table:\n%s", df_seq2)

# STD fq files 
if "nge-per-section" in request:
    logging.info(f" - Standardzing fastq file names.")

    logging.info("     Creating symlinks to standardize the file names for seq1.")
    df_seq1["seq1_fq_std"] = df_seq1.apply(lambda row: os.path.join(main_dirs["seq1st"], row["flowcell"], "fastqs", row["seq1_prefix"]+".fastq.gz"), axis=1)
    for _, row in df_seq1.iterrows():
        os.makedirs(os.path.dirname(row["seq1_fq_std"]), exist_ok=True)
        create_symlink(row["seq1_fq_raw"], row["seq1_fq_std"],silent=True)

    logging.info("     Creating symlinks to standardize the file names for seq2.")
    df_seq2["seq2_fqr1_std"]=df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_prefix"], row["seq2_prefix"]+".R1.fastq.gz"), axis=1)
    df_seq2["seq2_fqr2_std"]=df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_prefix"], row["seq2_prefix"]+".R2.fastq.gz"), axis=1)
    for _, row in df_seq2.iterrows():
        os.makedirs(os.path.dirname(row["seq2_fqr1_std"]), exist_ok=True)
        create_symlink(row["seq2_fqr1_raw"], row["seq2_fqr1_std"],silent=True)
        create_symlink(row["seq2_fqr2_raw"], row["seq2_fqr2_std"],silent=True)

    # prepare the layout file for rgb figure if it is not provided.
    rgb_layout=check_path(config.get("preprocess", {}).get("dge2sdge", {}).get('layout', "layout.1x1.tsv"), job_dir, strict_mode=False)
    if rgb_layout is None:
        rgb_layout=os.path.join(job_dir,"layout.1x1.tsv")
        with open(rgb_layout, "w") as f:
            f.write("lane\ttile\trow\tcol\n")
            f.write(f"1\t1\t1\t1\n")
    assert os.path.exists(rgb_layout), f"Please provide a valid layout file for rgb figure at {rgb_layout}."
else:
    rgb_layout=None

# Histology
# std dir
hist_std_dir = os.path.join(main_dirs["histology"], flowcell, section, specie)

# std fn, e.g. 10XN3-B09A-human-hne.tif
hist_res = config.get("histology",{}).get("resolution","10")
flowcell_abbr = config.get("input",{}).get("flowcell").split("-")[0]
hist_type = check_input(config.get("histology",{}).get("figtype","hne"), ["hne","dapi","fl"], "Histology figure type")
hist_std_fn = f"{hist_res}X{flowcell_abbr}-{section}-{specie}-{hist_type}.tif"

if "hist-per-section" in request:
    
    logging.info(f" - Histology file: Loading")
    os.makedirs(hist_std_dir, exist_ok=True)    

    hist_std_tif = os.path.join(hist_std_dir, hist_std_fn)
    hist_raw_tif = check_path(config.get("input",{}).get('histology', None), job_dir, strict_mode=False) # Update the path when it is a relative path, and return None if it is not provided.

    if hist_raw_tif is not None: # If histology file is provided, create a symlink to the standard folder.
        logging.info(f"     Histology file: {os.path.realpath(hist_raw_tif)}")
        create_symlink(hist_raw_tif, hist_std_tif, handle_existing_output="replace", silent=True)
    elif os.path.exists(hist_std_tif): # When not provided, check if the standard file exists.
        logging.info(f"     Histology file: {os.path.realpath(hist_std_tif)}")
    else:
        raise ValueError(f"Please provide a valid histology file.")

else:
    hist_std_tif=None
    logging.info(f" - Histology file: Skipping.")

#hist_request = lambda: "hist-per-section" in request
#==============================================
#
# 3. A dummy rule to collect results
#
# - Please note that The order of results affects the order of execution.
#
#==============================================
logging.info(f"\n")
logging.info(f"3. Required output filenames.")

output_filename_conditions = [
    # nge-per-section
    {
        'flag': 'nge-per-section',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "barcodes.tsv.gz"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "features.tsv.gz"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".gene_full_mito.png"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".sge_match_sbcd.png"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".gene_visual.tar.gz"], None),
                                #(["{flowcell}", "{section}", "histology", "{specie_with_seq2v}", hist_std_tif], hist_request),
        ],
        'zip_args': {
            'flowcell':         df_seq1["flowcell"].values,
            'section':          df_seq1["section"].values,
            'specie_with_seq2v': df_seq2["specie_with_seq2v"].values,  
            #'hist_std_tif':     hist_std_tif,     
        },
    },
    # hist-per-section
    {
        'flag': 'hist-per-section',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{section}", "histology", "{specie_with_seq2v}", hist_std_fn], None),
        ],
        'zip_args': {
            'flowcell':         df_seq1["flowcell"].values,
            'section':          df_seq1["section"].values,
            'specie_with_seq2v': df_seq2["specie_with_seq2v"].values,  
            'hist_std_tif':     hist_std_fn,          
        },
    }
]

requested_files=list_outputfn_by_request(output_filename_conditions, request, debug=True)

rule all:
    input:
        requested_files

end_logging()

#==============================================
#
# 4. include all rules here
#
#==============================================

include: "rules/a01_fastq2sbcd.smk"
include: "rules/a02_sbcd2nbcd.smk"
include: "rules/a03_nmatch.smk"
include: "rules/a04_align.smk"
include: "rules/a05_dge2sdge.smk"

include: "rules/b01_gene_visual.smk"

if "hist-per-section" in request:
    include: "rules/b02_hist_align.smk"

