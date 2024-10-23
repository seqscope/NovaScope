import pandas as pd
import logging, os, sys, yaml
from collections import defaultdict

novascope_scripts = os.path.dirname(os.path.abspath(__file__))
sys.path.append(novascope_scripts)
from bricks import check_input, check_path, create_dict, get_last5_from_md5, create_symlink, create_dirs_and_get_paths
from bricks import log_info, log_dataframe
from pipe_preconfig_novascope import id2req, df_seg_void, df_hist_void, df_seq2_void, df_sgevisual_void

# ini
def read_config_for_ini(config, job_dir, smk_dir, silent=False):
    log_info(f"1. Initializing pipeline...", silent)
    log_info(f" - Job directory: {job_dir}", silent)
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
    # - envmodules
    module_config = env_config.get("envmodules", {})
    log_info(f" - Environment modules: {module_config}", silent)
    # - python env
    pyenv  = env_config.get("pyenv", None)
    assert pyenv is not None, "Please provide a valid python environment."
    assert os.path.exists(pyenv), f"Python environment does not exist: {pyenv}"
    assert os.path.exists(os.path.join(pyenv, "bin", "python")), f"Python does not exist in your python environment: {pyenv}"
    log_info(f" - Python environment: {pyenv}", silent)
    # store env settings into config (make it easier for the later read_config functions)
    config["env"]=env_config 
    config["paths"]={}
    config["paths"]["job_dir"]=job_dir
    config["paths"]["smk_dir"]=smk_dir
    return config

# seq1 
def process_config_for_seq1(config_input, arch_fq, job_dir, main_dirs, silent=False):
    log_info(f" - 1st-Seq info:", silent)
    # seq1_id
    seq1_id = config_input.get('seq1st', {}).get('id', None)
    if seq1_id is None:
        chip = config_input.get('chip', None)
        lane = config_input.get('lane', {"A": "1", "B": "2", "C": "3", "D": "4"}.get(chip[-1], None))
        if lane is None:
            raise ValueError("Please provide a valid \"lane\" in the input field in job config file.")
        seq1_id = f"L{lane}"
    # input fastq
    seq1_fq_raw = check_path(config_input.get('seq1st', {}).get('fastq', None),job_dir, strict_mode=arch_fq)
    log_info(f"   - Seq1 ID: {seq1_id}" , silent)
    log_info(f"         FASTQ file: {seq1_fq_raw}" , silent)
    # archive fq 
    if arch_fq:
        log_info("   - Organizing and standardizing 1st-Seq FASTQ files...", silent)
        flowcell = config_input.get("flowcell", None)
        seq1_fq_std = os.path.join(main_dirs["seq1st"], flowcell, "fastqs", seq1_id+".fastq.gz")
        os.makedirs(os.path.dirname(seq1_fq_std), exist_ok=True)
        create_symlink(seq1_fq_raw, seq1_fq_std, silent=True)    
    return seq1_id

def read_config_for_seq1(config, silent=False):
    config_input = config.get("input", {})
    arch_fq_seq1 = config.get('upstream', {}).get('stdfastq', {}).get('seq1st', True)
    main_dirs=config.get("paths", {}).get("output", {})
    job_dir=config.get("paths", {}).get("job_dir", None)
    seq1_id = process_config_for_seq1(config_input, arch_fq_seq1, job_dir, main_dirs, silent)
    return seq1_id

# seq2
def process_config_for_seq2(config_input, arch_fq, job_dir, main_dirs, silent=False):
    log_info(f" - 2nd-Seq info:", silent)
    # seq2 ids and fastq files
    df_seq2  = pd.DataFrame(config_input.get('seq2nd', []))
    df_seq2['flowcell'] = config_input.get("flowcell", None)
    df_seq2['chip'] = config_input.get("chip", None)
    df_seq2['seq2_id'] = df_seq2.apply(lambda x: x.get('id') or f'{x.get("flowcell")}.{x.get("chip")}.{get_last5_from_md5(check_path(x.get("fastq_R1"), job_dir, strict_mode=arch_fq))}', axis=1)
    df_seq2['seq2_fqr1_raw'] = df_seq2['fastq_R1'].apply(lambda x: check_path(x, job_dir, strict_mode=arch_fq))
    df_seq2['seq2_fqr2_raw'] = df_seq2['fastq_R2'].apply(lambda x: check_path(x, job_dir, strict_mode=arch_fq))
    for _,row in df_seq2.iterrows():
        log_info(f"   - Seq2 ID: {row['seq2_id']}", silent)
        log_info(f"         FASTQ R1: {row['seq2_fqr1_raw']}", silent)
        log_info(f"         FASTQ R2: {row['seq2_fqr2_raw']}", silent)
    # archive fq
    if arch_fq:
        log_info("   - Organizing and standardizing 2nd-Seq FASTQ files...", silent)
        df_seq2["seq2_fqr1_std"] = df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_id"], row["seq2_id"]+".R1.fastq.gz"), axis=1)
        df_seq2["seq2_fqr2_std"] = df_seq2.apply(lambda row: os.path.join(main_dirs["seq2nd"],row["seq2_id"], row["seq2_id"]+".R2.fastq.gz"), axis=1)
        for _, row in df_seq2.iterrows():
            os.makedirs(os.path.dirname(row["seq2_fqr1_std"]), exist_ok=True)
            create_symlink(row["seq2_fqr1_raw"], row["seq2_fqr1_std"], silent=True)
            create_symlink(row["seq2_fqr2_raw"], row["seq2_fqr2_std"], silent=True)
    return df_seq2

def read_config_for_seq2(config, silent=False):
    if set(id2req["seq2_id"]).intersection(set(config["request"])):
        config_input = config.get("input", {})
        arch_fq_seq2 = config.get('upstream', {}).get('stdfastq', {}).get('seq2nd', True)
        main_dirs=config.get("paths", {}).get("output", {})
        job_dir=config.get("paths", {}).get("job_dir", None)
        df_seq2 = process_config_for_seq2(config_input, arch_fq_seq2, job_dir, main_dirs, silent)
    else:
        df_seq2 = df_seq2_void
    return df_seq2

# run_id
def process_config_for_runid(config_input, job_dir, main_dirs, df_seq2=None, silent=False):
    run_id = config_input.get("run_id", None)

    if df_seq2 is None:
        df_seq2 = read_config_for_seq2(config_input, {'seq2nd': False}, job_dir, main_dirs, silent=True)
    
    if run_id is None:
        # get run_id from seq2nd info
        flowcell =  config_input.get("flowcell", None)
        chip =  config_input.get("chip", None)
        species =  config_input.get("species", None)
        seq2_id_concatenated = ''.join(sorted(df_seq2['seq2_id'].apply(lambda x: ' '.join(sorted(x.split()))).sum().split()))
        run_id = f"{flowcell}-{chip}-{species}-" + get_last5_from_md5(seq2_id_concatenated)
        run_id = run_id.lower().replace("_", "-")
    
    df_seq2["run_id"] = run_id
    rid2seq2 = create_dict(df_seq2, key_col="run_id", val_cols="seq2_id",  dict_type="set", val_type="str")

    log_info(f" - Run ID: {run_id}", silent)
    return run_id, rid2seq2

def read_config_for_runid(config, df_seq2=None, silent=False):
    if set(id2req["run_id"]).intersection(set(config["request"])):   
        config_input = config.get("input", {})
        main_dirs=config.get("paths", {}).get("output", {})
        job_dir=config.get("paths", {}).get("job_dir", None)
        run_id, rid2seq2 = process_config_for_runid(config_input, job_dir, main_dirs, df_seq2, silent)
    else:
        run_id= None
        rid2seq2 = {}
    return run_id, rid2seq2

# unit_id
def process_config_for_unitid(config_input, job_dir, run_id, silent=False):
    unit_id = config_input.get("unit_id", None)
    boundary = config_input.get("boundary", None)
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

def read_config_for_unitid(config, silent=False):
    if set(id2req["unit_id"]).intersection(set(config["request"])):
        job_dir=config.get("paths", {}).get("job_dir", None)
        config_input = config.get("input", {})
        run_id = config_input.get("run_id", None)
        assert run_id is not None, "Failed to catch or generate a valid run_id."
        unit_id, unit_ann, boundary = process_config_for_unitid(config_input, job_dir, run_id, silent)
    else:
        unit_id = None
        unit_ann = None
        boundary = None
    return unit_id, unit_ann, boundary

#================================================================================================
# upstream

#  - sbcd layout examination
def validate_and_determine_layer(tile_1, tile_2):
    # Ensure tiles are 4-digit integers
    for tile in (tile_1, tile_2):
        if not (tile.isdigit() and len(tile) == 4):
            raise ValueError(f"Invalid tile '{tile}': Expected a 4-digit integer.")
    # Determine layer based on first digit of tile_1
    if tile_1[0] == '1':
        return "top"
    elif tile_1[0] == '2':
        return "bottom"
    else:
        raise ValueError(f"Invalid first digit '{tile_1[0]}' in tile_1 '{tile_1}'.")

def read_config_for_sbcdlo(df_run, config,silent =False):
    if "sbcdlo-per-flowcell" in config["request"]:
        log_info(f" - SBCD examination: ", silent)
        tilelist = config.get("upstream", {}).get("sbcd_layout", {}).get('tiles', ["1644,1544", "2644,2544"])
        log_info(f"   - Input tiles: {tilelist}", silent)

        df_sbcdlo = pd.concat([
            df_run.assign(
                tile_1=tiles.split(",")[0],
                tile_2=tiles.split(",")[1],
                layer=lambda x: validate_and_determine_layer(*tiles.split(","))
            ) for tiles in tilelist
        ])

        df_sbcdlo = df_sbcdlo[["flowcell", "seq1_id", "layer", "tile_1", "tile_2"]].drop_duplicates()
    else:
        log_info(f" - SBCD examination: Skipping...", silent)
        df_sbcdlo= pd.DataFrame( [{**row, 'layer': None} for _, row in df_run.iterrows()])
        df_sbcdlo= pd.DataFrame( [{**row, 'tile_1': None} for _, row in df_sbcdlo.iterrows()])
        df_sbcdlo= pd.DataFrame( [{**row, 'tile_2': None} for _, row in df_sbcdlo.iterrows()])
    return df_sbcdlo

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

def convert_sgevisual_list2df(config_upstream, refgl_dir):
    # Read the config file for sge visual parameters
    sge_visual_defparams = {'red': ["nonMT"], 'green': ["Unspliced"], 'blue': ["MT"]}
    sge_visual_params = config_upstream.get("visualization",{}).get("drawsge",{}).get("genes", sge_visual_defparams)
    df_sge_visual = pd.DataFrame(sge_visual_params).drop_duplicates()
    # Transform the DataFrame
    df_sge_visual['params'] = transform_sge_visual(df_sge_visual, refgl_dir)
    df_sge_visual['sgevisual_id'] = df_sge_visual.apply(lambda x: f"{x['red']}_{x['green']}_{x['blue']}", axis=1)
    return df_sge_visual[['sgevisual_id', 'params']]

def process_config_for_sgevisual(config_upstream, refgl_dir, run_id, silent=False):
    # input pd with sgevisual_id and params
    df_sge_visual = convert_sgevisual_list2df(config_upstream, refgl_dir)
    sgevisual_id2params = df_sge_visual.set_index("sgevisual_id")["params"].to_dict()

    # create a dict from unit_id from run_id to df_sge_visual["sgevisual_id"] one key to a list and remove duplicates
    rid2sgevisual_id = defaultdict(list)
    rid2sgevisual_id[run_id] = list(df_sge_visual["sgevisual_id"].unique())

    # log info
    log_info(f"   - Reference gene lists directory: {refgl_dir}", silent)
    log_info(f"   - SGE visualization abbr: {', '.join(df_sge_visual['sgevisual_id'].tolist())}", silent)
    return sgevisual_id2params, rid2sgevisual_id

def define_refgenelist_by_sp(config):
    species = config.get("input", {}).get("species", None)
    refgl_dir = config.get("env", {}).get("ref",{}).get("genelists",{}).get(species, None)
    if refgl_dir is None:
        smk_dir=config.get("paths", {}).get("smk_dir", None)
        sp2refgl_dir= {
            "mouse": os.path.join(smk_dir, "info", "genelists", "mm39"),
            "human": os.path.join(smk_dir, "info", "genelists", "hg38")
        }
        refgl_dir = sp2refgl_dir.get(species, None)
    assert refgl_dir is not None, f"Provide a valid gene list directory for species {species} or deactivate spatial expression visualization by setting `action` in `draw_sge` as `False`."
    return refgl_dir

def read_config_for_sgevisual(config, df_run, silent=False):
    df_run=df_run[['flowcell', 'chip', 'run_id']]
    drawsge=config.get("upstream",{}).get("visualization",{}).get("drawsge",{}).get("action", True)
    if drawsge and set(id2req["sgevisual_id"]).intersection(set(config["request"])) :
        log_info(f" - SGE visualization: ", silent)
        refgl_dir = define_refgenelist_by_sp(config)
        run_id = config.get("input",{}).get("run_id", None)
        assert run_id is not None, "Failed to catch or generate a valid run_id."
        config_upstream=config.get("upstream", {})
        sgevisual_id2params, rid2sgevisual_id = process_config_for_sgevisual(config_upstream, refgl_dir, run_id, silent)
        df_sge = pd.DataFrame( [{**row, 'sgevisual_id': sgevisual_id} for _, row in df_run.iterrows() for sgevisual_id in sgevisual_id2params.keys()])
    else:
        log_info(f" - SGE visualization: Skipping...", silent)
        sgevisual_id2params = {}
        rid2sgevisual_id = defaultdict(list)
        df_sge = df_sgevisual_void
    return df_sge, sgevisual_id2params, rid2sgevisual_id

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

def define_segchar_df(info, run_id, unit_id, format):
    if format == "ficture":
        sge_qc_def=True
    elif format == "10x":
        sge_qc_def=False

    seg_defvals={
            "solo_feature": "gn",
            "hexagon_width": 24,
            "quality_control": sge_qc_def
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
            "quality_control": [sge_qc_def]
        })
    df_char["sge_qc"] = df_char["quality_control"].apply(lambda x: "filtered" if x else "raw")
    df_char = df_char.drop(columns=["quality_control"])
    return df_char

def read_config_for_segment(config, run_id, unit_id, format, silent=False):
    seg_info = config.get("downstream", {}).get("segment",{}).get(format, {}).get("char", None)
    df_segchar = define_segchar_df(seg_info, run_id, unit_id, format)
    df_segchar = df_segchar[["run_id", "unit_id", "solo_feature", "sge_qc", "hexagon_width"]]
    if not silent:
        log_dataframe(df_segchar, log_message=f"   - Segmentation parameters (format: {format}): ", indentation="     ")
    return df_segchar

#================================================================================================
# Histology

def process_config_for_hist(df_hist, job_dir, main_dirs, silent=False):
    log_info(f" - Histology alignment:", silent)
    # add prefix
    df_hist["flowcell_abbr"] = df_hist["flowcell"].apply(lambda x: x.split("-")[0])
    df_hist["magnification"] = df_hist["magnification"].fillna("10X")
    df_hist["figtype"]       = df_hist["figtype"].fillna("hne")
    df_hist["hist_std_prefix"] = df_hist["magnification"]+df_hist["flowcell_abbr"]+"-"+df_hist["chip"]+"-"+df_hist["species"]+"-"+df_hist["figtype"]
    # add paths and archive the files
    df_hist["hist_raw_inputpath"] = df_hist["path"].apply(lambda x: check_path(x, job_dir, strict_mode=True))   # hist_raw_inputpath is the real path
    df_hist["hist_raw_stddir"] = df_hist.apply(lambda x: os.path.join(main_dirs["histology"], x["flowcell"], x["chip"], "raw"), axis=1)
    df_hist["hist_raw_stdpath"] = df_hist.apply(lambda x: os.path.join(x["hist_raw_stddir"], x["hist_std_prefix"]+".tif"), axis=1)
    # for each row if real path of row['hist_raw_inputpath'] is not equal to row['hist_raw_stdpath'], create symlink
    df_hist["hist_raw_stddir"].apply(lambda x: os.makedirs(x, exist_ok=True))
    df_hist.apply(lambda row: create_symlink(row['hist_raw_inputpath'], row['hist_raw_stdpath'], silent=True) if row['hist_raw_inputpath'] != row['hist_raw_stdpath'] else None, axis=1)
    
    for _,row in df_hist.iterrows():
        log_info(f"    - Histology path: {row['path']}", silent)
        log_info(f"           Real path: {row['hist_raw_inputpath']}", silent)
        log_info(f"       Magnification: {row['magnification']}", silent)
        log_info(f"         Figure type: {row['figtype']}", silent)
    
    df_hist = df_hist[["flowcell", "chip", "hist_std_prefix", "figtype", "magnification"]]
    return df_hist

def read_config_for_hist(config, df_run, silent=False):
    if "histology-per-run" in config["request"]:
        main_dirs=config.get("paths", {}).get("output", {})
        job_dir=config.get("paths", {}).get("job_dir", None)
        hist_info = config.get("input", {}).get("histology", None)
        if hist_info is None:
            raise ValueError("Please provide a valid path to input histology files when requesting 'histology-per-run' ...")
        df_hist_info = pd.DataFrame(hist_info)
        if df_hist_info["path"].isnull().any():
            raise ValueError("Please provide a valid path to input histology files when requesting 'histology-per-run' ...")
        df_hist = pd.merge(df_run, df_hist_info, how='cross')

        df_hist = process_config_for_hist(df_hist, job_dir, main_dirs, silent)
    else:
        log_info(f" - Histology alignment: Skipping...", silent)
        df_hist = df_hist_void
    log_dataframe(df_hist)
    return df_hist

   