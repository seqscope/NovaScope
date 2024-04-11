rule a08_sdgeAR_QC:
    input:
        sdgeAR_xyrange    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_ftr_tabqc  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.clean.tsv.gz"),
        sdgeAR_transcript = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"),
    output:
        sdgeAR_transcript_qc = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.filtered.tsv.gz"),
        sdgeAR_xyrange_qc    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.coordinate_minmax.tsv"),
        sdgeAR_bd_strict     = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.boundary.strict.geojson"), 
        sdgeAR_bd_lenient    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.boundary.lenient.geojson"), 
        sdgeAR_ftr_strict    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.strict.tsv.gz"), 
        sdgeAR_ftr_lenient   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.lenient.tsv.gz"), 
    params:
        outpref              = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}"), 
        solofeature          = config.get("sdgeAR", {}).get("QC", {}).get('solofeature', "gn"),  
        polygon_min_size     = config.get("sdgeAR", {}).get("QC", {}).get('polygon_min_size', 500),  
        radius               = config.get("sdgeAR", {}).get("QC", {}).get("radius", 15),
        n_move               = config.get("sdgeAR", {}).get("QC", {}).get('n_move', 2),   
        quartile             = config.get("sdgeAR", {}).get("QC", {}).get('quartile', 2),       
        # module
        module_cmd           = get_envmodules_for_rule(["python", "samtools"], module_config)
    threads: 2
    resources:
        mem = "14000MB",
        time = "20:00:00",
        #mem  = lambda params: "6500MB" if params_skip_density_QC else "14000MB",
        #time = lambda params: "2:00:00" if params_skip_density_QC else "20:00:00",
    run:
        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col")
        shell(
        r"""
        {params.module_cmd}
        source {pyenv}/bin/activate

        # Determine the sort column based on the major_axis value
        if [ {major_axis} == "Y" ]; then
            tabix_column="-b4 -e4"
        else
            tabix_column="-b3 -e3"
        fi

        echo "==> Perform QC on {input.sdgeAR_transcript} based on the density!"
        command time -v {python} {ficture}/script/filter_poly.py \
            --input {input.sdgeAR_transcript} \
            --feature {input.sdgeAR_ftr_tabqc} \
            --output {output.sdgeAR_transcript_qc} \
            --output_boundary {params.outpref} \
            --filter_based_on {params.solofeature} \
            --mu_scale {mu_scale} \
            --radius {params.radius} \
            --quartile {params.quartile} \
            --hex_n_move {params.n_move} \
            --remove_small_polygons {params.polygon_min_size} 

        zcat {output.sdgeAR_transcript_qc} | bgzip -c > {output.sdgeAR_transcript_qc}.tmp.gz
        mv {output.sdgeAR_transcript_qc}.tmp.gz {output.sdgeAR_transcript_qc}
        tabix -0 -f -s1 $tabix_column {output.sdgeAR_transcript_qc}
        """
        )