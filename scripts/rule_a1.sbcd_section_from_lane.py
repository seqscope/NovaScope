import argparse
import pandas as pd
import re
import os

parser = argparse.ArgumentParser(description="Process files for sbcds part.")
parser.add_argument("--input_layout", help="Path to the layout file")
parser.add_argument("--section",  help="section to process")
parser.add_argument("--sbcd_dir", help="Directory containing sbcd files")
parser.add_argument("--sbcd_part_dir", help="Directory for output sbcd part files")
args=parser.parse_args()

"""
args.input_layout = "/nfs/turbo/sph-hmkang/index/data/nova6000.section.info.v2.tsv"
args.sbcd_dir="/nfs/turbo/umms-leeju/v5/seq1st/N3-HG5MC/sbcds/L3"
args.sbcd_part_dir="/nfs/turbo/umms-leeju/v5/seq1st/N3-HG5MC/sbcds.part/L3"
args.section="B08C"
"""

def get_params_from_lo(layout):
    lane=str(layout['lane'])
    topbot=str(layout['topbot'])
    colbeg=int(layout['colbeg'])
    colend=int(layout['colend'])
    return lane, topbot, colbeg, colend

def create_layout_file(sbcd_part_dir, row_lof, section):
    print("Creating layout file for sbcds.part\n")
    # header
    layout_content = ["\t".join(["lane", "tile", "row", "col", "rowshift", "colshift"])]
    # params
    lane, topbot, colbeg, colend = get_params_from_lo(row_lof)
    # advparams
    irow_remainder = 1 if topbot == "2" else 0
    irow_denominator = 2 
    rowshift = 0
    colshift = 0.1715
    # layout
    for row in range(1,7):
        for col in range(colbeg,colend+1):
            scol = "%02d" % col
            print(scol)
            if row % irow_denominator == irow_remainder:
                layout_content.append("\t".join([lane, f"{topbot}{7-row}{scol}", str(row), str(col-colbeg+1), str(rowshift), str(colshift)]))
                #print("\t".join([lane, f"{topbot}{7-row}{scol}", str(row), str(col-colbeg+1), str(rowshift), "0"]))
            else:
                layout_content.append("\t".join([lane, f"{topbot}{7-row}{scol}", str(row), str(col-colbeg+1), str(rowshift), "0"]))
                #print("\t".join([lane, f"{topbot}{7-row}{scol}", str(row), str(col-colbeg+1), str(rowshift), str(colshift)]))
    
    sbcd_part_layout=os.path.join(sbcd_part_dir, section+".layout.tsv")
    with open(sbcd_part_layout, 'w') as file:
        file.write("\n".join(layout_content))
        file.write("\n")
    print(f"Finished layout file for sbcds.part at {sbcd_part_layout}\n")

def create_manifest_file(sbcd_dir, sbcd_part_dir, row_lof):
    print("Creating manifest file for sbcds.part\n")
    # input and output paths
    sbcd_mnfst=os.path.join(sbcd_dir, "manifest.tsv")
    sbcd_part_mnfst=os.path.join(sbcd_part_dir, "manifest.tsv")
    lane, topbot, colbeg, colend = get_params_from_lo(row_lof)
    # process info
    tiles = '|'.join(f"{i:02d}" for i in range(colbeg, colend + 1))
    pattern = re.compile(fr"{lane}_{topbot}[1-6]({tiles})")
    with open(sbcd_mnfst, 'r') as infile, open(sbcd_part_mnfst, 'w') as outfile:
        outfile.write(infile.readline())  # Write the first line
        for line in infile:
            if pattern.search(line):
                outfile.write(line)
                input_path = os.path.join(sbcd_dir, line.strip().split('\t')[1])
                output_path = os.path.join(sbcd_part_dir, line.strip().split('\t')[1])
                if not os.path.exists(output_path):
                    os.symlink(input_path, output_path)
                else:
                    os.remove(output_path)
                    os.symlink(input_path, output_path)
    print(f"Finished manifest file for sbcds.part at {sbcd_part_mnfst}\n")

os.makedirs(args.sbcd_part_dir, exist_ok=True)
df_layout = pd.read_csv(args.input_layout, sep="\t")
df_layout.columns = ["section", "lane", "topbot", "colbeg", "colend"]
row_lof = df_layout[df_layout["section"] == args.section].iloc[0]
print(f"Processing section {args.section} with layout {row_lof}\n")

create_layout_file(args.sbcd_part_dir, row_lof,  args.section)
create_manifest_file(args.sbcd_dir, args.sbcd_part_dir, row_lof)

