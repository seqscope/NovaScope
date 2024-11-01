# This is not applied in the NovaScope. 
import os
import argparse
import subprocess

def create_layout(outprefix, lane, tile1, tile2, colshift, shifttype):
    layout = f"{outprefix}.{shifttype}shift.layout.tsv"
    if shifttype == "odd":
        with open(layout, 'w') as f:
            f.write(f"lane\ttile\trow\tcol\trowshift\tcolshift\n")
            f.write(f"{lane}\t{tile1}\t1\t1\t0\t0\n")
            f.write(f"{lane}\t{tile2}\t2\t1\t0\t{colshift}\n")
    elif shifttype == "even":
        with open(layout, 'w') as f:
            f.write(f"lane\ttile\trow\tcol\trowshift\tcolshift\n")
            f.write(f"{lane}\t{tile1}\t1\t1\t0\t{colshift}\n")
            f.write(f"{lane}\t{tile2}\t2\t1\t0\t0\n")

def main():
    parser = argparse.ArgumentParser(description="Process some parameters.")
    parser.add_argument('--sbcd-dir','-i', type=str, help='The input sbcd directory for the specific lane, which should have a manifest.tsv file.') # example: /home/weiqiuc/task2/output/nova_v2/seq1st/N11-HTVJK/sbcds/L1
    parser.add_argument('--output-dir','-o', type=str, help='The output directory')
    parser.add_argument('--flowcell-id','-fcid', type=str, help='Flowcell ID. If absent, it will be inferred from --sbcd-dir')
    parser.add_argument('--lane','-l', type=int, default=None, help='Lane. When absent, the lane information will be interpreted from --sbcd-dir')
    parser.add_argument('--top-tile-start', '-tts', type=int, nargs='?', default=1644, help='Top tile start id (default: 1644)')
    parser.add_argument('--top-tile-end', '-tte', type=int, nargs='?', default=1544, help='Top tile end id (default: 1544)')
    parser.add_argument('--bottom-tile-start', '-bts', type=int, nargs='?', default=2644, help='Bottom tile start id (default: 2644)')
    parser.add_argument('--bottom-tile-end', '-bte', type=int, nargs='?', default=2544, help='Bottom tile end id (default: 2544)')
    parser.add_argument('--colshift', type=float, nargs='?', default=0.1715, help='Column shift (default: 0.1715)')
    parser.add_argument('--rowgap', type=float, nargs='?', default=0.0517, help='Row gap (default: 0.0517)')
    parser.add_argument('--colgap', type=float, nargs='?', default=0.0048, help='Column gap (default: 0.0048)')
    parser.add_argument('--maxdup', type=int, nargs='?', default=1, help='Max duplicates (default: 1)')
    parser.add_argument('--maxdist', type=int, nargs='?', default=1, help='Max duplicate distance (default: 1)')
    parser.add_argument('--spatula', type=str, nargs='?', default=None, help='Path to spatula binary')

    args = parser.parse_args()

    # dirs/files
    sbcd_mnfst = f"{args.sbcd_dir}/manifest.tsv"
    if args.flowcell_id is None:
        ## example sbcd_dir: /home/weiqiuc/task2/output/nova_v2/seq1st/N11-HTVJK/sbcds/L1
        args.flowcell_id = os.path.basename(os.path.dirname(os.path.dirname(args.sbcd_dir)))
    if args.lane is None:
        args.lane = int(os.path.basename(args.sbcd_dir).replace("L", ""))
    
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Create layouts
    loc2tile={
        "top":{
            "start":args.top_tile_start,
            "end":args.top_tile_end
        },
        "bottom":{
            "start":args.bottom_tile_start,
            "end":args.bottom_tile_end
        }
    }
    
    for loc in loc2tile:
        print(f"Processing {loc} tiles")
        tile_s=loc2tile[loc]["start"]
        tile_e=loc2tile[loc]["end"]
        for shifttype in ["odd", "even"]:
            print(f"Processing {shifttype} shift")
            out_prefix=f"{args.output_dir}/{args.flowcell_id}_{args.lane}_{tile_s}_{tile_e}.{shifttype}shift"
            # Create layout
            layout=f"{out_prefix}.layout.tsv"
            print("1. Creating layout:", layout)
            create_layout(out_prefix, args.lane, tile_s, tile_e, args.colshift, shifttype)
            # Combine sbcds
            nbcds_dir=f"{out_prefix}.nbcds"
            combine_sbcds_cmd = [
                args.spatula, 'combine-sbcds',
                '--layout', layout,
                '--manifest', sbcd_mnfst,
                '--sbcd', args.sbcd_dir,
                '--out', nbcds_dir,
                '--rowgap', str(args.rowgap),
                '--colgap', str(args.colgap),
                '--max-dup', str(args.maxdup),
                '--max-dup-dist-nm', str(args.maxdist)
            ]
            print("2. Combine sbcds:")
            print(" ".join(combine_sbcds_cmd))
            subprocess.run(combine_sbcds_cmd)
            # Draw xy
            nbcd_tsv=f"{nbcds_dir}/1_1.sbcds.sorted.tsv.gz"
            xy_png=f"{out_prefix}.nbcds.png"
            draw_xy_cmd = [
                args.spatula, 'draw-xy',
                '--tsv', f"{nbcd_tsv}",
                '--out', f"{xy_png}",
                '--coord-per-pixel', '1000',
                '--icol-x', '3',
                '--icol-y', '4',
                '--intensity-per-obs', '50'
            ]
            print("3. Drawing xy:")
            print(" ".join(draw_xy_cmd))
            subprocess.run(draw_xy_cmd)

if __name__ == '__main__':
    main()
