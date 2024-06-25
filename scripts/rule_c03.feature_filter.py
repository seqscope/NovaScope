import gzip
import re
import argparse
import subprocess
import pandas as pd

def read_gzip_file(file_path, header="infer"):
    with gzip.open(file_path, 'rt') as f:
        return pd.read_csv(f, sep='\t', header=header)

def write_gzip_file(df, file_path):
    with gzip.open(file_path, 'wt') as f:
        df.to_csv(f, sep='\t', index=False, compression='gzip')

def gene_filter_by_count(df, min_ct_per_feature):
    return df[df['gt'].astype(int) >= min_ct_per_feature]

def gene_filter_by_regex(df, regex):
    return df[~df['gene'].str.contains(regex, regex=True)] #"^Gm\d+|^mt-|^MT-"

def gene_filter_by_type(df, geneinfo_path, kept_gene_type):
    geneinfo_df = read_gzip_file(geneinfo_path, header=None)
    geneinfo_df.columns = ['chrom', 'start', 'end', 'gene_id', 'gene', 'type']
    geneinfo_df = geneinfo_df[geneinfo_df['type'].str.contains(kept_gene_type)] 
    gene_set = set(geneinfo_df.iloc[:, 3])
    return df[df['gene_id'].isin(gene_set)]

def main():
    parser = argparse.ArgumentParser(description="Feature filtering script.")
    parser.add_argument('--input', help="Path to the input feature file (gzipped)")
    parser.add_argument('--output', help="Path to the output filtered feature file (gzipped)")
    parser.add_argument('--geneinfo', help="Path to the gene info file (gzipped)")
    parser.add_argument('--min_ct_per_feature', type=int, default=0, help="Minimum count per feature")
    parser.add_argument('--rm_gene_regex', default="", help="Regex pattern to remove genes")
    parser.add_argument('--kept_gene_type', default="", help="Kept gene types (|-separated)")
    args = parser.parse_args()

    """ 
    # test 
    args.input = "/nfs/turbo/umms-leeju/nova/v2/analysis/n8-htwlw-b07c-mm10gg6ascribble-bec99/n8-htwlw-b07c-mm10gg6ascribble-bec99-default/preprocess/n8-htwlw-b07c-mm10gg6ascribble-bec99-default.feature.tsv.gz"
    args.output = "/nfs/turbo/umms-leeju/nova/v2/analysis/n8-htwlw-b07c-mm10gg6ascribble-bec99/n8-htwlw-b07c-mm10gg6ascribble-bec99-default/preprocess/n8-htwlw-b07c-mm10gg6ascribble-bec99-default.feature.clean.tsv.gz"
    args.min_ct_per_feature = 50
    args.rm_gene_regex = "^mm10_____Gm\d+|^mm10_____mt-|^mm10_____MT-"
    args.rm_gene_regex = "^mm10_____Gm\d+|^mm10_____mt-|^mm10_____MT-"
    args.geneinfo = "/nfs/turbo/sph-hmkang/index/data/weiqiuc/NovaFlow/misc/create_geneinfo/mm10gg6ascribble.mm10gg6a.mix.names.tsv.gz"
    args.kept_gene_type = "protein_coding|lncRNA"
    """

    gct = True if args.min_ct_per_feature > 0 else False
    gname = True if args.rm_gene_regex != "" else False
    gtype = True if args.kept_gene_type != "" else False
    
    # Read the input feature file
    feature_df = read_gzip_file(args.input,header="infer")

    if gct+gname+gtype > 0:
        # Initialize the output file with the header
        header = "gene_id\tgene\tgn\tgt\tspl\tunspl\tambig"
        with gzip.open(args.output, 'wt') as f:
            f.write(header + "\n")

        # Apply filters
        if gct:
            print(f"Gene filtering by count: Use {args.min_ct_per_feature}...")
            feature_df = gene_filter_by_count(feature_df, args.min_ct_per_feature)
            feature_df.reset_index(drop=True, inplace=True)
        else:
            print(f"Gene filtering by count: Skip...")

        if gname:
            print(f"Gene filtering by regex: Use {args.rm_gene_regex}...")
            feature_df = gene_filter_by_regex(feature_df, args.rm_gene_regex)
            feature_df.reset_index(drop=True, inplace=True)
        else:
            print(f"Gene filtering by regex: Skip...")

        if gtype:
            print(f"Gene filtering by gene type: Use {args.kept_gene_type}...")
            feature_df = gene_filter_by_type(feature_df, args.geneinfo, args.kept_gene_type.replace(",", "|")) # in case users use comma
            feature_df.reset_index(drop=True, inplace=True)
        else:
            print(f"Gene filtering by gene type: Skip...")
            
        # Write the filtered output file
        write_gzip_file(feature_df, args.output)
    else:
        # If no filters, just ln -s the file
        subprocess.run(['ln', '-s', args.input, args.output])

if __name__ == "__main__":
    main()
