rule c04_sdgeAR_segment_10x:
    input:
        sdgeAR_xyrange      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_transcript   = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz") if wildcards.sge_qc=="raw" else os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}."+wildcards.sge_qc+".transcripts.tsv.gz"),
        sdgeAR_ftr_tab      = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz")     if wildcards.sge_qc=="raw" else os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}."+wildcards.sge_qc+".feature.tsv.gz"),
    output:
        sdgeAR_seg_bcd      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "barcodes.tsv.gz"),
        sdgeAR_seg_ftr      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "features.tsv.gz"),
        sdgeAR_seg_mtx      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "matrix.mtx.gz"),
    params:
        solo_feature        = "{solo_feature}",
        hexagon_width       = "{hexagon_width}",
        hex_n_move          = config.get("downstream", {}).get('segment', {}).get('hex_n_move', 1), 
        precision           = config.get("downstream", {}).get('segment', {}).get('precision', 2), 
        min_pixel_per_unit  = config.get("downstream", {}).get('segment', {}).get('10x', {}).get('min_pixel_per_unit', 10), 
        # module
        module_cmd          = get_envmodules_for_rule(["python", "samtools"], module_config),
    resources:
        mem  = "7000MB", 
        time = "12:00:00",
    run:
        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col")
        # dirs
        sdgeAR_seg_dir = os.path.dirname(output.sdgeAR_seg_bcd)
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        command time -v {python} {ficture}/ficture/scripts/make_sge_by_hexagon.py \
            --input {input.sdgeAR_transcript} \
            --feature {input.sdgeAR_ftr_tab} \
            --output_path {sdgeAR_seg_dir} \
            --mu_scale {mu_scale} \
            --major_axis {major_axis} \
            --key {params.solo_feature} \
            --precision {params.precision} \
            --hex_width {params.hexagon_width} \
            --n_move {params.hex_n_move} \
            --min_ct_per_unit {params.min_pixel_per_unit} \
            --transfer_gene_prefix

        """
        )
