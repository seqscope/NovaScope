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
smk_name="Novascope"
smk_dir = os.path.dirname(workflow.snakefile)  
#smk_dir="/nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope"
job_dir = os.getcwd()

local_scripts   = os.path.join(smk_dir,"scripts")
sys.path.append(local_scripts)
from bricks import setup_logging, end_logging, load_configs, configure_pandas_display, create_symlink, list_outputfn_by_request, create_dirs_and_get_paths, create_dict

configure_pandas_display()

# Set up Log
setup_logging(job_dir,smk_name+"-preprocess")

logging.info(f"1. Reading input:")
logging.info(f" - Current job path: {job_dir}")

# Config
logging.info(f" - Loading config files.")
config_files = [
    ("config_job.yaml", True),      # True  indicates this file is required
]
config = load_configs(job_dir, config_files)

# Env
env_dir=config.get("env", os.path.join(smk_dir, "env"))
if not os.path.exists(env_dir):
    raise ValueError(f"The environment path ({env_dir}) does not exist. Please provide a valid environment path in the config file or create a environment directory within the pipeline directory.")

logging.info(f" - Environment path: {env_dir}")

# - ref 
ref_dir = os.path.join(env_dir, "ref")

# - python env (py3.10 and py3.9)
py310_env = os.path.join(env_dir,   "pyenv", "py310")
py310     = os.path.join(py310_env, "bin",   "python")
py39_env  = os.path.join(env_dir,   "pyenv", "py39")
py39      = os.path.join(py39_env,  "bin",   "python")

# - tools
spatula         = os.path.join(env_dir, "tools", "spatula")
sttools2        = os.path.join(env_dir, "tools", "sttools2")
samtools        = os.path.join(env_dir, "tools", "samtools")
star            = os.path.join(env_dir, "tools", "star")
#cart            = os.path.join(env_dir, "tools", "cart") # Not used?


#==============================================
#
# 2. basic config
#
#==============================================
logging.info(f"\n")
logging.info(f"2. Basic config.")

def create_dirs_and_get_paths(main_dir, sub_dirnames):
    """
    Create subdirectories under the main root directory if they don't exist and return their paths.

    :param main_dir: The main root directory path.
    :param sub_dirnames: A list of subdirectory names to create under the main root.
    :return: A dictionary with subdirectory names as keys and their full paths as values.
    """
    sub_dirpaths = {}
    os.makedirs(main_dir, exist_ok=True)
    for sub_dirname_i in sub_dirnames:
        sub_dir = os.path.join(main_dir, sub_dirname_i)
        os.makedirs(sub_dir, exist_ok=True)
        sub_dirpaths[sub_dirname_i] = sub_dir
    return sub_dirpaths

main_root = config["job"]["output_path"]
main_dirs = create_dirs_and_get_paths(main_root, ["seq1st", "seq2nd", "align"])
logging.info(f" - Output root: {main_root}")

# Basic info
specie = config["job"]["specie"]

# Seq1 and Seq2
seq1_data = [
    (item['uid'], source['flowcell'], source['section'], source.get('lane',None),seq1.get('prefix'), seq1.get('fastq'))
    for item in config['input_data']
    for source in item['source']
    for seq1 in source.get('seq1st', [])
]
df_seq1 = pd.DataFrame(seq1_data, columns=['uid', 'flowcell', 'section', 'lane', 'seq1_prefix', 'seq1_fq_raw'])
df_seq1["lane"] = df_seq1.apply(lambda row: row["lane"] if pd.notna(row["lane"]) else   # impute lane by section
                                {"A": "1", "B": "2", "C": "3", "D": "4"}.get(row["section"][-1], pd.NA),
                                axis=1)
if df_seq1.loc[df_seq1["lane"].isna(), "section"].any(): 
    raise ValueError(f"There are sections missing lane.")
df_seq1["lane"] = df_seq1["lane"].astype(str)
df_seq1["seq1_prefix"] = df_seq1["seq1_prefix"].fillna("L" + df_seq1["lane"].astype(str)) # impute prefix by lane

sc2ln       = create_dict(df_seq1, key_col="section", val_cols="lane",         dict_type="val", val_type="str")
sc2seq1     = create_dict(df_seq1, key_col="section", val_cols="seq1_prefix",  dict_type="val", val_type="str")

seq2_data = [
    (item['uid'], source['flowcell'], source['section'], source['seq2_version'], seq2.get('prefix'), seq2.get('fastq_R1'), seq2.get('fastq_R2'))
    for item in config['input_data']
    for source in item['source']
    for seq2 in source.get('seq2nd', [])
]
df_seq2 = pd.DataFrame(seq2_data, columns=['uid', 'flowcell', 'section', 'seq2_version', 'seq2_prefix', 'seq2_fqr1_raw', 'seq2_fqr2_raw'])
df_seq2["specie_with_seq2v"] = df_seq2.apply(lambda row: specie if pd.isna(row["seq2_version"]) else f"{specie}_{row['seq2_version']}", axis=1)

sc2seq2 = create_dict(df_seq2, key_col="section", val_cols="seq2_prefix",  dict_type="set", val_type="str")

##==============================================
##
## Tentative code
##
##==============================================

df_seq1["seq1_fq_std"] = df_seq1.apply(lambda row: os.path.join(main_dirs["seq1st"], row["flowcell"], "fastqs", row["seq1_prefix"]+".fastq.gz"), axis=1)
for _, row in df_seq1.iterrows():
    os.makedirs(os.path.dirname(row["seq1_fq_std"]), exist_ok=True)
    create_symlink(row["seq1_fq_raw"], row["seq1_fq_std"])
logging.info(df_seq1)

df_seq2["seq2_fqr1_std"]=df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_prefix"], row["seq2_prefix"]+".R1.fastq.gz"), axis=1)
df_seq2["seq2_fqr2_std"]=df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_prefix"], row["seq2_prefix"]+".R2.fastq.gz"), axis=1)
for _, row in df_seq2.iterrows():
    os.makedirs(os.path.dirname(row["seq2_fqr1_std"]), exist_ok=True)
    create_symlink(row["seq2_fqr1_raw"], row["seq2_fqr1_std"])
    create_symlink(row["seq2_fqr2_raw"], row["seq2_fqr2_std"])

logging.info(df_seq2)

request="test-per-task"
#==============================================
#
# 3. A dummy rule to collect results
#
# - Please note that The order of results affects the order of execution.
#
#==============================================
logging.info(f"3. Required output filenames.")

# Log the entire DataFrame
lda_train = lambda: train_model == "LDA"
histology_request = lambda: histology_type is not None

output_filename_conditions = [
    # test run
    {
        'flag': 'test-per-task',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "barcodes.tsv.gz"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "features.tsv.gz"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".gene_full_mito.png"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".sge_match_sbcd.png"], None),
                                (["{flowcell}", "{section}", "sge",   "{specie_with_seq2v}", "gene_visual.tar.gz"], None)
        ],
        'zip_args': {
            'flowcell':         df_seq1["flowcell"].values,
            'section':          df_seq1["section"].values,
            'specie_with_seq2v': df_seq2["specie_with_seq2v"].values,
        },
    },
]

requested_files=list_outputfn_by_request(output_filename_conditions, request)


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

