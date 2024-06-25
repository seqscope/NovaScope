# import modules
import os, sys, gzip, argparse, subprocess, random, yaml, snakemake, re, logging
import pandas as pd
from collections import defaultdict
from snakemake.io import glob_wildcards, Wildcards
import datetime
import logging.handlers
import itertools

novascope_scripts = os.path.dirname(os.path.abspath(__file__))
sys.path.append(novascope_scripts)

from bricks import setup_logging, end_logging, configure_pandas_display, log_a_separator
from bricks import check_input, check_path, check_request, create_dict, create_symlink, create_dirs_and_get_paths
from bricks import list_outputfn_by_request, create_symlinks_by_list
from pipe_utils_novascope import read_config_for_ini, read_config_for_runid, read_config_for_unitid, read_config_for_segment, read_config_for_hist, read_config_for_seq1, read_config_for_seq2, read_config_for_sgevisual
from pipe_condout_novascope import outfn_sbcd_per_fc, outfn_sbcd_per_chip, outfn_smatch_per_chip, outfn_align_per_run, outfn_sge_per_run, outfn_hist_per_run, outfn_segm_per_unit, outfn_trans_per_unit

argparser = argparse.ArgumentParser(description="Feature filtering script.")
argparser.add_argument('--config', help="Path to the input feature file (gzipped)")
args=argparser.parse_args()

# load config
config = yaml.safe_load(open(args.config))

log_a_separator()

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
#species = check_input(config["input"]["species"], {"human", "human_mouse", "mouse", "rat", "worm"}, "species", lower=False)
species = config["input"]["species"]
logging.info(f" - Species: {species}")


