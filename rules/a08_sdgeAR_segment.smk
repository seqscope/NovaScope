rule a08_sdgeAR_segment:
    input:
        sdgeAR_xyrange       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_transcript    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"),
        sdgeAR_ftr_tab       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz"),
    output:
        sdgeAR_seg_raw_bcd   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.d_{hexagon_width}.raw_{segment_move}", "barcodes.tsv.gz"),
        sdgeAR_seg_raw_ftr   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.d_{hexagon_width}.raw_{segment_move}", "features.tsv.gz"),
        sdgeAR_seg_raw_mtx   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.d_{hexagon_width}.raw_{segment_move}", "matrix.mtx.gz"),
    params:
        solo_feature         = "{solo_feature}",
        hexagon_width       = "{hexagon_width}",
        n_move              = "{segment_move}",
        precision           = config.get("downstream", {}).get('segment', {}).get('precision', 2), 
        min_pixel_per_unit  = config.get("downstream", {}).get('segment', {}).get('min_pixel_per_unit', 10), 
        # module
        module_cmd        = get_envmodules_for_rule(["python", "samtools"], module_config),
    resources:
        mem  = "7000MB", 
        time = "12:00:00",
    run:
        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col")
        # dirs
        sdgeAR_seg_raw_dir = os.path.dirname(output.sdgeAR_seg_raw_bcd)
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
            --key {params.solo_feature} \
            --precision {params.precision} \
            --hex_width {params.hexagon_width} \
            --n_move {params.n_move} \
            --min_ct_per_unit {params.min_pixel_per_unit} \
            --transfer_gene_prefix

        """
        )
