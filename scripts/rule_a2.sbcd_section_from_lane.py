import argparse
import pandas as pd
import re
import os

parser = argparse.ArgumentParser(description="Process files for sbcds part.")
parser.add_argument("--input", help="Path to input file, which can be a summary file or a layout file for sbcd layout.")
parser.add_argument("--section",  help="section to process")
parser.add_argument("--sbcd_dir", help="Directory containing sbcd files")
parser.add_argument("--sbcd_part_dir", help="Directory for output sbcd part files")
parser.add_argument("--input_type", default="summary", choices=["summary","layout"],help="This will use the provided summary file to create layout and manifest files. Default: True")

args=parser.parse_args()

"""
args.input = "/nfs/turbo/sph-hmkang/index/data/nova6000.section.info.v2.tsv"
args.sbcd_dir="/nfs/turbo/umms-leeju/v5/tmp/seq1st/N3-HG5MC_1/sbcds/L3"
args.sbcd_part_dir="/nfs/turbo/umms-leeju/v5/tmp/seq1st/N3-HG5MC_1/sbcds.part/L3"
args.section="B08C"
args.input_type="summary"

python rule_a2.sbcd_section_from_lane.py --input /nfs/turbo/sph-hmkang/index/data/nova6000.section.info.v2.tsv --sbcd_dir /nfs/turbo/umms-leeju/v5/tmp/seq1st/N3-HG5MC_1/sbcds/L3 --sbcd_part_dir /nfs/turbo/umms-leeju/v5/tmp/seq1st/N3-HG5MC_1/sbcds.part/L3/B08C --section B08C --input_type summary
python rule_a2.sbcd_section_from_lane.py --input /nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope/testrun/input_data/seq1st/layout/B08Csub.layout.tsv --sbcd_dir /nfs/turbo/umms-leeju/v5/tmp/seq1st/N3-HG5MC_1/sbcds/L3 --sbcd_part_dir /nfs/turbo/umms-leeju/v5/tmp/seq1st/N3-HG5MC_1/sbcds.part/L3/B08Ctest --section B08Ctest --input_type layout

"""

def get_params_from_summary(layout):
    lane=str(layout['lane'])
    topbot=str(layout['topbot'])
    colbeg=int(layout['colbeg'])
    colend=int(layout['colend'])
    return lane, topbot, colbeg, colend

def create_layout_from_summary(sbcd_part_dir, row_losum, section):
    print("Creating layout file for sbcds.part\n")
    # header
    layout_content = ["\t".join(["lane", "tile", "row", "col", "rowshift", "colshift"])]
    # params
    lane, topbot, colbeg, colend = get_params_from_summary(row_losum)
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

def load_tile_criteria(input_type, input_layout=None, row_losum=None):
    if input_type == "layout":
        assert input_layout is not None and os.path.exists(input_layout), \
            "input_layout must be provided and exist for layout input type."
        df_lo = pd.read_csv(input_layout, sep="\t")
        return set(df_lo['tile'].astype(str))
    elif input_type == "summary":
        assert row_losum is not None, "row_losum must be provided for summary input type."
        lane, topbot, colbeg, colend = get_params_from_summary(row_losum)
        tiles = '|'.join(f"{i:02d}" for i in range(colbeg, colend + 1))
        return re.compile(fr"{lane}_{topbot}[1-6]({tiles})")

def process_manifest_line(line, criteria, sbcd_dir, sbcd_part_dir, input_type):
    if input_type == "layout":
        tile_identifier = line.strip().split('\t')[0].split('_')[1]
        if tile_identifier not in criteria:
            return
    elif input_type == "summary":
        if not criteria.search(line):
            return
    
    tile_identifier = line.strip().split('\t')[1]  # Adjust based on actual column

    input_path = os.path.join(sbcd_dir, tile_identifier)
    output_path = os.path.join(sbcd_part_dir, tile_identifier)
    if os.path.exists(output_path):
        os.remove(output_path)
    os.symlink(input_path, output_path)
    return line

def create_manifest(sbcd_dir, sbcd_part_dir, row_losum=None, input_type="summary", input_layout=None):
    print("Creating manifest file for sbcds.part\n")
    criteria = load_tile_criteria(input_type, input_layout, row_losum)
    
    sbcd_mnfst = os.path.join(sbcd_dir, "manifest.tsv")
    sbcd_part_mnfst = os.path.join(sbcd_part_dir, "manifest.tsv")

    with open(sbcd_mnfst, 'r') as infile, open(sbcd_part_mnfst, 'w') as outfile:
        outfile.write(infile.readline())  # Copy the header
        for line in infile:
            processed_line = process_manifest_line(line, criteria, sbcd_dir, sbcd_part_dir, input_type)
            if processed_line:
                outfile.write(processed_line)

    print(f"Finished manifest file for sbcds.part at {sbcd_part_mnfst}\n")

os.makedirs(args.sbcd_part_dir, exist_ok=True)

if args.input_type == "summary":
    print("Input: summary file\n")

    df_losum = pd.read_csv(args.input, sep="\t")
    df_losum.columns = ["section", "lane", "topbot", "colbeg", "colend"]

    row_losum = df_losum[df_losum["section"] == args.section].iloc[0]
    print(f"The layout summary for {args.section}:\n{row_losum}\n")

    create_layout_from_summary(args.sbcd_part_dir, row_losum,  args.section)
    create_manifest(args.sbcd_dir, args.sbcd_part_dir, row_losum,input_type="summary")
elif args.input_type == "layout":
    print("Input: layout file\n")
    create_manifest(args.sbcd_dir, args.sbcd_part_dir, input_type="layout", input_layout=args.input)
