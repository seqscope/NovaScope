import os, sys
import pandas as pd
from math import ceil

local_scripts = os.path.dirname(os.path.abspath(__file__))
sys.path.append(local_scripts)
from bricks import create_symlink

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
    
def get_skip_sbcd(config):
    sbcd_format = config.get("preprocess", {}).get("fastq2sbcd", {}).get('format', "DraI32") 
    skip_sbcd   = config.get("preprocess", {}).get("smatch", {}).get('skip_sbcd', None)
    if skip_sbcd is None:
        if sbcd_format == "DraI31":
            skip_sbcd = 1
        elif sbcd_format == "DraI32":
            skip_sbcd = 0
        else:
            raise ValueError(f"Missing skip_sbcd and cannot infer from sbcd_format: {sbcd_format}")
    return skip_sbcd


## alignment resource
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

def cal_resource_by_filesize(section, sc2seq2, main_dirs, avail_resource_list):
    # calculate the 2nd-seq fastq size
    fqsize = 0
    for seq2_prefix in sc2seq2[section]:
        seq2_fqr1 = os.path.join(main_dirs["seq2nd"], seq2_prefix, seq2_prefix + ".R1.fastq.gz" )
        seq2_fqr2 = os.path.join(main_dirs["seq2nd"], seq2_prefix, seq2_prefix + ".R2.fastq.gz" )
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


def assign_resource_for_align(section, config, sc2seq2, main_dirs):
    assign_option=config.get("preprocess", {}).get("align", {}).get("resource", {}).get("assign_type", "stdin") 
    
    if assign_option=="filesize":
        avail_resource_list=config.get("preprocess", {}).get("align", {}).get("resource", {}).get("filesize", None)
        assert avail_resource_list is not None, "Please provide filesize resource list for alignment."
        resources = cal_resource_by_filesize(section, sc2seq2, main_dirs, avail_resource_list)
    elif assign_option=="stdin":
        resources = {
        "mem":  config.get("preprocess", {}).get("align", {}).get("resource", {}).get("stdin", {}).get("memory", "70000m"),
        "threads": config.get("preprocess", {}).get("align", {}).get("resource", {}).get("stdin", {}).get("threads", 10),
        "partition": config.get("preprocess", {}).get("align", {}).get("resource", {}).get("stdin", {}).get("partition", "standard"),
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


# Define a function to handle environment modules based on execution mode
def get_envmodules_for_rule(required_modules, module_config):
    if module_config:
        # Environment with module system and configuration is available
        module_list_in_a_string=" ".join([module_config[module] for module in required_modules if module in module_config])
        return f"module load {module_list_in_a_string}"
        #else:
            # Fallback to generic module load commands
            #module_list_in_a_string=" ".join([f"{module}" for module in required_modules])    
            #return f"module load {module_list_in_a_string}"
    else:
        # For local execution or HPC without a modules system, return an empty list
        return ""