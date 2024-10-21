import os, sys, csv
import pandas as pd
from math import ceil

novascope_scripts = os.path.dirname(os.path.abspath(__file__))
sys.path.append(novascope_scripts)
from bricks import create_symlink,  create_symlinks_by_list

#===============================================================================
# Table of Contents

# * Setup RGB Layout
# * Get skip_sbcd
# * Calculate resource for alignment by input file size
# * Assign resource for align
# * Get module (name+version) by key
# * Find major axis

# ===============================================================================
#
# create a 1x1 layout (not in use, 20240409)
#
def setup_rgb_layout(rgb_layout_path, sdge_dir):
    """
    Sets up an RGB layout file. Creates a default 1x1 layout if no layout is specified,
    or verifies the existence of a specified layout and creates a symlink to it.
    """
    # If no specific layout file is provided, create a default 1x1 layout
    if rgb_layout_path is None:
        print("No layout file for rgb-gene-image specified. Creating a default 1x1 layout.")
        default_layout_file = os.path.join(sdge_dir, "layout.1x1.tsv")
        # Check if the default layout file does not exist and create it
        if not os.path.exists(default_layout_file):
            with open(default_layout_file, "w") as f:
                f.write("lane\ttile\trow\tcol\n")
                f.write("1\t1\t1\t1\n")
        return default_layout_file
    else:
        # Ensure the specified layout file exists
        assert os.path.exists(rgb_layout_path), f"Please provide a valid layout file for rgb figure at {rgb_layout_path}."
        print(f"The rgb-gene-image layout file: {rgb_layout_path}")
        # Create a symlink to the specified layout file
        target_layout_file = os.path.join(sdge_dir, "layout.tsv")
        create_symlink(rgb_layout_path, target_layout_file)
        return target_layout_file
    
# ===============================================================================
#
# get skip_sbcd parameter by sbcd_format
#
def get_skip_sbcd(config):
    sbcd_format = config.get("upstream", {}).get("fastq2sbcd", {}).get('format', "DraI32") 
    skip_sbcd   = config.get("upstream", {}).get("smatch", {}).get('skip_sbcd', None)
    if skip_sbcd is None:
        if sbcd_format == "DraI31":
            skip_sbcd = 1
        elif sbcd_format == "DraI32":
            skip_sbcd = 0
        else:
            raise ValueError(f"Missing skip_sbcd and cannot infer from sbcd_format: {sbcd_format}")
    return skip_sbcd

# ===============================================================================
#
# calculate resource for alignment by input file size
#
def convert_mem_unit_to_gb(x):
    lower_x = x.lower()
    if lower_x.endswith('mb') or lower_x.endswith('m'):
        value = float(lower_x.rstrip('mb').rstrip('m')) / 1024  # Convert MB/M to GB
    elif lower_x.endswith('gb') or lower_x.endswith('g'):
        value = float(lower_x.rstrip('gb').rstrip('g'))  # Already in GB
    else:
        try:
            # No unit specified, assume GB
            value = float(x)
        except ValueError:
            raise ValueError(f"Invalid memory unit in '{x}'. Expected 'MB', 'GB', 'M', or 'G'.")
    return value

def calculate_default_memory(fqsize):
    """This is a tentative plan for automatically assign resources for alignment."""
    if fqsize < 200:
        return 70
    elif fqsize < 400:
        return 140
    return 330

def cal_resource_by_filesize(run, rid2seq2, main_dirs, avail_resource_list):
    # calculate the 2nd-seq fastq size
    fqsize = 0
    for seq2_id in rid2seq2[run]:
        seq2_fqr1 = os.path.join(main_dirs["seq2nd"], seq2_id, seq2_id + ".R1.fastq.gz" )
        seq2_fqr2 = os.path.join(main_dirs["seq2nd"], seq2_id, seq2_id + ".R2.fastq.gz" )
        fqsize += ( os.path.getsize(seq2_fqr1) / 1e9 )
        fqsize += ( os.path.getsize(seq2_fqr2) / 1e9 )
    
    # Convert resource list to DataFrame and adjust memory units
    avail_resource_df = pd.DataFrame(avail_resource_list)
    avail_resource_df["mem_per_cpu"] = avail_resource_df["mem_per_cpu"].apply(convert_mem_unit_to_gb)
    avail_resource_df["max_mem"] = avail_resource_df["mem_per_cpu"] * avail_resource_df["max_n_cpus"].astype(int)
    avail_resource_df.sort_values(by="mem_per_cpu", ascending=True, inplace=True)

    # The tentative plan for automatically assign resources
    def_mem_gb = calculate_default_memory(fqsize)
    suitable_resources = avail_resource_df[avail_resource_df["max_mem"] >= def_mem_gb]
    assert not suitable_resources.empty, "None of the available resources allows for the required memory."
    resource = suitable_resources.iloc[0]

    threads = ceil(def_mem_gb / resource["mem_per_cpu"])
    mem = threads * resource["mem_per_cpu"]

    return {
            "mem": f"{int(mem)}g",
            "threads": threads,
            "partition": resource["partition"],
        }

def assign_resource_for_align(run, config, rid2seq2, main_dirs):
    assign_option=config.get("upstream", {}).get("align", {}).get("resource", {}).get("assign_type", "stdin") 
    env_config=config.get("env_config", {})
    
    if assign_option=="filesize":
        avail_resource_list=env_config.get("available_nodes", None)
        assert avail_resource_list is not None, "Please provide filesize resource list for alignment."
        resources = cal_resource_by_filesize(run, rid2seq2, main_dirs, avail_resource_list)
    elif assign_option=="stdin":
        resources = {
        "mem":  config.get("upstream", {}).get("align", {}).get("resource", {}).get("stdin", {}).get("memory", "70000m"),
        "threads": config.get("upstream", {}).get("align", {}).get("resource", {}).get("stdin", {}).get("threads", 10),
        "partition": config.get("upstream", {}).get("align", {}).get("resource", {}).get("stdin", {}).get("partition", "standard"),
        }  
    else:
        raise ValueError(f"Unknown assign_option: {assign_option}")

    resources["threads"] = int(resources["threads"])

    mem_str = resources["mem"].replace(" ", "").upper()

    if mem_str.endswith("G") or mem_str.endswith("GB"):
        mem_str = mem_str.rstrip("GB").rstrip("G")
        ram=int(mem_str) * 1024**3
    elif mem_str.endswith("M") or mem_str.endswith("MB"):
        mem_str = mem_str.rstrip("MB").rstrip("M")
        ram=int(mem_str) * 1024**2
    else:
        raise ValueError("Please provide assign_resource_memory in GB or MB.")
    
    resources["ram"] = str(ram)

    return resources

# ===============================================================================
#
# get module names by key

# Update: 
# * 20240326: Updated function to correctly load nested modules, e.g., 'samtools' under 'Bioinformatics'.
def get_envmodules_for_rule(required_modules, module_config):
    if module_config:
        # Environment with module system and configuration is available
        module_cmd = []
        for module in required_modules:
            if module in module_config:
                if '&&' in module_config[module]:
                    module_cmd.extend([f"module load {mod.strip()}" for mod in module_config[module].split('&&')])
                else:
                    module_cmd.append(f"module load {module_config[module]}")
        return '\n'.join(module_cmd)
    else:
        # For local execution or HPC without a modules system, return an empty list
        return ""

# ===============================================================================

# get python path

def get_python(pyenv):
    assert pyenv is not None, "Please provide a valid python environment."
    assert os.path.exists(pyenv), f"Python environment does not exist: {pyenv}"
    python = os.path.join(pyenv, "bin", "python")
    assert os.path.exists(python), f"Python does not exist in your python environment: {python}"
    return python

# ===============================================================================
#
# find_major_axis

def find_major_axis(filename, format):
    # Usage: 
    #   - It was suggested to use the longer axis as the major axis 
    #   - Once the major axis was set, the QCed.matrix.tsv.gz and transcripts.tsv.gz should be sorted by the major axis
    # Update:
    #   2024.02: Since the longer axis may change after postsdge_QC, use the barcodes.minmax.tsv to determine the major axis.
    # (1) detect from the "{uid}.coordinate_minmax.tsv"  
    if format == "row":
        data = {}
        with open(filename, 'r') as file:
            for line in file:
                key, value = line.split()
                data[key] = float(value)
        if not all(k in data for k in ['xmin', 'xmax', 'ymin', 'ymax']):
            raise ValueError("Missing one or more required keys (xmin, xmax, ymin, ymax)")
        xmin = data['xmin']
        xmax = data['xmax']
        ymin = data['ymin']
        ymax = data['ymax']
    # (2) detect from the barcodes.minmax.tsv
    elif format == "col":
        # read filename and read the header from the first line
        with open(filename, 'r') as file:
            reader = csv.DictReader(file, delimiter='\t')
            try:
                row = next(reader)  # Read the first row
            except StopIteration:
                raise ValueError("File is empty")
            # Check if there is more than one row
            try:
                next(reader)
                raise ValueError("Error: More than one row of data found.")
            except StopIteration:
                pass  # Only one row of data, which is expected
            xmin = int(row['xmin'])
            xmax = int(row['xmax'])
            ymin = int(row['ymin'])
            ymax = int(row['ymax'])
    deltaX = xmax - xmin
    deltaY = ymax - ymin
    if deltaX > deltaY:
        return "X"
    else:
        return "Y"
        
