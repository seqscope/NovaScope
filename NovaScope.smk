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
import itertools

# snakemake dir and job dir
smk_name="NovaScope"
smk_dir = os.path.dirname(workflow.snakefile)  
#smk_dir="/nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope"
job_dir = os.getcwd()

novascope_scripts   = os.path.join(smk_dir,"scripts")
sys.path.append(novascope_scripts)
from bricks import setup_logging, end_logging, configure_pandas_display, log_a_separator
from bricks import check_input, check_path, check_request, create_dict, create_symlink, create_dirs_and_get_paths
from bricks import list_outputfn_by_request, create_symlinks_by_list
from pipe_utils_novascope import read_config_for_ini, read_config_for_runid, read_config_for_unitid, read_config_for_segment, read_config_for_hist, read_config_for_seq1, read_config_for_seq2, read_config_for_sgevisual
from pipe_condout_novascope import outfn_sbcd_per_fc, outfn_sbcd_per_chip, outfn_smatch_per_chip, outfn_align_per_run, outfn_sge_per_run, outfn_hist_per_run, outfn_trans_per_unit, outfn_filterftr_per_unit, outfn_filterpoly_per_unit, outfn_seg10x_per_unit, outfn_segfict_per_unit
from rule_general_novascope import assign_resource_for_align, get_envmodules_for_rule, get_skip_sbcd, find_major_axis

# set up 
configfile: "config_job.yaml"
# config = yaml.safe_load(open( "config_job.yaml"))

setup_logging(job_dir, smk_name+"_read-in")
log_a_separator()

# - env
env_config, module_config, python, pyenv = read_config_for_ini(config, job_dir, smk_dir, silent=False)

# - tools
spatula  = env_config.get("tools", {}).get("spatula",   "spatula")
samtools = env_config.get("tools", {}).get("samtools",  "samtools")
star     = env_config.get("tools", {}).get("star",      "STAR")
ficture  = os.path.join(smk_dir, "submodules", "ficture")

#==============================================
#
# basic config
#
#==============================================
log_a_separator()
logging.info(f"2. Processing job config files.")

# output
main_root = config.get("output", None)
assert main_root is not None, "Provide a valid output directory."
main_dirs = create_dirs_and_get_paths(main_root, ["seq1st", "seq2nd", "match", "align", "histology", "analysis"])
logging.info(f" - Output root: {main_root}")

# flowcell
flowcell = config.get("input", {}).get("flowcell", None)
assert flowcell is not None, "Provide a valid Flowcell."
logging.info(f" - Flowcell: {flowcell}")

# chip
chip =  config.get("input", {}).get("chip", None)
assert chip is not None, "Provide a valid Section Chip."
logging.info(f" - Section Chip: {chip}")

# species
species = config.get("input", {}).get("species", None) 
logging.info(f" - Species: {species}")

# request
request = check_request(input_request=config.get("request", ["sge-per-run"]), 
                        valid_options=["sbcd-per-flowcell", "sbcd-per-chip", "smatch-per-chip", "align-per-run", "sge-per-run", "hist-per-run", 
                                        "transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", 
                                        "segment-10x-per-unit", "segment-fict-per-unit", "segment-per-unit"])

if  "segment-per-unit" in request:
    request = request + ["segment-10x-per-unit", "segment-fict-per-unit"]

logging.info(f" - Valid Request(s): {request}")

#==============================================
#
# Process input
#
#==============================================
log_a_separator()
logging.info(f"3. Processing input by requests.")

# per-flowcell:
# - all requests
seq1_id, seq1_fq_raw, sc2seq1 = read_config_for_seq1(config, job_dir, main_dirs, silent=False)

# per-chip:
# - smatch-per-chip, sbcd-per-chip (and above)
df_seq2 = read_config_for_seq2(config, job_dir, main_dirs, silent=False)

# per-unit or per-run:
if any(task in request for task in ["align-per-run", "sge-per-run", "hist-per-run", "transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", "segment-10x-per-unit", "segment-fict-per-unit"]):
    run_id, rid2seq2 = read_config_for_runid(config, job_dir, main_dirs, df_seq2, silent=False)
else:
    run_id = None

df_run = pd.DataFrame({
    'flowcell': [flowcell],
    'chip': [chip],
    'seq1_id': [seq1_id],
    'run_id': [run_id],
})

# sge visual
if any(task in request for task in ["sge-per-run", "hist-per-run", "transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", "segment-10x-per-unit", "segment-fict-per-unit"]):
    sgevisual_id2params, rid2sgevisual_id = read_config_for_sgevisual(config, env_config, smk_dir, run_id, silent=False)
    # expand df_sge for sge-per-run
    df_sge = pd.DataFrame( [{**row, 'sgevisual_id': sgevisual_id} for _, row in df_run.iterrows() for sgevisual_id in sgevisual_id2params.keys()])
else:
    logging.info(f" - SGE visualization: Skipping")
    df_sge = pd.DataFrame({
        'flowcell': pd.Series(dtype='object'),
        'chip': pd.Series(dtype='object'),
        'run_id': pd.Series(dtype='object'),
        'sgevisual_id': pd.Series(dtype='object'),
    })

# hist
if "hist-per-run" in request:
    df_hist = read_config_for_hist(config, job_dir, main_dirs, silent=False)
    df_hist["run_id"] = run_id
else:
    logging.info(f" - Histology file: Skipping")
    df_hist = pd.DataFrame({
        'flowcell': pd.Series(dtype='object'),
        'chip': pd.Series(dtype='object'),
        'hist_std_prefix': pd.Series(dtype='object'),
        'figtype': pd.Series(dtype='object'),
        'magnification': pd.Series(dtype='object'),
        'run_id': pd.Series(dtype='object'),
    })

if any(task in request for task in["transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", "segment-10x-per-unit", "segment-fict-per-unit"]):
    # unit ID: to distinguish the default sge and the sge with manual boundary filtering.
    unit_id, unit_ann, boundary = read_config_for_unitid(config.get("input", {}), job_dir, run_id, silent=False)
else:
    unit_id = None

df_run['unit_id']=unit_id

# downstream
df_seg_void = pd.DataFrame({
        'run_id': pd.Series(dtype='object'),
        'unit_id': pd.Series(dtype='object'),
        'solo_feature': pd.Series(dtype='object'),
        'hexagon_width': pd.Series(dtype='int64'), 
        'polygon_den': pd.Series(dtype='object') 
    })

if any(task in request for task in["segment-10x-per-unit", "segment-fict-per-unit"]):
    logging.info(f" - Downstream Segmentation:")
    mu_scale = config.get("downstream", {}).get("mu_scale", 1000)
    logging.info(f"   - mu scale: {mu_scale}")
    # segment info (multiple pairs)
else:
    logging.info(f" - Downstream Segmentation: Skipping")

if "segment-10x-per-unit" in request:
    df_seg10x = read_config_for_segment(config, run_id, unit_id, "10x", silent=False)
else:
    df_seg10x = df_seg_void

if "segment-fict-per-unit" in request:
    df_segfict = read_config_for_segment(config, run_id, unit_id, "ficture", silent=False)
else:
    df_segfict = df_seg_void
#==============================================
#
# Rule all
#
# - If all variable in the zip_args is a list of one element, it's ok to use the list directly. Otherwise, use a dataframe will be safer to avoid wrong combination.
#   Currently, only the df_seq2 and df_segment_char are in the dataframe format.
# - Please note that the order of results affects the order of execution.
#
#==============================================

log_a_separator()
logging.info(f"4. Expected output filenames.")

# required df: df_run, df_seq2, df_sge, df_hist, df_segment_char

# output files are generated based on the requests and extra conditions
output_filename_conditions = [
    outfn_sbcd_per_fc(main_dirs, df_run),
    outfn_sbcd_per_chip(main_dirs, df_run),
    outfn_smatch_per_chip(main_dirs, df_seq2),
    outfn_align_per_run(main_dirs, df_run),
    outfn_sge_per_run(main_dirs, df_sge),
    outfn_hist_per_run(main_dirs, df_hist),
    outfn_trans_per_unit(main_dirs, df_run),
    outfn_filterftr_per_unit(main_dirs, df_run),
    outfn_filterpoly_per_unit(main_dirs, df_segfict),
    outfn_segfict_per_unit(main_dirs, df_segfict),
    outfn_seg10x_per_unit(main_dirs, df_seg10x),
]

requested_files = list_outputfn_by_request(output_filename_conditions, request, debug=False)

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

if any(task in request for task in ["align-per-run", "sge-per-run", "hist-per-run", "transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", "segment-10x-per-unit", "segment-fict-per-unit"]):
    include: "rules/a04_align.smk"
    include: "rules/a05_dge2sdge.smk"

if any(task in request for task in ["sge-per-run", "transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", "segment-10x-per-unit", "segment-fict-per-unit"]):
    include: "rules/b01_sdge_visual.smk"

if "hist-per-run" in request:
    include: "rules/b02_historef.smk"

if any(task in request for task in ["transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", "segment-10x-per-unit", "segment-fict-per-unit"]):
    include: "rules/c01_sdge2sdgeAR.smk"
    include: "rules/c02_sdgeAR_reformat.smk"

if any(task in request for task in ["filterftr-per-unit", "filterpoly-per-unit", "segment-10x-per-unit", "segment-fict-per-unit"]):
    include: "rules/c03_sdgeAR_polygonfilter.smk"
    include: "rules/c03_sdgeAR_featurefilter.smk"

if "segment-10x-per-unit" in request:
    include: "rules/c04_sdgeAR_segment_10x.smk"

if "segment-fict-per-unit" in request:
    include: "rules/c04_sdgeAR_segment_ficture.smk"
