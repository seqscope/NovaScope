rule c03_sdgeAR_polygonfilter:
    input:
        sdgeAR_xyrange          = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_transcript       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"),
        sdgeAR_transcript_tbi   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz.tbi"),
        sdgeAR_ftr_clean        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.clean.tsv.gz"),
    output:
        sdgeAR_transcript_qc    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.transcripts.tsv.gz"),
        sdgeAR_transcript_qc_tbi= os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.transcripts.tsv.gz.tbi"),
        sdgeAR_xyrange_qc       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.coordinate_minmax.tsv"),
        sdgeAR_ftr_qc           = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.feature.tsv.gz"),       # This file has never been used.
        sdgeAR_bd_qc            = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.boundary.geojson"),
    params:
        # params
        solo_feature            = "{solo_feature}",
        radius                  = config.get("downstream", {}).get('polygon_density_filter', {}).get("radius", 15),
        quartile                = config.get("downstream", {}).get('polygon_density_filter', {}).get('quartile', 2),  
        hex_n_move              = config.get("downstream", {}).get('polygon_density_filter', {}).get('hex_n_move', 1),   
        polygon_min_size        = config.get("downstream", {}).get('polygon_density_filter', {}).get('polygon_min_size', 500),  
        # files
        sdgeAR_bd_strict        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.boundary.strict.geojson"), 
        sdgeAR_bd_lenient       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.boundary.lenient.geojson"), 
        sdgeAR_ftr_strict       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.feature.strict.tsv.gz"), 
        sdgeAR_ftr_lenient      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.feature.lenient.tsv.gz"), 
        # module
        module_cmd              = get_envmodules_for_rule(["python", "samtools"], module_config),
    resources:
        mem  = lambda params:  "14000MB",
        time = lambda params:  "10:00:00",
    run:
        sdgeAR_qc_pref         = output.sdgeAR_transcript_qc.replace(".transcripts.tsv.gz", ""),

        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col")
        shell(
        r"""
        {params.module_cmd}
        source {pyenv}/bin/activate

        command time -v {python} {ficture}/ficture/scripts/filter_poly.py \
                --input {input.sdgeAR_transcript} \
                --feature {input.sdgeAR_ftr_clean} \
                --output {output.sdgeAR_transcript_qc} \
                --output_boundary {sdgeAR_qc_pref} \
                --filter_based_on {params.solo_feature} \
                --mu_scale {mu_scale} \
                --radius {params.radius} \
                --quartile {params.quartile} \
                --hex_n_move {params.hex_n_move} \
                --remove_small_polygons {params.polygon_min_size} 

        # Determine the sort column based on the major_axis value
        if [ {major_axis} == "Y" ]; then
            tabix_column="-b4 -e4"
        else
            tabix_column="-b3 -e3"
        fi

        zcat {output.sdgeAR_transcript_qc} | bgzip -c > {output.sdgeAR_transcript_qc}.tmp.gz
        mv {output.sdgeAR_transcript_qc}.tmp.gz {output.sdgeAR_transcript_qc}
        tabix -0 -f -s1 $tabix_column {output.sdgeAR_transcript_qc}

        ln -s {params.sdgeAR_ftr_strict} {output.sdgeAR_ftr_qc}
        ln -s {params.sdgeAR_bd_strict} {output.sdgeAR_bd_qc}
        
        """
        )