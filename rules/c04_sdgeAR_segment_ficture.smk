rule c04_sdgeAR_segment_ficture:
    input:
        sdgeAR_xyrange        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_transcript_qc = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.transcripts.tsv.gz"),
        sdgeAR_bd_qc         = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.boundary.geojson") if wildcards.sge_qc == "auto" else "",
    output:
        sdgeAR_hxg            = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.d_{hexagon_width}.hexagon.tsv.gz"),
    params:
        solo_feature        = "{solo_feature}",
        train_width         = "{hexagon_width}",
        hex_n_move          = config.get("downstream", {}).get('segment', {}).get('hex_n_move', 1), 
        precision           = config.get("downstream", {}).get('segment', {}).get('precision', 2), 
        min_density         = config.get("downstream", {}).get('segment', {}).get('ficture', {}).get('min_density', 0.3),
        # module
        module_cmd          = get_envmodules_for_rule(["python", "samtools"], module_config)
    resources:
        mem  = "28000MB", 
        time = "72:00:00"
    run:
        sdgeAR_hxg_unzip = output.sdgeAR_hxg.rstrip(".gz")

        major_axis       = find_major_axis(input.sdgeAR_xyrange, format="col")

        if os.path.isfile(input.sdgeAR_bd_qc):
            boundary_args = f"--boundary {input.sdgeAR_bd_qc}"
        else:
            boundary_args = ""

        # if hex_n_move is float, convert it to int
        if isinstance(params.hex_n_move, float):
            params.hex_n_move = int(params.hex_n_move)
        shell(
        r"""
        {params.module_cmd}
        source {pyenv}/bin/activate

        ### skip the --ct_header to use the default value.
        command time -v {python} {ficture}/ficture/scripts/make_dge_univ.py \
            --input {input.sdgeAR_transcript_qc} \
            --output {sdgeAR_hxg_unzip} \
            --mu_scale {mu_scale} \
            --key {params.solo_feature} \
            --hex_width {params.train_width} \
            --min_density_per_unit {params.min_density} \
            --n_move {params.hex_n_move} \
            --precision {params.precision} \
            --major_axis {major_axis} \
            {boundary_args}

        ## Shuffle hexagons
        sort -S 10G -k1,1n {sdgeAR_hxg_unzip} | gzip -c > {output.sdgeAR_hxg}  

        if [ -f {sdgeAR_hxg_unzip} ]; then
            rm {sdgeAR_hxg_unzip}
        fi
        """
        )



