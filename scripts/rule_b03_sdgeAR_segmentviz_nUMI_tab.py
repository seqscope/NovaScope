import pandas as pd
import gzip
import argparse
import os
import matplotlib.pyplot as plt
import numpy as np

def read_tsv_gz(file_path):
    assert os.path.exists(file_path), f"File not found: {file_path}"
    with gzip.open(file_path, 'rt') as f:
        return pd.read_csv(f, sep='\t')

def read_mtx_gz(file_path):
    assert os.path.exists(file_path), f"File not found: {file_path}"
    with gzip.open(file_path, 'rt') as f:
        return pd.read_csv(f, sep=' ', skiprows=3, header=None, names=['feature', 'random_index', 'nUMI'])

def numi_per_hex(args):
    hex_widths = args.hex_width.split(',')
    # df: nhex per numi_cutoff across hex_width 
    df = pd.DataFrame(columns=['nUMI_cutoff', 'nhex', 'hex_width'])
    for hex_width in hex_widths:
        # df_sge: nUMI per feature per hexagon for one hex_width
        if args.format == "ficture":
            sge_path=os.path.join(args.in_dir, args.solo_feature+".den_"+args.density_filter+"."+hex_width, f"{args.unit_id}.{args.solo_feature}.den_{args.density_filter}.{hex_width}.hexagon.tsv.gz")
            df_sge=read_tsv_gz(sge_path)
        elif args.format == "10x":
            sge_path=os.path.join(args.in_dir, args.solo_feature+".den_"+args.density_filter+"."+hex_width, "10x", "matrix.mtx.gz")
            df_sge=read_mtx_gz(sge_path)
            df_sge[args.solo_feature]=df_sge['nUMI']
        # df_hex: nUMI per hexagon for one hex_width
        df_hex=df_sge.groupby('random_index', as_index=False)[args.solo_feature].sum()
        df_hex=df_hex.sort_values(by=args.solo_feature, ascending=True)
        if args.write_numi_per_width:
            numi_dir=os.path.dirname(sge_path)
            numi_path=os.path.join(numi_dir, f"{args.unit_id}.{args.solo_feature}.den_{args.density_filter}.{hex_width}.numi_per_hex.{args.format}.tsv")
            df_hex.to_csv(numi_path, index=False, header=True,sep="\t")
        # df_cutoff: nhex per numi_cutoff for one hex_width
        cutoff_list = [] 
        for cutoff in cutoffs:
            nhex = df_hex[df_hex[args.solo_feature] >= cutoff].shape[0]
            cutoff_list.append([cutoff, nhex, hex_width])
        df_cutoff = pd.DataFrame(cutoff_list, columns=['nUMI_cutoff', 'nhex', 'hex_width'])
        df = pd.concat([df, df_cutoff], ignore_index=True)
    print(f"Output: {args.output}")
    df.to_csv(args.output, index=False, header=True,sep="\t")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process TSV.GZ files and filter data.')
    parser.add_argument('-i', '--in-dir', type=str, help='Input file directory')
    parser.add_argument('-u', '--unit-id', type=str, help='Unit ID')
    parser.add_argument('-m', '--format', type=str, choices=["ficture", "10x"], help='hexagon')
    parser.add_argument('-s', '--solo_feature', default="gn", type=str, help='Solo feature')
    parser.add_argument('-a', '--density_filter', default="auto", type=str, help='Auto density')
    parser.add_argument('-o', '--output', type=str, default=None, help='Output CSV file path')
    parser.add_argument('-c', '--cutoffs', type=str, default="10,20,30,40,50,100,200,300,400,500,1000,2000,3000,5000", help='Comma-separated list of cutoffs')
    parser.add_argument('-l', '--hex-width', type=str, default="d_12,d_18,d_24,d_36,d_48,d_72,d_96,d_120", help='Comma-separated list of hex_widths (hex_width) for the input files')
    parser.add_argument('-w', '--write-numi-per-width', action='store_true', default=False, help='Write nUMI per hexagon for each hexagon width')
    args = parser.parse_args()
    '''
    # ficture
    python /nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope/scripts/rule_b03_sdgeAR_segmentviz_nUMI_tab.py \
        --in-dir /nfs/turbo/umms-leeju/nova/v2/analysis/n9-hgc2m-b06-07c-mouse-714e6/n9-hgc2m-b06-07c-mouse-714e6-default/segment \
        --format ficture \
        --density_filter auto \
        --unit-id n9-hgc2m-b06-07c-mouse-714e6-default
    args.in_dir="/nfs/turbo/umms-leeju/nova/v2/analysis/n9-hgc2m-b06-07c-mouse-714e6/n9-hgc2m-b06-07c-mouse-714e6-default/segment"
    args.unit_id="n9-hgc2m-b06-07c-mouse-714e6-default"
    args.solo_feature="gn"
    args.density_filter="auto"
    args.hex_width="d_12,d_18,d_24,d_36,d_48,d_72,d_96"
    args.cutoffs="10,20,30,40,50,100,200,300,400,500,1000,2000,3000,5000"
    # 10x
    python /nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaScope/scripts/rule_b03_sdgeAR_segmentviz_nUMI_tab.py \
        --in-dir /nfs/turbo/umms-leeju/nova/v2/analysis/n9-hgc2m-b06-07c-mouse-714e6/n9-hgc2m-b06-07c-mouse-714e6-default/segment \
        --format 10x \
        --density_filter raw \
        --unit-id n9-hgc2m-b06-07c-mouse-714e6-default \
        --write-numi-per-width
    args.in_dir="/nfs/turbo/umms-leeju/nova/v2/analysis/n9-hgc2m-b06-07c-mouse-714e6/n9-hgc2m-b06-07c-mouse-714e6-default/segment"
    args.unit_id="n9-hgc2m-b06-07c-mouse-714e6-default"
    args.solo_feature="gn"
    args.density_filter="raw"
    args.hex_width="d_12,d_18,d_24,d_36,d_48,d_72,d_96,d_120"
    args.cutoffs="10,20,30,40,50,100,200,300,400,500,1000,2000,3000,5000"
    '''
    # output 
    if args.output is None:    
        args.output = os.path.join(args.in_dir, f"{args.unit_id}.{args.solo_feature}.den_{args.density_filter}.hexagon_nUMI.{args.format}.tsv")
    # cutoffs
    cutoffs = list(map(int, args.cutoffs.split(',')))
    numi_per_hex(args)


