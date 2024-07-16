rule c03_sdgeAR_polygonfilter:
    input:
        sdgeAR_xyrange          = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_transcript       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"),
        sdgeAR_transcript_tbi   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz.tbi"),
        sdgeAR_ftr_cond         = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", ("{unit_id}.feature.tsv.gz" if wildcards.sge_qc == "raw" else "{unit_id}.feature.clean.tsv.gz")),
    output:
        sdgeAR_transcript_qc    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.transcripts.tsv.gz"),
        sdgeAR_transcript_qc_tbi= os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.transcripts.tsv.gz.tbi"),
        sdgeAR_xyrange_qc       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv"),
        sdgeAR_ftr_qc           = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.feature.tsv.gz"),       # This file has never been used.
        sdgeAR_bd_qc            = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.boundary.geojson"),
    params:
        # params
        solo_feature            = "{solo_feature}",
        sge_qc                  = "{sge_qc}",
        radius                  = config.get("downstream", {}).get('polygon_density_filter', {}).get("radius", 15),
        quartile                = config.get("downstream", {}).get('polygon_density_filter', {}).get('quartile', 2),  
        hex_n_move              = config.get("downstream", {}).get('polygon_density_filter', {}).get('hex_n_move', 1),   
        polygon_min_size        = config.get("downstream", {}).get('polygon_density_filter', {}).get('polygon_min_size', 500),  
        # files
        sdgeAR_bd_strict        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.boundary.strict.geojson"), 
        sdgeAR_bd_lenient       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.boundary.lenient.geojson"), 
        sdgeAR_ftr_strict       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.feature.strict.tsv.gz"), 
        sdgeAR_ftr_lenient      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.feature.lenient.tsv.gz"), 
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

        if [ {params.sge_qc} == "filtered" ]; then     

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
        
        elif [ {params.sge_qc} == "raw" ]; then
            ln -s {input.sdgeAR_transcript}     {output.sdgeAR_transcript_qc}
            ln -s {input.sdgeAR_transcript_tbi} {output.sdgeAR_transcript_qc_tbi}

            gzip -cd {output.sdgeAR_transcript_qc} | \
                awk 'BEGIN{{FS=OFS="\t"}} NR==1{{for(i=1;i<=NF;i++){{if($i=="X")x=i;if($i=="Y")y=i}}print $x,$y;next}}{{print $x,$y}}' | \
                perl -slane 'print join("\t",$F[0]/{mu_scale},$F[1]/{mu_scale})' -- -mu_scale="{mu_scale}" | \
                awk 'BEGIN {{FS=OFS="\t"; min1 = "undef"; max1 = "undef"; min2 = "undef"; max2 = "undef";}} {{if (NR == 2 || $1 < min1) min1 = $1; if (NR == 2 || $1 > max1) max1 = $1; if (NR == 2 || $2 < min2) min2 = $2; if (NR == 2 || $2 > max2) max2 = $2;}} END {{print "xmin", min1; print "xmax", max1; print "ymin", min2; print "ymax", max2;}}' > {output.sdgeAR_xyrange_qc}

            ln -s {input.sdgeAR_ftr_tab} {output.sdgeAR_ftr_qc}
            touch {output.sdgeAR_bd_qc}
        fi
        """
        )