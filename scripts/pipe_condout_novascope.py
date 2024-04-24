# Generate output file name by request
# for upstream pipeline (NovaScope)

def output_fn_sbcdperfc(main_dirs, df_run):
    outfn= {
        'flag': 'sbcd-per-flowcell',
        'root': main_dirs["seq1st"],
        'subfolders_patterns': [
                                (["{flowcell}", "sbcds", "{seq1_id}", "manifest.tsv"], None),
        ],
        'zip_args': {
            'flowcell':    df_run["flowcell"].values,
            'seq1_id':     df_run["seq1_id"].values,
        },
    }
    return outfn

def output_fn_sbcdperchip(main_dirs, df_run):
    outfn = {
        'flag': 'sbcd-per-chip',
        'root': main_dirs["seq1st"],
        'subfolders_patterns': [
                                (["{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.tsv.gz"], None),
                                (["{flowcell}", "nbcds", "{chip}", "manifest.tsv"], None),
                                (["{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.png"], None),
        ],
        'zip_args': {
            'flowcell':     df_run["flowcell"].values,
            'chip':         df_run["chip"].values,
        },
    }
    return outfn

def output_fn_smatchperchip(main_dirs, df_seq2):
    outfn = {
        'flag': 'smatch-per-chip',
        'root': main_dirs["match"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.match.sorted.uniq.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.summary.tsv"], None),
                                (["{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.counts.tsv"], None),
                                (["{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.match.png"], None),
        ],
        'zip_args': {
            'flowcell':      df_seq2["flowcell"].values,
            'chip':          df_seq2["chip"].values,
            'seq2_id':       df_seq2["seq2_id"].values,  
        },
    }
    return outfn

def output_fn_alignperrun(main_dirs, df_run):
    outfn = {
        'flag': 'align-per-run',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "barcodes.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "features.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Gene",     "raw", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "spliced.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "unspliced.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "ambiguous.mtx.gz"], None),
        ],
        'zip_args': {
            'flowcell':     df_run["flowcell"].values,
            'chip':         df_run["chip"].values,
            'run_id':       df_run["run_id"].values,
        },
    }
    return outfn


def output_fn_sgeperrun(main_dirs, df_run):
    out_fn ={
        'flag': 'sge-per-run',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "features.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.gene_full_mito.png"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_match_sbcd.png"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.gene_visual.tar.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.minmax.tsv"], None),
        ],
        'zip_args': {
            'flowcell':     df_run["flowcell"].values,
            'chip':         df_run["chip"].values,
            'run_id':       df_run["run_id"].values,
        },
    }
    return out_fn

def output_fn_histperrun(main_dirs, df_hist):
    out_fn = {
        'flag': 'hist-per-run',
        'root': main_dirs["histology"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "aligned", "{run_id}", "{hist_std_prefix}.tif"], None),
                                (["{flowcell}", "{chip}", "aligned", "{run_id}", "{hist_std_prefix}-fit.tif"], None),
        ],
        'zip_args': {
            'flowcell':         df_hist["flowcell"].values,
            'chip':             df_hist["chip"].values,
            'run_id':           df_hist["run_id"].values,  
            'hist_std_prefix':  df_hist["hist_std_prefix"].values, 
        },
    }
    return out_fn


def output_fn_segmperunit(main_dirs, df_segment_char):
    out_fn = {
            'flag': 'segment-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}.d_{tw}.raw_{seg_nmove}", "barcodes.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}.d_{tw}.raw_{seg_nmove}", "features.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "segment", "{sf}.d_{tw}.raw_{seg_nmove}", "matrix.mtx.gz"  ], None),                     
            ],
            'zip_args': {
                'run_id':       df_segment_char["run_id"].values,  
                'unit_id':      df_segment_char["unit_id"].values,
                'sf':           df_segment_char["solofeature"].values,
                'tw':           df_segment_char["trainwidth"].values,
                'seg_nmove':    df_segment_char['segmentmove'].values,
            },
    }
    return out_fn

def output_fn_transperunit(main_dirs, df_segment_char):
    out_fn = {
            'flag': 'transcript-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "preprocess", "{unit_id}.merged.matrix.tsv.gz"  ], None),
                                    ([ "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.clean.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz"      ], None),                     
            ],
            'zip_args': {
                'run_id':       df_segment_char["run_id"].values,  
                'unit_id':      df_segment_char["unit_id"].values,
            },
    }
    return out_fn
