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

from pipe_utils_novascope import read_config_for_ini, read_config_for_runid, read_config_for_unitid, read_config_for_segment, read_config_for_hist, read_config_for_seq1, read_config_for_seq2, read_config_for_sbcdlo, read_config_for_sgevisual
from pipe_condout_novascope import outfn_sbcdlo_per_tilepair, outfn_smatch_per_chip, outfn_sge_per_run, outfn_hist_per_run, outfnlist_by_seg, outfnlist_by_run
from pipe_preconfig_novascope import id2req, df_seg_void
from rule_general_novascope import assign_resource_for_align, get_envmodules_for_rule, get_skip_sbcd, find_major_axis

# set up 
configure_pandas_display()
configfile: "config_job.yaml"
# config = yaml.safe_load(open("config_job.yaml"))

# logging
setup_logging(job_dir, smk_name+"_read-in")
log_a_separator()
mode_debug=config.get("debug", False) # if debug, report details for each output file
mode_quite=config.get("quite", False) # if quite, skip the details for processing config

# - env (store env setting into config)
config = read_config_for_ini(config, job_dir, smk_dir, silent=mode_quite)

# - tools
pyenv    = config.get("env",{}).get("pyenv", None)
python   = os.path.join(pyenv, "bin", "python")

spatula  = config.get("env",{}).get("tools", {}).get("spatula",   "spatula")
samtools = config.get("env",{}).get("tools", {}).get("samtools",  "samtools")
star     = config.get("env",{}).get("tools", {}).get("star",      "STAR")
ficture  = os.path.join(smk_dir, "submodules", "ficture")

#==============================================
#
# basic config
#
#==============================================
log_a_separator()
logging.info(f"2. Reading the job configuration file...")

# output
main_root = config.get("output", None)
assert main_root is not None, "Provide a valid output directory."
main_dirs = create_dirs_and_get_paths(main_root, ["seq1st", "seq2nd", "match", "align", "histology", "analysis"])
logging.info(f" - Output directory: {main_root}")

# flowcell
flowcell = config.get("input", {}).get("flowcell", None)
assert flowcell is not None, "Provide a valid flowcell."
logging.info(f" - Flowcell: {flowcell}")

# chip
chip =  config.get("input", {}).get("chip", None)
assert chip is not None, "Provide a valid section chip."
logging.info(f" - Section chip: {chip}")

# species
species = config.get("input", {}).get("species", None)
assert species is not None, "Provide a valid species."
logging.info(f" - Species: {species}")

# request
request = check_request(input_request=config.get("request", ["sge-per-run"]), 
                        valid_options=["sbcd-per-flowcell", "sbcdlo-per-flowcell", 
                                        "sbcd-per-chip", "smatch-per-chip", 
                                        "align-per-run", "sge-per-run", "histology-per-run", 
                                        "transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", 
                                        "segment-10x-per-unit", "segment-ficture-per-unit", "segment-per-unit", 
                                        "segment-viz-per-unit", "sge-per-unit" #additional request options
                                        ])

if  "segment-per-unit" in request:
    request = request + ["segment-10x-per-unit", "segment-ficture-per-unit"]
    
logging.info(f" - Valid Request(s): {request}")

# update config
config["paths"]["output"] = main_dirs
request = request

#==============================================
#
# Process input by requests
#
#==============================================

log_a_separator()
logging.info(f"3. Processing configuration by requests...")

# per-flowcell (all requests)
seq1_id = read_config_for_seq1(config, silent=mode_quite)
sc2seq1 = {chip:seq1_id}

# per-chip: (smatch-per-chip, sbcd-per-chip (and above))
df_seq2 = read_config_for_seq2(set(id2req["seq2_id"]).intersection(set(request)), 
                                config, silent=mode_quite)

# per-unit or per-run:
# - run-id: to distinguish different sets of seq2.
# - unit ID: to distinguish the "default" sge and the sge with boundary filtering.
run_id, rid2seq2 = read_config_for_runid(set(id2req["run_id"]).intersection(set(request)), 
                                         config, df_seq2, silent=mode_quite)
config["input"]["run_id"] = run_id

unit_id, unit_ann, boundary = read_config_for_unitid(set(id2req["unit_id"]).intersection(set(request)), 
                                                    config, silent=mode_quite)
config["input"]["unit_id"] = unit_id

df_run = pd.DataFrame({
    'flowcell': [flowcell],
    'chip': [chip],
    'species': [species],
    'seq1_id': [seq1_id],
    'run_id': [run_id],
    'unit_id': [unit_id],
})

# sbcd layout
df_sbcdlo= read_config_for_sbcdlo("sbcdlo-per-flowcell" in request, config, df_run, silent=mode_quite)

# sge gene set visualization
drawsge = config.get("upstream",{}).get("visualization",{}).get("drawsge",{}).get("action", True)
df_sge, sgevisual_id2params, rid2sgevisual_id = read_config_for_sgevisual(drawsge and set(id2req["sgevisual_id"]).intersection(set(request)),
                                                                        config,  df_run, silent=mode_quite)

# histology alignment
df_hist = read_config_for_hist("histology-per-run" in request, config, df_run, silent=mode_quite)

# downstream
df_seg = read_config_for_segment(set(id2req["seg_id"]).intersection(set(request)), 
                                config, silent=mode_quite)

# - segmentviz or not (default: NOT)
segmentviz = config.get("downstream", {}).get("segmentviz", None)
if "segment-viz-per-unit" in request and segmentviz is None:
    segmentviz=["10x"] # use 10x as default

# - resilient or not (default: NOT)
resilient = config.get("resilient", False)  
if segmentviz:
    resilient = True
logging.info(f" - Resilient mode: {resilient}")

#==============================================
#
# Rule all
#
# - If all variable in the zip_args is a list of one element, it's ok to use the list directly. Otherwise, use a dataframe will be safer to avoid wrong combination.
# - Please note that the order of results affects the order of execution.
#
#==============================================

log_a_separator()
logging.info(f"4. Expected output filenames...")

# output files are generated based on the requests and extra conditions
output_filename_conditions = [
    # per lane & tile pair
    outfn_sbcdlo_per_tilepair(main_dirs, df_sbcdlo),
    # per seq2 id
    outfn_smatch_per_chip(main_dirs, df_seq2),
    # per sgevisual id
    outfn_sge_per_run(main_dirs, df_sge, drawsge),
    # per hist_std_prefix
    outfn_hist_per_run(main_dirs, df_hist),
]
output_filename_conditions.extend(outfnlist_by_run(main_dirs, df_run))
output_filename_conditions.extend(outfnlist_by_seg(main_dirs, df_seg, resilient, segmentviz))    # segment & segmentviz

requested_files = list_outputfn_by_request(output_filename_conditions, request, mode_debug)

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
include: "rules/b03_sbcd_layout.smk"

if set(id2req["run_id"]).intersection(set(request)):   
    include: "rules/a04_align.smk"
    include: "rules/a05_dge2sdge.smk"

if drawsge and set(id2req["sgevisual_id"]).intersection(set(request)) :
    include: "rules/b01_sdge_visual.smk"

if "histology-per-run" in request:
    include: "rules/b02_historef.smk"

if set(id2req["unit_id"]).intersection(set(request)):   
    include: "rules/c01_sdge2sdgeAR.smk"
    include: "rules/c02_sdgeAR_reformat.smk"
    include: "rules/c03_sdgeAR_minmax.smk"
    include: "rules/c03_sdgeAR_featurefilter.smk"

if any(task in request for task in [ "filterpoly-per-unit", "segment-10x-per-unit", "segment-ficture-per-unit" ]):
    if resilient:
        include: "rules/c03_sdgeAR_polygonfilter_resilient.smk"
    else:
        include: "rules/c03_sdgeAR_polygonfilter.smk"
        
if "segment-10x-per-unit" in request:
    if resilient:
        include: "rules/c04_sdgeAR_segment_10x_resilient.smk"
    else:
        include: "rules/c04_sdgeAR_segment_10x.smk"

if "segment-ficture-per-unit" in request:
    if resilient:
        include: "rules/c04_sdgeAR_segment_ficture_resilient.smk"
    else:
        include: "rules/c04_sdgeAR_segment_ficture.smk"

if segmentviz:
    include: "rules/b04_sdgeAR_segmentviz.smk"