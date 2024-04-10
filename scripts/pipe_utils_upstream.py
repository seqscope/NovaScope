import pandas as pd
import logging, os, sys

local_scripts = os.path.dirname(os.path.abspath(__file__))
sys.path.append(local_scripts)
from bricks import check_input, check_path, create_dict, get_last5_from_md5, create_symlink


def read_config_for_seq1(config, job_dir):
    logging.info(f" - Seq1 info")

    # temp
    chip = config["input"]["chip"]
    
    # seq1_id
    seq1_id = config.get('input', {}).get('seq1st', {}).get('id', None)

    if seq1_id is None:
        lane = config.get('input', {}).get('lane', {"A": "1", "B": "2", "C": "3", "D": "4"}.get(chip[-1], None))
        if lane is None:
            raise ValueError("Please provide a valid lane.")
        seq1_id = f"L{lane}"

    # seq1_fq_raw
    seq1_fq_raw = check_path(config.get('input', {}).get('seq1st', {}).get('fastq', None),job_dir, strict_mode=True)

    # sc2seq1
    sc2seq1 = {chip:seq1_id}

    logging.info(f"     Seq1 ID: {seq1_id}")
    logging.info(f"     Seq1 Fastq: {seq1_fq_raw}")
    return seq1_id, seq1_fq_raw, sc2seq1

def read_config_for_seq2(config, job_dir, log_option=False):
    df_seq2 = pd.DataFrame(config.get('input', {}).get('seq2nd', []))

    # temp
    flowcell= config["input"]["flowcell"]
    chip = config["input"]["chip"]

    #df
    df_seq2['flowcell'] = flowcell
    df_seq2['chip'] = chip
    df_seq2['seq2_id'] = df_seq2.apply(lambda x: x.get('id') or f"{flowcell}.{chip}.{get_last5_from_md5(check_path(x.get('fastq_R1'), job_dir))}", axis=1)
    df_seq2['seq2_fqr1_raw'] = df_seq2['fastq_R1'].apply(lambda x: check_path(x, job_dir))
    df_seq2['seq2_fqr2_raw'] = df_seq2['fastq_R2'].apply(lambda x: check_path(x, job_dir))

    if log_option:
        logging.info(f" - Seq2nd info:")
        for _,row in df_seq2.iterrows():
            logging.info(f"     Seq2nd pair id: {row['seq2_id']}")
            logging.info(f"                 R1: {row['seq2_fqr1_raw']}")
            logging.info(f"                 R2: {row['seq2_fqr2_raw']}")

    return df_seq2

def read_config_for_runid(config, job_dir, df_seq2=None):
    run_id = config.get("input", {}).get("run_id", None)

    if df_seq2 is None:
        df_seq2 = read_config_for_seq2(config, job_dir)
    
    if run_id is None:
        # get run_id from seq2nd info
        flowcell = config["input"]["flowcell"]
        chip = config["input"]["chip"]
        species = config["input"]["species"]
        seq2_fqr1_concatenated = ''.join(sorted(df_seq2['seq2_fqr1_raw'].apply(lambda x: ' '.join(sorted(x.split()))).sum().split()))
        run_id = f"{flowcell}-{chip}-{species}-" + get_last5_from_md5(seq2_fqr1_concatenated)
        run_id = run_id.lower().replace("_", "-")
    
    df_seq2["run_id"] = run_id
    rid2seq2 = create_dict(df_seq2, key_col="run_id", val_cols="seq2_id",  dict_type="set", val_type="str")

    logging.info(f" - Run id: {run_id}")
    return run_id, rid2seq2

def read_config_for_unitid(config, job_dir, run_id):
    boundary = check_path(config.get("input", {}).get("boundary", None), job_dir, strict_mode=False)
    unit_ann = "default" if boundary is None else "bdfilter"
    unit_id  = run_id + "-" + unit_ann

    logging.info(f" - Unit ID: {unit_id}")
    logging.info(f"     Boundary: {boundary}")
    return unit_id, unit_ann, boundary

def read_config_for_analysis(config, run_id, unit_id):
    
    df_analysis = pd.DataFrame(config["analysis"]["params"])
    
    if "solofeature" not in df_analysis.columns: df_analysis["solofeature"] = "gn"
    if "trainwidth" not in df_analysis.columns: df_analysis["trainwidth"] = 24
    if "segmentmove" not in df_analysis.columns: df_analysis["segmentmove"] = 1

    df_analysis["run_id"]  = run_id
    df_analysis["unit_id"] = unit_id

    mu_scale = config.get("analysis", {}).get("mu_scale", 1000)

    logging.info(f" - Analysis info:")
    logging.info(f"     genomic feature: {df_analysis['solofeature'].values}")
    logging.info(f"     training width: {df_analysis['trainwidth'].values}")
    logging.info(f"     segment n_move: {df_analysis['segmentmove'].values}")
    logging.info(f"     mu scale: {mu_scale}")

    return df_analysis, mu_scale

def read_config_for_hist(config, job_dir, main_dir_histology):
    logging.info(f" - Histology file: Loading")

    # std prefix according to historef
    flowcell = config["input"]["flowcell"]
    chip = config["input"]["chip"]
    species = config["input"]["species"]
    
    hist_res = config.get("histology",{}).get("resolution","10")
    flowcell_abbr = config.get("input",{}).get("flowcell").split("-")[0]
    hist_type = check_input(config.get("histology",{}).get("figtype","hne"), ["hne","dapi","fl"], "Histology figure type")
    
    hist_std_prefix = f"{hist_res}X{flowcell_abbr}-{chip}-{species}-{hist_type}"

    # input path
    hist_raw_inputpath = check_path(config.get("input",{}).get('histology', None), job_dir, strict_mode=False) 

    # standard path
    hist_raw_stddir = os.path.join(main_dir_histology, flowcell, chip, "raw")
    os.makedirs(hist_raw_stddir, exist_ok=True)
    hist_raw_stdpath   = os.path.join(hist_raw_stddir, hist_std_prefix+".tif")

    # examine the input and archive the file when needed
    if hist_raw_inputpath is not None: # If histology file is provided, create a symlink to the standard folder.
        logging.info(f"     Histology file: {os.path.realpath(hist_raw_inputpath)}")
        create_symlink(hist_raw_inputpath, hist_raw_stdpath, handle_existing_output="replace", silent=True)
    elif os.path.exists(hist_raw_stdpath): # When not provided, check if the standard file exists.
        logging.info(f"     Histology file: {os.path.realpath(hist_raw_stdpath)}")
    else:
        raise ValueError(f"Please provide a valid histology file. None is found in {hist_raw_stdpath}")

    return hist_std_prefix
