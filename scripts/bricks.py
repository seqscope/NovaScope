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
        if job_dir is not None:
            file_path = os.path.join(job_dir, filename)
        else:
            file_path = filename
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

def check_path(file_path, work_dir, strict_mode=True, flag="The path"):
    """    
    Parameters:
    - file_path (str): The path to check.
    - job_dir (str): The directory to consider as the base for relative paths.
    - strict_mode (bool): If True, raise an error if the path doesn't exist.
    
    Returns:
    - str: The validated path if exists.
    
    Raises:
    - FileNotFoundError: If the path does not exist as either an absolute or a relative path.
    """
    if file_path is not None:
        # Check if file_path is an absolute path and exists
        if os.path.exists(file_path):
            return os.path.realpath(file_path)
        # Construct the full path if file_path is relative to job_dir
        full_path = os.path.join(work_dir, file_path)
        if os.path.exists(full_path):
            return os.path.realpath(full_path)
    # when the file path is not a valid full / relative path or is None 
    if strict_mode:
        raise FileNotFoundError(f" '{flag}' '{file_path}' does not exist as either an absolute or a relative path.")
    else:
        return None

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
def log_info(message, silent):
    """Log a message unless silenced."""
    if not silent:
        logging.info(message)

def check_missing_input(input_path, action_if_missing, output_path, silent):
    """Handle scenarios where the input path is missing."""
    if not os.path.exists(input_path):
        message = f"Missing input path: {input_path}."
        if action_if_missing == "warn":
            raise ValueError(message)
        elif action_if_missing == "skip":
            log_info("Skipping symlink creation: " + message, silent)
            return True
        else:
            raise ValueError("Invalid option for handle_missing_input.")
    return False


def check_and_handle_existing_output(output_path, input_path, action_if_existing, silent):
    """Handle scenarios where the output path already exists. action_if_existing valid options: replace, warn. (update: I deleted the skip option)"""
    # - link
    if os.path.islink(output_path):
        output_realpath=os.path.realpath(os.readlink(output_path))
        # broken link
        if not os.path.exists(output_realpath):
            os.unlink(output_path)
            log_info(f"Removing broken symlink '{output_path}'.", silent)
            return False     
        else:
            if output_realpath == input_path: # link to the same target
                log_info(f"Skipping creation as existing symlink '{output_path}' points to the same target.", silent)
                return True
            else:                             # link to a different target  
                if action_if_existing == "replace":
                    log_info(f"Replacing existing symlink '{output_path}' pointing to a different target.", silent)
                    os.unlink(output_path)
                    return False
                elif action_if_existing == "warn":
                    raise ValueError(f"Output symlink '{output_path}' exists and points to a different target.")
                else:
                    raise ValueError("Invalid option for handle_existing_output.")
    # - file 
    elif os.path.isfile(output_path):
        raise ValueError(f"Output path '{output_path}' exists as a valid file.")
    # - dir
    elif os.path.isdir(output_path):
        raise ValueError(f"Output path '{output_path}' exists as a valid directory.")
    # - else: not exist,?
    return False  # Indicates action is needed: create the symlink

def create_symlink(input_path, output_path, handle_missing_input="warn", handle_existing_output="replace", silent=False):
    """Creates a symbolic link pointing from output_path to input_path."""
    # If input_path is a symbolic link, update it to the target path
    if os.path.islink(input_path):
        input_path = os.path.realpath(os.readlink(input_path))
    
    if check_missing_input(input_path, handle_missing_input, output_path, silent):
        return  # Missing input is handled as specified; skip further actions

    if check_and_handle_existing_output(output_path, input_path, handle_existing_output, silent):
        return  # Existing output is handled as specified; skip creating the symlink

    try:
        os.symlink(input_path, output_path)
        log_info(f"Created symlink from '{input_path}' to '{output_path}'.", silent)
    except Exception as e:
        raise ValueError(f"Failed to create symlink: {e}")


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

def expand_output_to_filenames(root, subfolders_patterns, product_args, required_output_flag, require_output, debug=False):
    expanded_lists = []
    if debug:
        logging.info(f" - {required_output_flag}: ")
    if required_output_flag in require_output:
        for pattern, extra_condition in subfolders_patterns:
            expanded_paths = []
            if extra_condition is None or extra_condition():
                # Format each path with the correct combination of arguments
                expanded_paths = list(set(expand(os.path.join(root, *pattern), product_args)))
                expanded_lists.extend(expanded_paths)
                if debug: logging.info(f"   - Fulfill the extra condition {extra_condition}. Including {expanded_paths}...")
            else:
                if debug: logging.info(f"   - Do not fulfill the extra condition {extra_condition}. Skipping...")
    else:
        if debug: logging.info(f"   - Not in the required output, skipping...")  # For debugging
    if debug: logging.info(f"   => Returning: {expanded_lists if expanded_lists else None}")  # For debugging
    return expanded_lists if expanded_lists else None

def list_outputfn_by_request(output_filename_conditions, request, debug=False):
    requested_files = [
        output
        for cond in output_filename_conditions
        for output in (expand_output_to_filenames(cond['root'], cond['subfolders_patterns'], cond['zip_args'], cond['flag'], request, debug=debug) or [])
    ]

    requested_files=list(set(requested_files))
    # sort the list by alphabetical order
    requested_files.sort()

    #logging.info(f'\n')
    logging.info(f'Summarizing required output files: ')
    for output_file_i in requested_files:
        logging.info(f' - {output_file_i}')
    
    return requested_files


# 6. Download file
def download_file(url, local_path):
    if not os.path.exists(local_path):
        subprocess.run(["wget", "-O", local_path, url], check=True)

# 7. Display pandas dataframe
def configure_pandas_display():
    pd.set_option('display.max_columns', None)  # display all columns
    pd.set_option('display.max_rows', None)     # display all rows
    pd.set_option('display.width', None)        # auto-detect the display width for wrapping
    pd.set_option('display.max_colwidth', None) # display all content of each cell

# 9. Create dirs and get paths
def create_dirs_and_get_paths(main_dir, sub_dirnames):
    sub_dirpaths = {}
    os.makedirs(main_dir, exist_ok=True)
    for sub_dirname_i in sub_dirnames:
        sub_dir = os.path.join(main_dir, sub_dirname_i)
        os.makedirs(sub_dir, exist_ok=True)
        sub_dirpaths[sub_dirname_i] = sub_dir
    return sub_dirpaths
