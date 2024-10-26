import pandas as pd

uid_req = ["transcript-per-unit", "filterftr-per-unit", "filterpoly-per-unit", "segment-10x-per-unit", "segment-ficture-per-unit"]
rid_req = ["align-per-run", "sge-per-run", "histology-per-run"] + uid_req
seq2id_req = ["sbcd-per-chip", "smatch-per-chip"] + rid_req
sgevisual_req = ["sge-per-run", "histology-per-run"] + uid_req

id2req={
    "unit_id": uid_req,
    "run_id": rid_req,
    "seq2_id": seq2id_req,
    "sgevisual_id": sgevisual_req
}

df_hist_void = pd.DataFrame({
        'flowcell': pd.Series(dtype='object'),
        'chip': pd.Series(dtype='object'),
        'hist_std_prefix': pd.Series(dtype='object'),
        'figtype': pd.Series(dtype='object'),
        'magnification': pd.Series(dtype='object'),
        'run_id': pd.Series(dtype='object'),
    })


df_seg_void = pd.DataFrame({
        'run_id': pd.Series(dtype='object'),
        'unit_id': pd.Series(dtype='object'),
        'solo_feature': pd.Series(dtype='object'),
        'hexagon_width': pd.Series(dtype='int64'), 
        'sge_qc': pd.Series(dtype='object') 
    })


df_seq2_void = pd.DataFrame({
    'id': pd.Series(dtype='object'),
    'fastq_R1': pd.Series(dtype='object'),
    'fastq_R2': pd.Series(dtype='object'),
    'flowcell': pd.Series(dtype='object'),
    'chip': pd.Series(dtype='object'),
    'seq2_id': pd.Series(dtype='object'),
    'seq2_fqr1_raw': pd.Series(dtype='object'),
    'seq2_fqr2_raw': pd.Series(dtype='object'),
    'seq2_fqr1_std': pd.Series(dtype='object'),
    'seq2_fqr2_std': pd.Series(dtype='object'),
})

df_sgevisual_void=pd.DataFrame({
    'flowcell': pd.Series(dtype='object'),
    'chip': pd.Series(dtype='object'),    
    'run_id': pd.Series(dtype='object'),
    'sgevisual_id': pd.Series(dtype='object')
})