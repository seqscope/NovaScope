# Generate output file name by request
# for upstream pipeline (NovaScope)

def outfn_sbcd_per_fc(main_dirs, df_run):
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

def outfn_sbcd_per_chip(main_dirs, df_run):
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

def outfn_smatch_per_chip(main_dirs, df_seq2):
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

def outfn_align_per_run(main_dirs, df_run):
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


def outfn_sge_per_run(main_dirs, df_sge):
    out_fn ={
        'flag': 'sge-per-run',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "features.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_match_sbcd.png"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_visual", "{sgevisual_id}.png"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.minmax.tsv"], None),
        ],
        'zip_args': {
            'flowcell':     df_sge["flowcell"].values,
            'chip':         df_sge["chip"].values,
            'run_id':       df_sge["run_id"].values,
            'sgevisual_id': df_sge["sgevisual_id"].values,
        },
    }
    return out_fn

def outfn_hist_per_run(main_dirs, df_hist):
    out_fn = {
        'flag': 'histology-per-run',
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

def outfn_trans_per_unit(main_dirs, df_run):
    out_fn = {
            'flag': 'transcript-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"  ], None),
                                    ([ "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz"      ], None),                     
            ],
            'zip_args': {
                'run_id':       df_run["run_id"].values,  
                'unit_id':      df_run["unit_id"].values,
            },
    }
    return out_fn

def outfn_filterftr_per_unit(main_dirs, df_run):
    out_fn = {
            'flag': 'filterftr-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.clean.tsv.gz"], None),
            ],
            'zip_args': {
                'run_id':       df_run["run_id"].values,  
                'unit_id':      df_run["unit_id"].values,
            },
    }
    return out_fn

def outfn_filterpoly_per_unit(main_dirs, df_segchar):
    # note this only applies to sge_qc = "filtered"
    df_segchar = df_segchar[df_segchar["sge_qc"] == "filtered"]
    out_fn = {
            'flag': 'filterpoly-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.transcripts.tsv.gz"], None),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv"], None),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.feature.tsv.gz"], None),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.boundary.geojson"], None),
            ],
            'zip_args': {
                'run_id':        df_segchar["run_id"].values,  
                'unit_id':       df_segchar["unit_id"].values,
                'solo_feature':  df_segchar["solo_feature"].values,
                'sge_qc':        df_segchar["sge_qc"].values
            },
    }
    return out_fn

def outfn_seg10x_per_unit(main_dirs, df_segchar):
    out_fn = {
            'flag': 'segment-10x-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "barcodes.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "features.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "matrix.mtx.gz"  ], None),   
                                    ([ "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv"], None),              
            ],
            'zip_args': {
                'run_id':        df_segchar["run_id"].values,  
                'unit_id':       df_segchar["unit_id"].values,
                'solo_feature':  df_segchar["solo_feature"].values,
                'hexagon_width': df_segchar["hexagon_width"].values,
                'sge_qc':        df_segchar["sge_qc"].values
            },
    }
    return out_fn


def outfn_segfict_per_unit(main_dirs, df_segchar):
    out_fn = {
            'flag': 'segment-ficture-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.d_{hexagon_width}.hexagon.tsv.gz"], None),
                                    ([ "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv"], None), 
            ],
            'zip_args': {
                'run_id':        df_segchar["run_id"].values,  
                'unit_id':       df_segchar["unit_id"].values,
                'solo_feature':  df_segchar["solo_feature"].values,
                'hexagon_width': df_segchar["hexagon_width"].values,
                'sge_qc':        df_segchar["sge_qc"].values
            },
    }
    return out_fn