rule c04_sdgeAR_segment_ficture_resilient:
    input:
        transcript_raw      = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz") if wildcards.sge_qc=="raw" else [],  
        polygonfilter_log   = lambda wildcards: [] if wildcards.sge_qc=="raw" else os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.filtered.log"), 
        xyrange_in          = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv")  if wildcards.sge_qc=="raw" else [],    # This file is not used but is required to make sure every transcript file has a corresponding xyrange_in file.
        sdgeAR_axis         = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "major_axis.tsv"),
    output:
        hexagon_log         = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.ficture.d_{hexagon_width}.log")
    params:
        hexagon_prefix      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.d_{hexagon_width}"),
        solo_feature        = "{solo_feature}",
        train_width         = "{hexagon_width}",
        sge_qc              = "{sge_qc}",
        hex_n_move          = int(config.get("downstream", {}).get('segment', {}).get('hex_n_move', 1)), 
        precision           = config.get("downstream", {}).get('segment', {}).get('precision', 2), 
        min_density_per_unit= config.get("downstream", {}).get('segment', {}).get('ficture', {}).get('min_density_per_unit', 0.01),
        min_ct_per_unit     = config.get("downstream", {}).get('segment', {}).get('ficture', {}).get('min_ct_per_unit', 10),
        exist_action        = config.get("downstream", {}).get('segment', {}).get('ficture', {}).get('exist_action', "overwrite"), # ["skip", "overwrite"] # for the inhouse production pipeline, because the parameters has been changed: density from 0.3 to 0.01, ct from 20 to 10, do not use the previous hexagon file.
        transcript_filtered = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.filtered.transcripts.tsv.gz"), 
        # module
        module_cmd          = get_envmodules_for_rule(["python", "samtools"], config),
    resources:
        mem  = "28000MB", 
        time = "10:00:00"
    run:
        # dirs/files
        hexagon_unzip = params.hexagon_prefix + ".hexagon.tsv"
        hexagon       = params.hexagon_prefix + ".hexagon.tsv.gz"

        major_axis = pd.read_csv(input.sdgeAR_axis, sep='\t', header=None).iloc[0, 0]

        # 1) If polygonfilter failed, skip the segmentation
        if params.sge_qc == "filtered":
            # check the status of the previous step
            polygonfilter_status = open(input.polygonfilter_log).read().strip()
            if "Failed" in polygonfilter_status:
                with open(output.hexagon_log, "w") as f:
                    f.write(polygonfilter_status)
                print(f"Skip hexagon segmentation: The polygonfilter step failed (see {input.polygonfilter_log}).")
                return
            
            # update the boundary file
            boundary_in = input.polygonfilter_log.replace(".filtered.log", ".boundary.strict.geojson")
            boundary_args = f"--boundary {boundary_in}"
            # update transcript file
            transcript_in = params.transcript_filtered
        else:
            boundary_args = ""
            transcript_in = input.transcript_raw

        # 2) If the segmentation exists and the exist_action is "skip", skip the segmentation
        if params.exist_action == "skip" and os.path.exists(hexagon):
            print("Skip hexagon segmentation: The segmentation exists.")
            with open(output.hexagon_log, "w") as f:
                f.write("Done")
            return 

        # 3) Start the hexagon segmentation
        print("Start hexagon segmentation...")

        try:
            shell(
            r"""
            {params.module_cmd}
            source {pyenv}/bin/activate

            ### skip the --ct_header to use the default value.
            command time -v {python} {ficture}/ficture/scripts/make_dge_univ.py \
                --input {transcript_in} \
                --output {hexagon_unzip} \
                --mu_scale {mu_scale} \
                --key {params.solo_feature} \
                --hex_width {params.train_width} \
                --min_ct_per_unit {params.min_ct_per_unit} \
                --min_density_per_unit {params.min_density_per_unit} \
                --n_move {params.hex_n_move} \
                --precision {params.precision} \
                --major_axis {major_axis} {boundary_args}
                
            ## Shuffle hexagon
            sort -S 10G -k1,1n {hexagon_unzip} | gzip -c > {hexagon} 

            if [ -f {hexagon_unzip} ]; then
                rm {hexagon_unzip}
            fi
            """
            )
            # sanity check: empty sge
            nhex = int(subprocess.check_output(f"gzip -dc {hexagon} | wc -l", shell=True).decode().strip())
            print(f"The hexagon-indexed SGE has {nhex} hexagons.")
            if nhex > 1:    # header
                with open(output.hexagon_log, "w") as f:
                    f.write("Done")
            else:
                with open(output.hexagon_log, "w") as f:
                    f.write("Failed: c04_sdgeAR_segment_ficture_inhouse")
                    f.write("Issue: Returned 0 hexagons")
        except Exception as e:
            print(str(e))
            with open(output.hexagon_log, "w") as f:
                f.write("Failed: c04_sdgeAR_segment_ficture_inhouse")
                f.write("Issue: "+str(e))

