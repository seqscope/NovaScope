import os, sys, gzip, argparse, subprocess, random, yaml, re
import pandas as pd
from os.path import join
from collections import defaultdict
import itertools
import glob
import datetime
import logging 
from collections import OrderedDict

#from snakemake.io import expand

# 1. Set up logging func:
def setup_logging(job_dir,log_prefix):
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d')
    log_dir = os.path.join(job_dir, "logs")
    if not os.path.exists(log_dir):
        os.mkdir(log_dir)
    logging.basicConfig(
        filename=os.path.join(log_dir, f'{log_prefix}_{timestamp}.log'),
        level=logging.DEBUG,
        format='%(asctime)s - %(levelname)s - %(message)s',
        filemode='w'
    )

def end_logging():
    # Now stop the logging info
    # 1) Get the root logger
    root_logger = logging.getLogger()
    # 2) Find and remove the file handler from the root logger
    for handler in root_logger.handlers[:]:
        if isinstance(handler, logging.FileHandler):
            handler.close()
            root_logger.removeHandler(handler)

# 2. Load configs func:
def load_configs(job_dir, config_files):
    """
    Load configuration files from a list of tuples specifying the file names
    and whether they are required or optional.

    Parameters:
    - job_dir (str): The directory where configuration files are located.
    - config_files (list of tuples): Each tuple contains:
        - The filename (str) of a configuration file.
        - A boolean indicating whether the file is required (True) or optional (False).

    Returns:
    - dict: Combined configuration from all successfully loaded files.
    """
    config = {}
    for filename, is_required in config_files:
        file_path = os.path.join(job_dir, filename)
        try:
            with open(file_path) as config_file:
                config.update(yaml.safe_load(config_file))
            logging.info(f"     Loaded: {file_path}")
        except FileNotFoundError:
            if is_required:
                logging.error(f"Required configuration file not found: {file_path}")
                raise
            else:
                logging.info(f"     Skipping: {file_path}")
        except Exception as e:
            logging.error(f"Error loading configuration file {file_path}: {e}")
            if is_required:
                raise
    return config

# 2. Check input func:
def check_input(value, valid_options, label, lower=True):
    """
    Validate if the given value, set of values, or DataFrame column exists in the set of valid options.

    Parameters:
    value (str, set, pd.Series): The value, set of values, or DataFrame column to be validated.
    valid_options (set): A set of valid options.
    label (str): A label to use in error messages.

    Returns:
    - str: Lowercased validated value if input is a string.
    - set: Validated set if input is a set.
    - pd.Series: The same Series if column values are validated.
    """
    if isinstance(value, str):
        # Single string value
        if value not in valid_options:
            raise ValueError(f"Error: Please provide a valid {label}. Current {label}: {value}")
        if lower:
            return value.lower()
        else:
            return value
    elif isinstance(value, list):
        # convert list to set
        value = set(value)
        # Set of values 
        if not value.issubset(valid_options):
            raise ValueError(f"Error: Please provide valid {label} options. Current options: {value}")
        return value
    elif isinstance(value, set):
        # Set of values 
        if not value.issubset(valid_options):
            raise ValueError(f"Error: Please provide valid {label} options. Current options: {value}")
        return value
    elif isinstance(value, pd.Series):
        # DataFrame column
        invalid_rows = value[~value.isin(valid_options)]
        if not invalid_rows.empty:
            raise ValueError(f"Invalid '{label}' values:\n{invalid_rows}")
        return value
    else:
        raise TypeError(f"Unsupported type for 'value': {type(value)}")

# 3. Create dict func:
def create_dict(df, key_col, val_cols, dict_type, val_type):
    if isinstance(val_cols, list):
        all_cols = val_cols.copy()
    else:
        all_cols=[val_cols]
    all_cols.append(key_col)
    df=df[all_cols].drop_duplicates()
    if dict_type == "set":
        my_dict = defaultdict(set)
    else:
        my_dict = defaultdict()
    for index, row in df.iterrows():
        key = row[key_col]
        if val_type == "str":
            values = row[val_cols]
        elif val_type == "tuple":
            values = tuple([row[col] for col in val_cols])
        if dict_type == "set":
            if key in my_dict:
                my_dict[key].add(values)
            else:
                my_dict[key] = {values}
        else:
            my_dict[key] = values
    if dict_type == "val":
        my_dict2 = my_dict
    elif dict_type == "set":
        my_dict2 = defaultdict(list)
        for key, values in my_dict.items():
            my_dict2[key] = list(values)
    return my_dict2

# 4. Create symlink func:
def create_symlink(input_path, output_path, handle_missing_input="warn", handle_existing_output="replace"):
    """
    Create a symlink based on the provided parameters.
    - input_path: The source path for the symlink. If it doesn't exist, behavior is controlled by handle_missing_input.
    - output_path: The destination path for the symlink.
    - handle_missing_input: Determines action if input_path doesn't exist ('warn' to raise an error, 'skip' to ignore).
    - handle_existing_output: Determines action if output_path exists and is a different symlink ('replace' to recreate, 'warn' to raise an error, 'skip' to ignore).
    Returns:
        None
    """
    # Check for missing input path
    if not os.path.exists(input_path):
        message = f"Missing input path: {input_path} for output {output_path}."
        if handle_missing_input == "warn":
            logging.error("Error: " + message)
            raise ValueError(message)
        elif handle_missing_input == "skip":
            logging.info("Skipping symlink creation: " + message)
            return
        else:
            logging.error("Invalid option for handle_missing_input.")
            return
    # Handle existing output path
    def handle_existing_symlink():
        if os.path.realpath(output_path) == os.path.realpath(input_path):
            logging.info(f"Symlink '{output_path}' already exists with the same target. No action needed.")
            return True  # Indicates no further action is needed
        if handle_existing_output == "replace":
            os.unlink(output_path)
            return False  # Indicates further action is needed (symlink creation)
        elif handle_existing_output == "warn":
            logging.error(f"Output symlink '{output_path}' points to a different target. Cannot replace without explicit instruction.")
            raise ValueError("Different target for existing symlink.")
        elif handle_existing_output == "skip":
            logging.info("Existing symlink points to a different target. Skipping creation.")
            return True
        else:
            logging.error("Invalid option for handle_existing_output.")
            raise ValueError("Invalid handle_existing_output option.")

    def handle_existing_non_symlink():
        logging.error(f"Output path '{output_path}' exists and is not a symlink. Consider revising the output path.")
        raise ValueError("Output path exists and is not a symlink.")

    if os.path.exists(output_path):
        if os.path.islink(output_path):
            if handle_existing_symlink():
                return  # Symlink exists with the same target or skipping creation
        else:
            handle_existing_non_symlink()
            return
    # Create symlink if all checks pass
    try:
        os.symlink(input_path, output_path)
        logging.info(f"Created symlink from '{input_path}' to '{output_path}'.")
    except Exception as e:
        logging.error(f"Failed to create symlink: {e}")


def create_symlinks_by_list(input_path, output_path, items, match_by_suffix=False):
    """
    Creates symlinks for files in the input directory at the output directory.
    Handles both exact filenames and files matching a given suffix.

    Args:
    - input_path (str): Path to the input directory.
    - output_path (str): Path to the output directory.
    - items (list of str): A list of filenames or suffixes.
    - is_suffix (bool): If True, treats items as suffixes and searches for matching files.
                        If False, treats items as exact filenames.
    """
    for item in items:
        if match_by_suffix:
            matched_files = [f for f in os.listdir(input_path) if f.endswith(item)]
            if len(matched_files) == 1:
                source_path = os.path.join(input_path, matched_files[0])
                target_path = os.path.join(output_path, item)
                create_symlink(source_path, target_path)
            elif len(matched_files) > 1:
                raise ValueError(f"Multiple files match the suffix '{item}' in {input_path}.")
            else:
                raise ValueError(f"No files match the suffix '{item}' in {input_path}.")
        else:
            source_path = os.path.join(input_path, item)
            target_path = os.path.join(output_path, item)
            if os.path.exists(source_path):
                create_symlink(source_path, target_path)
            else:
                raise ValueError(f"Required input file {source_path} does not exist.")
    
# 5. the expand function to list the file names
def expand(path_pattern, product_args):
    return [path_pattern.format(**dict(zip(product_args.keys(), values)))
            for values in itertools.product(*product_args.values())]

def expand_output_to_filenames(root, subfolders_patterns, product_args, required_output_flag, require_output):
    expanded_lists = []
    logging.info(f" - {required_output_flag}: ")
    if required_output_flag in require_output:
        for pattern, extra_condition in subfolders_patterns:
            expanded_paths = []
            if extra_condition is None or extra_condition():
                # Format each path with the correct combination of arguments
                expanded_paths = list(set(expand(os.path.join(root, *pattern), product_args)))
                expanded_lists.extend(expanded_paths)
                logging.info(f"   - Fulfill the extra condition {extra_condition}, including {expanded_paths} in the output list.")
            else:
                logging.info(f"   - Do not fulfill the extra condition {extra_condition}, skipping {expanded_paths}.")
    else:
        logging.info(f"   - Not in the required output, skipping...")  # For debugging
    logging.info(f"   => Returning: {expanded_lists if expanded_lists else None}")  # For debugging
    return expanded_lists if expanded_lists else None

def list_outputfn_by_request(output_filename_conditions, request):
    requested_files = [
        output
        for cond in output_filename_conditions
        for output in (expand_output_to_filenames(cond['root'], cond['subfolders_patterns'], cond['zip_args'], cond['flag'], request) or [])
    ]

    requested_files=list(set(requested_files))

    logging.info(f' - The required output files includes: ')
    for output_file_i in requested_files:
        logging.info(f'    - {output_file_i}')
    
    return requested_files


# 6. Download file
def download_file(url, local_path):
    """
    Download a file from a URL to a local path using wget.
    Efficiently checks if the file already exists before downloading.
    """
    if not os.path.exists(local_path):
        subprocess.run(["wget", "-O", local_path, url], check=True)

# 7. Display pandas dataframe
def configure_pandas_display():
    pd.set_option('display.max_columns', None)  # display all columns
    pd.set_option('display.max_rows', None)     # display all rows
    pd.set_option('display.width', None)        # auto-detect the display width for wrapping
    pd.set_option('display.max_colwidth', None) # display all content of each cell

# 8. Get mu_scale (not in use)
def get_mu_scale(platform):
    """
    Determine the mu_scale value based on the sequencing platform.
    Parameters:
    - platform (str): The name of the sequencing platform.
    Returns:
    - int or float: The mu_scale value corresponding to the given platform.
    Raises:
    - ValueError: If the platform is not recognized.
    """
    # Dictionary mapping platforms to their mu_scale values
    platform_scales = {
        "seqscope,hiseq": 1000,   # or 26.67 for sge-based pipeline, currently set for nge-based
        "seqscope,novaseq": 1000,
        "salus": 4000,
        "stereoseq": 2,
    }
    # Check if platform is in the dictionary
    if platform in platform_scales:
        return platform_scales[platform]
    else:
        raise ValueError(f"Error: The current platform {platform} is not supported to provide a fixed mu_scale.")

# 9. Create dirs and get paths
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