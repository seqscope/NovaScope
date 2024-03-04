
import os, argparse, yaml, sys

local_scripts = os.path.dirname(os.path.abspath(__file__))
sys.path.append(local_scripts)
from bricks import create_symlink

parser = argparse.ArgumentParser(description='''
                                 Setup environment based on a YAML configuration file. For example: 
                                 python env_setup.py --yaml_file /nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope/installation/env_setup.yaml --env_dir /nfs/turbo/sph-hmkang/index/data/weiqiuc/env_test
                                 ''')
parser.add_argument('--yaml_file', type=str, help='Path to the YAML configuration file')
parser.add_argument('--env_dir', type=str, help='Path to the environment directory.')
args = parser.parse_args()



print("Loading YAML file...")
if not os.path.exists(args.yaml_file):
    print(f"Error: The file {args.yaml_file} does not exist.")
    sys.exit(1)

with open(args.yaml_file, 'r') as file:
    data = yaml.safe_load(file)

print(f"Creating directory: {args.env_dir}")
os.makedirs(args.env_dir, exist_ok=True)


def process_item(key, value, parent_dir):
    os.makedirs(parent_dir, exist_ok=True)
    # Handle dictionary values
    if isinstance(value, dict):
        #print(f"dict: {key}:{value}")
        sub_dir = os.path.join(parent_dir, key)
        for sub_key, sub_value in value.items():
            process_item(sub_key, sub_value, sub_dir)
    # Handle string values (softlink creation)
    elif isinstance(value, str):
        #print(f"string: {key}:{value}")
        target_path=value
        symlink_path=os.path.join(parent_dir, key)
        create_symlink(target_path, symlink_path)
        print(f"    Creating softlink: {symlink_path} -> {target_path}")

print("Processing items from YAML ...")
for main_key, main_value in data.items():
    print(f" - {main_key}")
    process_item(main_key, main_value, args.env_dir)
