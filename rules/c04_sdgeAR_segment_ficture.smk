rule c04_sdgeAR_segment_ficture:
    input:
        sdgeAR_xyrange      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),    # Use sdgeAR_xyrange instead of xyrange_in to determine the major axis is because the transcript was sorted by the longer axis in sdgeAR_xyrange and the longer axis may be different between sdgeAR_xyrange and xyrange.
        transcript_in       = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", ("{unit_id}.{solo_feature}."+wildcards.sge_qc+".transcripts.tsv.gz" if wildcards.sge_qc == "filtered" else "{unit_id}.transcripts.tsv.gz")),
        boundary_in         = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.boundary.strict.geojson") if wildcards.sge_qc == "filtered" else [],
        xyrange_in          = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv"),    # This file is not used but is required to make sure every transcript file has a corresponding xyrange file.
    output:
        hexagon             = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.d_{hexagon_width}.hexagon.tsv.gz"),
    params:
        solo_feature        = "{solo_feature}",
        train_width         = "{hexagon_width}",
        sge_qc              = "{sge_qc}",
        hex_n_move          = config.get("downstream", {}).get('segment', {}).get('hex_n_move', 1), 
        precision           = config.get("downstream", {}).get('segment', {}).get('precision', 2), 
        min_density         = config.get("downstream", {}).get('segment', {}).get('ficture', {}).get('min_density', 0.3),
        # module
        module_cmd          = get_envmodules_for_rule(["python", "samtools"], module_config)
    resources:
        mem  = "28000MB", 
        time = "72:00:00"
    run:
        # major axis
        major_axis       = find_major_axis(input.sdgeAR_xyrange, format="col")
        # dirs/files
        hexagon_unzip = output.hexagon.rstrip(".gz")

        if params.sge_qc == "filtered":
            boundary_args = f"--boundary {input.boundary_in}"
        else:
            boundary_args = ""

        if isinstance(params.hex_n_move, float):
            params.hex_n_move = int(params.hex_n_move)
        
        shell(
        r"""
        {params.module_cmd}
        source {pyenv}/bin/activate

        ### skip the --ct_header to use the default value.
        command time -v {python} {ficture}/ficture/scripts/make_dge_univ.py \
            --input {input.transcript_in} \
            --output {hexagon_unzip} \
            --mu_scale {mu_scale} \
            --key {params.solo_feature} \
            --hex_width {params.train_width} \
            --min_density_per_unit {params.min_density} \
            --n_move {params.hex_n_move} \
            --precision {params.precision} \
            --major_axis {major_axis} {boundary_args}
            
        ## Shuffle hexagon
        sort -S 10G -k1,1n {hexagon_unzip} | gzip -c > {output.hexagon}  

        if [ -f {hexagon_unzip} ]; then
            rm {hexagon_unzip}
        fi
        """
        )



