import os, sys, gzip, argparse, subprocess, random, yaml, re
import pandas as pd
from os.path import join
from collections import defaultdict
import itertools
import glob
import datetime
import logging 
from collections import OrderedDict

#================================================================================================

# Table of Contents

# * logging-related func
# * load configs func
# * check input func
# * check path func
# * create dict func
# * create symbolic link func
# * expand func
# * misc

#================================================================================================

# logging-related functions

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


def log_dataframe(df, log_message="DataFrame Info:", indentation=""): 
    ## purpose:format the log messages so that each column value occupies a fixed width

    # Calculate column widths
    col_widths = {col: max(df[col].astype(str).apply(len).max(), len(col)) for col in df.columns}

    # Prepare the header string with column names aligned
    header = ' | '.join([col.ljust(col_widths[col]) for col in df.columns])

    # Log the header
    logging.info(f"{log_message}")
    logging.info(indentation+header)
    logging.info(indentation+"-" * len(header))  # Divider line

    # Iterate over DataFrame rows and log each, maintaining alignment
    for _, row in df.iterrows():
        row_str = ' | '.join([str(row[col]).ljust(col_widths[col]) for col in df.columns])
        logging.info(indentation+row_str)

def log_a_separator():
    logging.info(" ")
    logging.info("#================================================================================================")
    logging.info(" ")

#================================================================================================
# check input func:
# - check if the input value fits the valid options
# - check if the input path is valid

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
            raise ValueError(f"Error: Please provide valid {label} options. Current {label}: {value}")
        return value
    elif isinstance(value, set):
        # Set of values 
        if not value.issubset(valid_options):
            raise ValueError(f"Error: Please provide valid {label} options. Current {label}: {value}")
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

def check_request(input_request, valid_options):
    valid_requests = [task for task in valid_options if task in input_request]
    invalid_requests = [task for task in input_request if task not in valid_options]
    if not valid_requests:
        raise ValueError(f"Provide at least one valid request. Current request(s): {input_request}")
    if invalid_requests:
        logging.warning(f" - Invalid Request(s): {invalid_requests} (omitted).")
    return valid_requests

#================================================================================================

# create dict func:

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

#================================================================================================

# create symbolic link func:

def log_info(message, silent=False):
    """Log a message unless silenced."""
    if not silent:
        logging.info(message)

def check_missing_input(input_path, action_if_missing, silent):
    """Handle scenarios where the input path is missing."""
    if not os.path.exists(input_path):
        message = f"Missing input path: {input_path}."
        if action_if_missing == "warn":
            raise ValueError(message)
        elif action_if_missing == "skip":
            log_info("Skipping symbolic link creation: " + message, silent)
            return True
        else:
            raise ValueError("Invalid option for handle_missing_input.")
    return False

def check_and_handle_existing_output(input_path, output_path, action_if_existing, silent):
    """Handle scenarios where the output path already exists. action_if_existing valid options: replace, warn. (update: I deleted the skip option)"""
    # - link
    if os.path.islink(output_path):
        output_realpath=os.path.realpath(os.readlink(output_path))
        # broken link
        if not os.path.exists(output_realpath):
            os.unlink(output_path)
            log_info(f"Removing broken symbolic link '{output_path}'.", silent)
            return False     
        else:
            if output_realpath == input_path: # link to the same target
                log_info(f"Skipping creation as existing symbolic link '{output_path}' points to the same target.", silent)
                return True
            else:                             # link to a different target  
                if action_if_existing == "replace":
                    log_info(f"Replacing existing symbolic link '{output_path}' pointing to a different target.", silent)
                    os.unlink(output_path)
                    return False
                elif action_if_existing == "warn":
                    raise ValueError(f"Output symbolic link '{output_path}' exists and points to a different target.")
                else:
                    raise ValueError("Invalid option for check_and_handle_existing_output.")
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
    
    if check_missing_input(input_path, handle_missing_input, silent):
        return  # Missing input is handled as specified; skip further actions

    if check_and_handle_existing_output(input_path, output_path, handle_existing_output, silent):
        return  # Existing output is handled as specified; skip creating the symlink

    try:
        os.symlink(input_path, output_path)
        log_info(f"Created symbolic link from '{input_path}' to '{output_path}'.", silent)
    except Exception as e:
        raise ValueError(f"Failed to create symlink: {e}")

def create_symlinks_by_list(input_path, output_path, items, input_id=None, output_id=None, match_by_suffix=False):
    """
    Creates symlinks for files in the input directory at the output directory.
    Handles both exact filenames and files matching a given suffix.
    """
    for item in items:
        if match_by_suffix:
            output_fn = f"{output_id}.{item}" if output_id else item
            if input_id is not None:
                source_path = os.path.join(input_path, input_id+"."+item)
                target_path = os.path.join(output_path, output_fn)
            elif input_id is None:
                matched_files = [f for f in os.listdir(input_path) if f.endswith(item)]
                assert len(matched_files) == 1, f"None file or more than 1 file matched the suffix '{item}' in {input_path}."                
                source_path = os.path.join(input_path, matched_files[0])
                target_path = os.path.join(output_path, output_fn)
        else:
            source_path = os.path.join(input_path, item)
            target_path = os.path.join(output_path, item)
        create_symlink(source_path, target_path)
    
#================================================================================================

#  expand function to list the file names

# 20240424: this one will expand all combinations of the product_args
#def expand(path_pattern, product_args):
#    return [path_pattern.format(**dict(zip(product_args.keys(), values)))
#            for values in itertools.product(*product_args.values())]

def expand(path_pattern, zip_args):
    # Using zip to ensure values from each key are combined by their indices
    return [path_pattern.format(**dict(zip(zip_args.keys(), values)))
            for values in zip(*zip_args.values())]

def expand_output_to_filenames(root, subfolders_patterns, product_args, request_flag, require_output, debug=False):
    # collect two list one is the outputlist one is skiplist
    outlist  = []
    skiplist = []
    if request_flag in require_output:
        for pattern, extra_condition in subfolders_patterns:
            expanded_paths = list(set(expand(os.path.join(root, *pattern), product_args)))
            if extra_condition is None or extra_condition():
                # Format each path with the correct combination of arguments
                outlist.extend(expanded_paths)
            else:
                skiplist.extend(expanded_paths)
    
    # Log output or warnings based on conditions
    if not debug:
        if outlist:
            logging.info(f"   - {request_flag}:")
            [logging.info(f"       {expanded_path}") for expanded_path in outlist]
    else:
        if request_flag in require_output:
            logging.info(f"   - {request_flag}:")
            if outlist:
                logging.info("     - Output files to be generated:")
                [logging.info(f"       {expanded_path}") for expanded_path in outlist]
            if skiplist:
                logging.info("     - Output files to be skipped due to unmet conditions:")
                [logging.info(f"       {expanded_path}") for expanded_path in skiplist]
        else:
            logging.info(f"   - {request_flag}: Skipped.")

    return outlist if outlist else None

def list_outputfn_by_request(output_filename_conditions, request, debug=False):
    logging.info(f' - Checking output by \'request\' and conditions: ')
    requested_files = [
        output
        for cond in output_filename_conditions
        for output in (expand_output_to_filenames(cond['root'], cond['subfolders_patterns'], cond['zip_args'], cond['flag'], request, debug=debug) or [])
    ]
    requested_files=list(set(requested_files))

    # #logging.info(f'\n')
    # if debug:
    #     logging.info(f' - Summarizing all output files: ')
    #     requested_files.sort() # sort the list by alphabetical order
    #     for output_file_i in requested_files:
    #         logging.info(f'   - {output_file_i}')
    
    return requested_files


#================================================================================================

# misc

# download files
def download_file(url, local_path):
    if not os.path.exists(local_path):
        subprocess.run(["wget", "-O", local_path, url], check=True)

# get the last 5 characters of an MD5 hash
import hashlib
def get_last5_from_md5(input_string):
    hash_object = hashlib.md5(input_string.encode())
    hash_hex = hash_object.hexdigest()
    return hash_hex[-5:]

# display pandas dataframe
def configure_pandas_display():
    pd.set_option('display.max_columns', None)  # display all columns
    pd.set_option('display.max_rows', None)     # display all rows
    pd.set_option('display.width', None)        # auto-detect the display width for wrapping
    pd.set_option('display.max_colwidth', None) # display all content of each cell

# Create dirs and get paths
def create_dirs_and_get_paths(main_dir, sub_dirnames):
    sub_dirpaths = {}
    os.makedirs(main_dir, exist_ok=True)
    for sub_dirname_i in sub_dirnames:
        sub_dir = os.path.join(main_dir, sub_dirname_i)
        os.makedirs(sub_dir, exist_ok=True)
        sub_dirpaths[sub_dirname_i] = sub_dir
    return sub_dirpaths