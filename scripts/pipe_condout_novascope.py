# Generate output file name by request
# for upstream pipeline (NovaScope)
import pandas as pd
#===============================================================================
#
#        Output files for each run
#
#===============================================================================

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

def outfnlist_by_run(main_dirs, df_run):
    outfnlist = [
    outfn_sbcd_per_fc(main_dirs, df_run),
    outfn_sbcd_per_chip(main_dirs, df_run),
    outfn_align_per_run(main_dirs, df_run),
    outfn_trans_per_unit(main_dirs, df_run),
    outfn_filterftr_per_unit(main_dirs, df_run)
    ]
    return outfnlist

#===============================================================================
#
#        Output files for each lane & tile pair, seq2 id, sgevisual id, histology id
#
#===============================================================================

# - lane & tile1 & tile2
def outfn_sbcdlo_per_tilepair(main_dirs, df_sbcdlo):
    df_sbcdlo["lane"]=df_sbcdlo["seq1_id"].str.replace("L", "", regex=False)
    outfn= {
        'flag': 'sbcdlo-per-flowcell',
        'root': main_dirs["seq1st"],
        'subfolders_patterns': [
                                (["{flowcell}", "images", "{flowcell}.{lane}.{layer}.{tile_1}_{tile_2}.evenshift.nbcds.png"], None),
                                (["{flowcell}", "images", "{flowcell}.{lane}.{layer}.{tile_1}_{tile_2}.oddshift.nbcds.png"], None),
        ],
        'zip_args': {
            'flowcell':    df_sbcdlo["flowcell"].values,
            'lane':        df_sbcdlo["lane"].values,
            'layer':       df_sbcdlo["layer"].values,
            'tile_1':      df_sbcdlo["tile_1"].values,
            'tile_2':      df_sbcdlo["tile_2"].values,
        },
    }
    return outfn

# seq2id
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

# run_id & (optional) sgevisual_id 
def outfn_sge_per_run(main_dirs, df_sge, drawsge):
    out_fn ={
        'flag': 'sge-per-run',
        'root': main_dirs["align"],
        'subfolders_patterns': [
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "features.tsv.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "matrix.mtx.gz"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_match_sbcd.png"], None),
                                (["{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_visual", "{sgevisual_id}.png"], lambda: drawsge is True),
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

#===============================================================================
#
#        Output files for each segchar id
#
#===============================================================================

def outfn_filterpoly_per_unit(main_dirs, df_segchar, resilient):
    df_segchar = df_segchar[["run_id", "unit_id", "solo_feature", "sge_qc"]]   # only keep the required columns
    df_segchar = df_segchar[df_segchar["sge_qc"] == "filtered"] # note this only applies to sge_qc = "filtered"
    out_fn = {
            'flag': 'filterpoly-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.transcripts.tsv.gz"], lambda: resilient is False),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.transcripts.tsv.gz.tbi"], lambda: resilient is False),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.coordinate_minmax.tsv"], lambda: resilient is False),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.feature.strict.tsv.gz"], lambda: resilient is False),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.boundary.strict.geojson"], lambda: resilient is False),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.feature.lenient.tsv.gz"], lambda: resilient is False),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.boundary.lenient.geojson"], lambda: resilient is False),
                    (["{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.log"], lambda: resilient is True),
            ],
            'zip_args': {
                'run_id':        df_segchar["run_id"].values,  
                'unit_id':       df_segchar["unit_id"].values,
                'solo_feature':  df_segchar["solo_feature"].values,
            },
    }
    return out_fn

def outfn_seg10x_per_unit(main_dirs, df_segchar, resilient):
    out_fn = {
            'flag': 'segment-10x-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "barcodes.tsv.gz"],  lambda: resilient is False),
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "features.tsv.gz"],  lambda: resilient is False),
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "matrix.mtx.gz"  ],  lambda: resilient is False),   
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.10x.d_{hexagon_width}.log"], lambda: resilient is True)
            ],
            'zip_args': {
                'run_id':        df_segchar["run_id"].values,  
                'unit_id':       df_segchar["unit_id"].values,
                'solo_feature':  df_segchar["solo_feature"].values,
                'hexagon_width': df_segchar["hexagon_width"].values,
                'sge_qc':        df_segchar["sge_qc"].values,
            },
    }
    return out_fn

def outfn_segfict_per_unit(main_dirs, df_segchar, resilient):
    out_fn = {
            'flag': 'segment-ficture-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.d_{hexagon_width}.hexagon.tsv.gz"], lambda: resilient is False),
                                    ([ "{run_id}", "{unit_id}", "segment",    "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.ficture.d_{hexagon_width}.log"], lambda: resilient is True)
            ],
            'zip_args': {
                'run_id':        df_segchar["run_id"].values,  
                'unit_id':       df_segchar["unit_id"].values,
                'solo_feature':  df_segchar["solo_feature"].values,
                'hexagon_width': df_segchar["hexagon_width"].values,
                'sge_qc':        df_segchar["sge_qc"].values,
            },
    }
    return out_fn

def outfn_segviz_per_unit(main_dirs, df_segchar, segmentviz):
    df_segchar = pd.DataFrame( [{**row, 'segviz_format': viz_format} for _, row in df_segchar.iterrows() for viz_format in segmentviz])
    out_fn = {
            'flag': 'segment-viz-per-unit',
            'root': main_dirs["analysis"],
            'subfolders_patterns': [
                                    ([ "{run_id}", "{unit_id}", "segment", "{unit_id}.{solo_feature}.raw.{segviz_format}.segmentviz.log"], None),
                                    ([ "{run_id}", "{unit_id}", "segment", "{unit_id}.{solo_feature}.filtered.{segviz_format}.segmentviz.log"], None),
            ],
            'zip_args': {
                'run_id':        df_segchar["run_id"].values,
                'unit_id':       df_segchar["unit_id"].values,
                'solo_feature':  df_segchar["solo_feature"].values,
                'segviz_format': df_segchar["segviz_format"].values,
            },
    }
    return out_fn

def outfnlist_by_seg(main_dirs, df_segchar, resilient, segmentviz):
    outfnlist = []
    outfnlist.append(outfn_filterpoly_per_unit(main_dirs, df_segchar, resilient))
    if segmentviz:
        df_seg_viz= df_segchar[['run_id', 'unit_id', 'solo_feature']].drop_duplicates().reset_index(drop=True)
        outfnlist.append(outfn_segviz_per_unit(main_dirs, df_seg_viz, segmentviz))
    df_segchar_10x= df_segchar[df_segchar["sge_format"] == "10x"]
    if not df_segchar_10x.empty:
        outfnlist.append(outfn_seg10x_per_unit(main_dirs, df_segchar_10x, resilient))
    df_segchar_ficture= df_segchar[df_segchar["sge_format"] == "ficture"]
    if not df_segchar_ficture.empty:
        outfnlist.append(outfn_segfict_per_unit(main_dirs, df_segchar_ficture, resilient))
    return outfnlist
