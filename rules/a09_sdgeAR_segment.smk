rule a09_sdgeAR_segment:
    input:
        sdgeAR_xyrange       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_transcript    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.merged.matrix.tsv.gz"),
        sdgeAR_ftr_tab       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz"),
        sdgeAR_transcript_qc = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.filtered.matrix.tsv.gz"),
        sdgeAR_ftr_strict    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.strict.tsv.gz"), 
        sdgeAR_bd_strict     = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.boundary.strict.geojson"), 
    output:
        sdgeAR_seg_raw_bcd   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "raw_{seg_nmove}", "barcodes.tsv.gz"),
        sdgeAR_seg_raw_ftr   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "raw_{seg_nmove}", "features.tsv.gz"),
        sdgeAR_seg_raw_mtx   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "raw_{seg_nmove}", "matrix.mtx.gz"),
        sdgeAR_seg_qc_bcd    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "filtered_{seg_nmove}", "barcodes.tsv.gz"),
        sdgeAR_seg_qc_ftr    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "filtered_{seg_nmove}", "features.tsv.gz"),
        sdgeAR_seg_qc_mtx    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{sf}", "d_{tw}", "filtered_{seg_nmove}", "matrix.mtx.gz"),
    params:
        solofeature         = "{sf}",
        train_width         = "{tw}",
        precision           = config.get("sdgeAR", {}).get("segment", {}).get('precision', 2), 
        n_move              = "{seg_nmove}",
        min_pixel_per_unit  = config.get("sdgeAR", {}).get("segment", {}).get('min_pixel_per_unit', 10), 
        # module
        module_cmd        = get_envmodules_for_rule(["python", "samtools"], module_config),
    resources:
        mem  = "7000MB", 
        time = "12:00:00",
    run:
        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col")
        # dirs
        sdgeAR_seg_raw_dir = os.path.dirname(output.sdgeAR_seg_raw_bcd)
        sdgeAR_seg_qc_dir  = os.path.dirname(output.sdgeAR_seg_qc_bcd)
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        command time -v {python} {ficture}/script/make_sge_by_hexagon.py \
            --input {input.sdgeAR_transcript} \
            --feature {input.sdgeAR_ftr_tab} \
            --output_path {sdgeAR_seg_raw_dir} \
            --mu_scale {mu_scale} \
            --major_axis {major_axis} \
            --key {params.solofeature} \
            --precision {params.precision} \
            --hex_width {params.train_width} \
            --n_move {params.n_move} \
            --min_ct_per_unit {params.min_pixel_per_unit} \
            --transfer_gene_prefix

        command time -v {python} {ficture}/script/make_sge_by_hexagon.py \
            --input {input.sdgeAR_transcript_qc} \
            --feature {input.sdgeAR_ftr_strict} \
            --output_path {sdgeAR_seg_qc_dir} \
            --mu_scale {mu_scale} \
            --boundary {input.sdgeAR_bd_strict} \
            --major_axis {major_axis} \
            --key {params.solofeature} \
            --precision {params.precision} \
            --hex_width {params.train_width} \
            --n_move {params.n_move} \
            --min_ct_per_unit {params.min_pixel_per_unit} \
            --transfer_gene_prefix
        """
        )
