
import os, argparse, yaml, sys

local_scripts = os.path.dirname(os.path.abspath(__file__))
sys.path.append(local_scripts)
from bricks import create_symlink

def create_directory(path):
    if not os.path.exists(path):
        os.makedirs(path)

def process_item(key, value, parent_dir):
    # Handle dictionary values
    if isinstance(value, dict):
        dict_dir = os.path.join(parent_dir, key)
        create_directory(dict_dir)
        print(f"Creating directory: {dict_dir}")
        for sub_key, sub_value in value.items():
            process_item(sub_key, sub_value, dict_dir)
    # Handle list values
    elif isinstance(value, list):
        for item in value:
            if isinstance(item, dict):
                for list_key, list_value in item.items():
                    list_dir = os.path.join(parent_dir, key)
                    process_item(list_key, list_value, list_dir)
    # Handle string values (softlink creation)
    elif isinstance(value, str):
        link_name = os.path.join(parent_dir, key)
        create_symlink(value, link_name)
        print(f"Creating softlink: {link_name} -> {value}")

def process_yaml_file(file_path, work_path):
    with open(file_path, 'r') as file:
        data = yaml.safe_load(file)
    env_path = os.path.join(work_path, 'env')
    create_directory(env_path)
    print(f"Creating directory: {env_path}")
    for main_key, main_value in data.items():
        process_item(main_key, main_value, env_path)

parser = argparse.ArgumentParser(description='''
                                 Setup environment based on a YAML configuration file. For example: 
                                 python env_setup.py --yaml_file /nfs/turbo/sph-hmkang/index/data/weiqiuc/from_nge_to_cartoscope/ScopeFlow/installation/env_setup.yaml --work_path  /nfs/turbo/sph-hmkang/index/data/weiqiuc/from_nge_to_cartoscope/ScopeFlow
                                 ''')
parser.add_argument('--yaml_file', type=str, help='Path to the YAML configuration file')
parser.add_argument('--work_path', type=str, help='Path to the snakemake working directory')
args = parser.parse_args()


if not os.path.exists(args.yaml_file):
    print(f"Error: The file {args.yaml_file} does not exist.")
    sys.exit(1)
elif not os.path.exists(args.work_path):
    print(f"Error: The directory {args.work_path} does not exist.")
    sys.exit(1)

process_yaml_file(args.yaml_file, args.work_path)
