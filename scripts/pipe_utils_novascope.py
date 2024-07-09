import pandas as pd
import logging, os, sys, yaml
from collections import defaultdict

novascope_scripts = os.path.dirname(os.path.abspath(__file__))
sys.path.append(novascope_scripts)
from bricks import check_input, check_path, create_dict, get_last5_from_md5, create_symlink, create_dirs_and_get_paths
from bricks import log_info, log_dataframe

def read_config_for_ini(config, job_dir, smk_dir, silent=False):
    log_info(f"1. Reading input:", silent)
    log_info(f" - Current job path: {job_dir}")
    # config: job
    log_info(f" - Job configuration file: {job_dir}/config_job.yaml", silent)
    # config: env
    env_input = config.get("env_yml", os.path.join(smk_dir, "info", "config_env.yaml"))
    if isinstance(env_input, dict):
        env_input_val = env_input[os.path.basename(smk_dir).lower()]
    elif isinstance(env_input, str):
        env_input_val = env_input
    else:
        raise ValueError("Please provide a valid env config file.")
    env_configfile = check_path(env_input_val, job_dir, strict_mode=True, flag="The environment config file")
    env_config = yaml.safe_load(open(env_configfile))
    log_info(f" - Environment configuration file: {env_configfile}", silent)
    #   - envmodules
    module_config = env_config.get("envmodules", None)
    log_info(f" - Environment modules: {module_config}", silent)
    #   - python env
    pyenv  = env_config.get("pyenv", None)
    assert pyenv is not None, "Please provide a valid python environment."
    assert os.path.exists(pyenv), f"Python environment does not exist: {pyenv}"
    python = os.path.join(pyenv, "bin", "python")
    assert os.path.exists(python), f"Python does not exist in your python environment: {python}"
    log_info(f" - Python environment: {pyenv}", silent)
    return env_config, module_config, python, pyenv

def read_config_for_seq1(config, job_dir, main_dirs, silent=False):
    log_info(f" - Seq1st info:", silent)
    arch_seq1 = config.get('upstream', {}).get('stdfastq', {}).get('seq1st', True)
    # temp
    flowcell = config["input"]["flowcell"]
    chip     = config["input"]["chip"]
    # seq1_id
    seq1_id = config.get('input', {}).get('seq1st', {}).get('id', None)
    if seq1_id is None:
        lane = config.get('input', {}).get('lane', {"A": "1", "B": "2", "C": "3", "D": "4"}.get(chip[-1], None))
        if lane is None:
            raise ValueError("Please provide a valid \"lane\" in the input field in job config file.")
        seq1_id = f"L{lane}"
    # seq1_fq_raw
    seq1_fq_raw = check_path(config.get('input', {}).get('seq1st', {}).get('fastq', None),job_dir, strict_mode=arch_seq1)
    log_info(f"   - Seq1 ID: {seq1_id}" , silent)
    log_info(f"   - Seq1 Fastq: {seq1_fq_raw}" , silent)
    # organize the fastq files
    if arch_seq1:
        log_info("   - Organizing the input FASTQ files and standardizing the file names...", silent)
        seq1_fq_std=os.path.join(main_dirs["seq1st"], flowcell, "fastqs", seq1_id+".fastq.gz")
        os.makedirs(os.path.dirname(seq1_fq_std), exist_ok=True)
        create_symlink(seq1_fq_raw, seq1_fq_std, silent=True)
    # sc2seq1
    sc2seq1 = {chip:seq1_id}
    return seq1_id, seq1_fq_raw, sc2seq1

def read_config_for_seq2(config, job_dir, main_dirs, silent=False):
    log_info(f" - Seq2nd info:", silent)
    arch_seq2   = config.get('upstream', {}).get('stdfastq', {}).get('seq2nd', True)
    # temp
    flowcell= config["input"]["flowcell"]
    chip = config["input"]["chip"]
    # df
    df_seq2 = pd.DataFrame(config.get('input', {}).get('seq2nd', []))
    df_seq2['flowcell'] = flowcell
    df_seq2['chip'] = chip
    df_seq2['seq2_id'] = df_seq2.apply(lambda x: x.get('id') or f"{flowcell}.{chip}.{get_last5_from_md5(check_path(x.get('fastq_R1'), job_dir, strict_mode=arch_seq2))}", axis=1)
    df_seq2['seq2_fqr1_raw'] = df_seq2['fastq_R1'].apply(lambda x: check_path(x, job_dir, strict_mode=arch_seq2))
    df_seq2['seq2_fqr2_raw'] = df_seq2['fastq_R2'].apply(lambda x: check_path(x, job_dir, strict_mode=arch_seq2))
    df_seq2["seq2_fqr1_std"] = df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_id"], row["seq2_id"]+".R1.fastq.gz"), axis=1)
    df_seq2["seq2_fqr2_std"] = df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_id"], row["seq2_id"]+".R2.fastq.gz"), axis=1)
    for _,row in df_seq2.iterrows():
        log_info(f"   - Seq2nd pair id: {row['seq2_id']}", silent)
        log_info(f"                 R1: {row['seq2_fqr1_raw']}", silent)
        log_info(f"                 R2: {row['seq2_fqr2_raw']}", silent)
    # organize the fastq files
    if arch_seq2:
        log_info("   - Organizing the input FASTQ files and standardizing the file names.", silent)
        for _, row in df_seq2.iterrows():
            os.makedirs(os.path.dirname(row["seq2_fqr1_std"]), exist_ok=True)
            create_symlink(row["seq2_fqr1_raw"], row["seq2_fqr1_std"], silent=True)
            create_symlink(row["seq2_fqr2_raw"], row["seq2_fqr2_std"], silent=True)
    return df_seq2

def read_config_for_runid(config, job_dir, main_dirs, df_seq2=None, silent=False):
    run_id = config.get("input", {}).get("run_id", None)

    if df_seq2 is None:
        df_seq2 = read_config_for_seq2(config, job_dir, main_dirs, silent=True)
    
    if run_id is None:
        # get run_id from seq2nd info
        flowcell = config["input"]["flowcell"]
        chip = config["input"]["chip"]
        species = config["input"]["species"]
        seq2_id_concatenated = ''.join(sorted(df_seq2['seq2_id'].apply(lambda x: ' '.join(sorted(x.split()))).sum().split()))
        run_id = f"{flowcell}-{chip}-{species}-" + get_last5_from_md5(seq2_id_concatenated)
        run_id = run_id.lower().replace("_", "-")
    
    df_seq2["run_id"] = run_id
    rid2seq2 = create_dict(df_seq2, key_col="run_id", val_cols="seq2_id",  dict_type="set", val_type="str")

    log_info(f" - Run ID: {run_id}", silent)
    return run_id, rid2seq2

def read_config_for_unitid(config_content, job_dir, run_id, silent=False):
    unit_id = config_content.get("unit_id", None)
    boundary = config_content.get("boundary", None)
    if unit_id is None:
        if boundary is None:
            unit_ann = "default"
        else:
            boundary = check_path(boundary, job_dir, strict_mode=True)
            unit_ann=get_last5_from_md5(boundary)
        unit_id = run_id + "-" + unit_ann
    else:
        unit_ann = unit_id.replace(f"{run_id}-", "")
        if unit_ann == "default":
            assert boundary is None, "When unit_id is annotated with 'default', boundary should not be provided or applied."
        else:
            boundary = check_path(boundary, job_dir, strict_mode=True)
    log_info(f" - Unit ID: {unit_id}", silent)
    log_info(f" - Boundary: {boundary}", silent)
    return unit_id, unit_ann, boundary

#================================================================================================
# upstream
#  - sgevisual

def transform_sge_visual(df, refgl_dir):
    genelist_options={
        "defined": ["nonMT", "MT", "ribosomal", "nuclear"],
        "all": ["Gene", "GeneFull", "Spliced", "Unspliced", "Velocyto"]
    }
    color_code={
            "red":  "#010000",
            "green": "#000100",
            "blue": "#000001"
    }
    # Melt dataframe and calculate paths and indices in one go
    df = df.reset_index().melt(id_vars="index", var_name="color", value_name="value")
    df['color_code'] = df['color'].map(color_code)
    df['is_defined'] = df['value'].isin(genelist_options['defined'])
    df['refgl']      = df.apply(lambda x: os.path.join(refgl_dir, f"{x['value']}.genes.tsv") if x['is_defined'] else os.path.join(refgl_dir, f"all.genes.tsv"), axis=1)
    df['idx']        = df.apply(lambda x: 1 if x['is_defined'] else genelist_options['all'].index(x['value']) + 1, axis=1)
    df['params']     = df.apply(lambda x: f"--color-list \"{x['color_code']}:{x['refgl']}:{x['idx']}\"", axis=1)
    # Create the final parameters string
    return df.pivot(index='index', columns='color', values='params').apply(lambda x: ' '.join(x.dropna()), axis=1)

def convert_sgevisual_list2df(config, refgl_dir):
    # Read the config file for sge visual parameters
    sge_visual_defparams = {'red': ["nonMT"], 'green': ["Unspliced"], 'blue': ["MT"]}
    sge_visual_params = config.get("upstream",{}).get("visualization",{}).get("drawsge",{}).get("genes", sge_visual_defparams)
    df_sge_visual = pd.DataFrame(sge_visual_params).drop_duplicates()
    # Transform the DataFrame
    df_sge_visual['params'] = transform_sge_visual(df_sge_visual, refgl_dir)
    df_sge_visual['sgevisual_id'] = df_sge_visual.apply(lambda x: f"{x['red']}_{x['green']}_{x['blue']}", axis=1)
    return df_sge_visual[['sgevisual_id', 'params']]

def read_config_for_sgevisual(config, env_config, smk_dir, run_id, silent=False):
    log_info(f" - SGE visualization: ", silent)
    # reference gene list directory
    sp2refgl_dir= {
    "mouse": os.path.join(smk_dir, "info", "genelists", "mm39"),
    "human": os.path.join(smk_dir, "info", "genelists", "hg38")
    } 
    species = config["input"]["species"]
    refgl_dir = env_config.get("ref",{}).get("genelists",{}).get(species, sp2refgl_dir.get(species, None))
    assert refgl_dir is not None, f"Provide a valid gene list directory for species {species}."

    # input pd with sgevisual_id and params
    df_sge_visual = convert_sgevisual_list2df(config, refgl_dir)
    sgevisual_id2params = df_sge_visual.set_index("sgevisual_id")["params"].to_dict()

    # create a dict from unit_id from run_id to df_sge_visual["sgevisual_id"] one key to a list and remove duplicates
    rid2sgevisual_id = defaultdict(list)
    rid2sgevisual_id[run_id] = list(df_sge_visual["sgevisual_id"].unique())

    # log info
    log_info(f"   - Reference gene list directory: {refgl_dir}", silent)
    log_info(f"   - SGE visualization(s): {', '.join(df_sge_visual['sgevisual_id'].tolist())}", silent)

    # return
    return sgevisual_id2params, rid2sgevisual_id

#================================================================================================

# downstream

def add_or_expand_column(df, col_name, default_value):
    if col_name not in df.columns:
        if isinstance(default_value, list) and len(default_value) > 1:
            temp_dfs = []
            for value in default_value:
                temp_df = df.copy()
                temp_df[col_name] = value
                temp_dfs.append(temp_df)
            df = pd.concat(temp_dfs).sort_index(kind='merge').reset_index(drop=True)
        else:
            single_value = default_value if not isinstance(default_value, list) else default_value[0]
            df[col_name] = single_value
    return df

def add_default_for_char(df_char, col_w_defval):
    for col_name, default_value in col_w_defval.items():
        df_char = add_or_expand_column(df_char, col_name, default_value)
    return df_char

# def read_config_for_segment(config, run_id, unit_id, silent=False):
#     # segment_char_info
#     segment_char_info= config.get("downstream", {}).get("segment",{}).get("char", None)
#     if segment_char_info is not None:
#         df_segment_char = pd.DataFrame(segment_char_info)
#         segment_defvals={
#             "solo_feature": "gn",
#             "hexagon_width": 24,
#         }
#         df_segment_char["run_id"] = run_id 
#         df_segment_char["unit_id"] = unit_id
#         df_segment_char = add_default_for_char(df_segment_char, segment_defvals)
#     else:
#         df_segment_char = pd.DataFrame({
#             "run_id": [run_id],
#             "unit_id": [unit_id],
#             "solo_feature": ["gn"],
#             "hexagon_width": [24],
#         })
#     # mu_scale
#     mu_scale = config.get("downstream", {}).get("mu_scale", 1000)
#     log_info(f" - Downstream: ", silent)
#     log_info(f"   - mu scale: {mu_scale}", silent)
#     if not silent:
#         log_dataframe(df_segment_char, log_message="   - segment parameters: ", indentation="     ")
#     return df_segment_char, mu_scale

def define_segchar_df(info, run_id, unit_id, format):
    if format == "ficture":
        auto_den_def=True
    elif format == "10x":
        auto_den_def=False

    seg_defvals={
            "solo_feature": "gn",
            "hexagon_width": 24,
            "auto_density": auto_den_def
    }

    if info is not None:
        df_char = pd.DataFrame(info)
        df_char["run_id"] = run_id
        df_char["unit_id"] = unit_id
        df_char = add_default_for_char(df_char, seg_defvals)
    else:
        df_char = pd.DataFrame({
            "run_id": [run_id],
            "unit_id": [unit_id],
            "solo_feature": ["gn"],
            "hexagon_width": [24],
            "auto_density": [auto_den_def]
        })
    # replace auto_density by polygon_den: if "auto_density" is True, polygon_den is "auto" else it is "raw"
    df_char["polygon_den"] = df_char["auto_density"].apply(lambda x: "auto" if x else "raw")
    df_char = df_char.drop(columns=["auto_density"])
    return df_char

def read_config_for_segment(config, run_id, unit_id, format, silent=False):
    seg_info = config.get("downstream", {}).get("segment",{}).get(format, {}).get("char", None)
    df_segchar = define_segchar_df(seg_info, run_id, unit_id, format)
    df_segchar = df_segchar[["run_id", "unit_id", "solo_feature", "polygon_den", "hexagon_width"]]
    if not silent:
        log_dataframe(df_segchar, log_message=f"   - segment parameters ({format}): ", indentation="     ")
    return df_segchar

#================================================================================================

# Histology

def read_config_for_hist(config, job_dir, main_dirs, silent=False):
    # read in with sanity check
    log_info(f" - Histology file: Loading", silent)
    hist_info = config.get("input",{}).get("histology", None)
    if hist_info is None:
        raise ValueError("Please provide a valid histology file when requesting 'hist-per-run' or 'cart-per-hist'...")
    df_hist = pd.DataFrame(hist_info)
    if df_hist["path"].isnull().any():
        raise ValueError("Please provide a valid histology file when requesting 'hist-per-run' or 'cart-per-hist'...")
    # add prefix
    df_hist["flowcell"]      = config["input"]["flowcell"]
    df_hist["flowcell_abbr"] = df_hist["flowcell"].apply(lambda x: x.split("-")[0])
    df_hist["chip"]          = config["input"]["chip"]
    df_hist["species"]       = config["input"]["species"]
    df_hist["magnification"] = df_hist["magnification"].fillna("10X")
    df_hist["figtype"]       = df_hist["figtype"].fillna("hne")
    df_hist["hist_std_prefix"]=df_hist["magnification"]+df_hist["flowcell_abbr"]+"-"+df_hist["chip"]+"-"+df_hist["species"]+"-"+df_hist["figtype"]
    # add paths and archive the files
    df_hist["hist_raw_inputpath"] = df_hist["path"].apply(lambda x: check_path(x, job_dir, strict_mode=True))   # hist_raw_inputpath is the real path
    df_hist["hist_raw_stddir"] = df_hist.apply(lambda x: os.path.join(main_dirs["histology"], x["flowcell"], x["chip"], "raw"), axis=1)
    df_hist["hist_raw_stddir"].apply(lambda x: os.makedirs(x, exist_ok=True))
    df_hist["hist_raw_stdpath"] = df_hist.apply(lambda x: os.path.join(x["hist_raw_stddir"], x["hist_std_prefix"]+".tif"), axis=1)
    # for each row if real path of row['hist_raw_inputpath'] is not equal to row['hist_raw_stdpath'], create symlink
    df_hist.apply(lambda row: create_symlink(row['hist_raw_inputpath'], row['hist_raw_stdpath'], silent=True) if row['hist_raw_inputpath'] != row['hist_raw_stdpath'] else None, axis=1)
    for _,row in df_hist.iterrows():
        log_info(f"    - histology path: {row['path']}", silent)
        log_info(f"            realpath: {row['hist_raw_inputpath']}", silent)
        log_info(f"       magnification: {row['magnification']}", silent)
        log_info(f"         figure type: {row['figtype']}", silent)
    df_hist = df_hist[["flowcell", "chip", "hist_std_prefix", "figtype", "magnification"]]
    return df_hist



   