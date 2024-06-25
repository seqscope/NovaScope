rule c03_sdgeAR_polygonfilter:
    input:
        sdgeAR_xyrange          = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_ftr_tabqc        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.clean.tsv.gz"),
        sdgeAR_transcript       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"),
    output:
        sdgeAR_transcript_den   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.den_{polygon_den}.transcripts.tsv.gz"),
        sdgeAR_xyrange_den      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.den_{polygon_den}.coordinate_minmax.tsv"),
        sdgeAR_ftr_den          = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.den_{polygon_den}.feature.tsv.gz"),
        sdgeAR_bd_den           = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.den_{polygon_den}.boundary.geojson"),
    params:
        # params
        solo_feature            = "{solo_feature}",
        polygon_den             = "{polygon_den}",
        radius                  = config.get("downstream", {}).get('polygon_density_filter', {}).get("radius", 15),
        quartile                = config.get("downstream", {}).get('polygon_density_filter', {}).get('quartile', 2),  
        hex_n_move              = config.get("downstream", {}).get('polygon_density_filter', {}).get('hex_n_move', 1),   
        polygon_min_size        = config.get("downstream", {}).get('polygon_density_filter', {}).get('polygon_min_size', 500),  
        # files
        sdgeAR_bd_strict        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.den_{polygon_den}.boundary.strict.geojson"), 
        sdgeAR_bd_lenient       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.den_{polygon_den}.boundary.lenient.geojson"), 
        sdgeAR_ftr_strict       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.den_{polygon_den}.feature.strict.tsv.gz"), 
        sdgeAR_ftr_lenient      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.den_{polygon_den}.feature.lenient.tsv.gz"), 
        # module
        module_cmd              = get_envmodules_for_rule(["python", "samtools"], module_config),
    threads: 2
    resources:
        mem = "14000MB",
        time = "20:00:00",
        #mem  = lambda params: "6500MB" if params_skip_density_QC else "14000MB",
        #time = lambda params: "2:00:00" if params_skip_density_QC else "20:00:00",
    run:
        sdgeAR_den_pref         = output.sdgeAR_transcript_den.replace(".transcripts.tsv.gz", ""),

        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col")
        shell(
        r"""
        {params.module_cmd}
        source {pyenv}/bin/activate

        if [ {params.polygon_den} == "auto" ]; then     

            command time -v {python} {ficture}/ficture/scripts/filter_poly.py \
                --input {input.sdgeAR_transcript} \
                --feature {input.sdgeAR_ftr_tabqc} \
                --output {output.sdgeAR_transcript_den} \
                --output_boundary {sdgeAR_den_pref} \
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

            zcat {output.sdgeAR_transcript_den} | bgzip -c > {output.sdgeAR_transcript_den}.tmp.gz
            mv {output.sdgeAR_transcript_den}.tmp.gz {output.sdgeAR_transcript_den}
            tabix -0 -f -s1 $tabix_column {output.sdgeAR_transcript_den}

            ln -s {params.sdgeAR_ftr_strict} {output.sdgeAR_ftr_den}

            ln -s {params.sdgeAR_bd_strict} {output.sdgeAR_bd_den}
        
        ##TO-DO: add the code to create 
        fi

        """
        )