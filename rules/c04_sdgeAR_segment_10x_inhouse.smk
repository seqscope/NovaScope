rule c04_sdgeAR_segment_10x_inhouse:
    input:
        sdgeAR_xyrange  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),    # Use sdgeAR_xyrange instead of xyrange_in to determine the major axis is because the transcript was sorted by the longer axis in sdgeAR_xyrange and the longer axis may be different between sdgeAR_xyrange and xyrange.
        transcript_in   = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", ("{unit_id}.transcripts.tsv.gz" if wildcards.sge_qc=="raw" else "{unit_id}.{solo_feature}."+wildcards.sge_qc+".transcripts.tsv.gz")),
        ftr_in          = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", ("{unit_id}.feature.tsv.gz"     if wildcards.sge_qc=="raw" else "{unit_id}.{solo_feature}."+wildcards.sge_qc+".feature.tsv.gz")),
        boundary_in     = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.boundary.strict.geojson") if wildcards.sge_qc == "filtered" else [],
        xyrange_in      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv"),    # This file is not used but is required to make sure every transcript file has a corresponding xyrange file.
    output:
        # hexagon_bcd      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "barcodes.tsv.gz"),
        # hexagon_ftr      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "features.tsv.gz"),
        # hexagon_mtx      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "matrix.mtx.gz"),
        hexagon_log         = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.d_{hexagon_width}.10x.log")
    params:
        solo_feature        = "{solo_feature}",
        hexagon_width       = "{hexagon_width}",
        sge_qc              = "{sge_qc}",
        hex_n_move          = config.get("downstream", {}).get('segment', {}).get('hex_n_move', 1), 
        precision           = config.get("downstream", {}).get('segment', {}).get('precision', 2), 
        min_density_per_unit = config.get("downstream", {}).get('segment', {}).get('10x', {}).get('min_density_per_unit', 0.01), 
        min_ct_per_unit     = config.get("downstream", {}).get('segment', {}).get('10x', {}).get('min_ct_per_unit', 10),        # module
        module_cmd          = get_envmodules_for_rule(["python", "samtools"], module_config),
    resources:
        mem  = "7000MB", 
        time = "12:00:00",
    run:
        # major axis
        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col") 
        # dirs/files
        hexagon_dir = os.path.join(os.path.dirname(output.hexagon_log), "10x")
        hexagon_bcd = os.path.join(hexagon_dir, "barcodes.tsv.gz")
        hexagon_ftr = os.path.join(hexagon_dir, "features.tsv.gz")
        hexagon_mtx = os.path.join(hexagon_dir, "matrix.mtx.gz")
        
        if params.sge_qc == "filtered":
            boundary_args = f"--boundary {input.boundary_in}"
        else:
            boundary_args = ""
        
        # Check if the segmentation is done in the previous runs
        if os.path.exists(hexagon_bcd) and os.path.exists(hexagon_ftr) and os.path.exists(hexagon_mtx):
            with open(output.hexagon_log, "w") as f:
                f.write("Done")
        # if the segmentation is not done, do the segmentation
        else:
            # Attempt to do segmentation
            try:
                shell(
                r"""
                set -euo pipefail
                {params.module_cmd}

                command time -v {python} {ficture}/ficture/scripts/make_sge_by_hexagon.py \
                    --input {input.transcript_in} \
                    --feature {input.ftr_in} \
                    --output_path {hexagon_dir} \
                    --mu_scale {mu_scale} \
                    --major_axis {major_axis} \
                    --key {params.solo_feature} \
                    --precision {params.precision} \
                    --hex_width {params.hexagon_width} \
                    --n_move {params.hex_n_move} \
                    --min_ct_per_unit {params.min_pixel_per_unit} \
                    --transfer_gene_prefix {boundary_args}
                """
                )
                # write down a log file to indicate the segmentation is done
                with open(output.hexagon_log, "w") as f:
                    f.write("Done")
            # add an exception to catch the error, which may happen when the dataset is shallow
            except Exception as e:
                with open(output.hexagon_log, "w") as f:
                    f.write("Failed")

        
