rule b03_sdgeAR_segmentviz:
    input:
        hexagon_log_d12  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_12",  "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.d_12.log"),
        hexagon_log_d18  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_18",  "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.d_18.log"),
        hexagon_log_d24  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_24",  "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.d_24.log"),
        hexagon_log_d36  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_36",  "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.d_36.log"),
        hexagon_log_d48  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_48",  "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.d_48.log"),
        hexagon_log_d72  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_72",  "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.d_72.log"),
        hexagon_log_d96  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_96",  "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.d_96.log"),
        hexagon_log_d120 = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_120", "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.d_120.log"),
    output:
        segmentviz_log   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{unit_id}.{solo_feature}.{sge_qc}.{sge_format}.segmentviz.log"),
    params:
        run_id         = "{run_id}",
        unit_id        = "{unit_id}",
        solo_feature   = "{solo_feature}",
        sge_qc         = "{sge_qc}",
        sge_format     = "{sge_format}",
        # prefix
        png_title      = "{unit_id}_{sge_format}_{sge_qc}",
        # module
        module_cmd     = get_envmodules_for_rule(["python", "R"], module_config)
    resources:
        mem  = "28000MB", 
        time = "72:00:00"
    run:
        # dirs/files
        segment_dir = os.path.dirname(os.path.dirname(input.hexagon_log_d12))

        segmentviz_tab = output.segmentviz_log.rstrip(".log") + ".tsv"
        segmentviz_png = output.segmentviz_log.rstrip(".log") + ".space.png"

        # collect available widths by log files        
        print(f" Input file in {params.sge_format} format...")
        print("     - Checking the availability of hexagon-indexed SGE...")
        hex_width_list = []
        for i in [12, 18, 24, 36, 48, 72, 96, 120]:
            hexagon_log_file=os.path.join(main_dirs["analysis"], params.run_id, params.unit_id, "segment", f"{params.solo_feature}.{params.sge_qc}.d_"+str(i),  f"{params.unit_id}.{params.solo_feature}.{params.sge_qc}.{params.sge_format}.d_"+str(i)+".log")
            with open(hexagon_log_file, "r") as f:
                if f.read().strip() == "Done":
                    hex_width_list.append(f"d_{i}")
        
        print("     - hexagon-widths: "+",".join(hex_width_list))

        if len(hex_width_list) > 0:
            hex_width_joint=",".join(hex_width_list)
            shell(
            r"""
            {params.module_cmd}
            source {pyenv}/bin/activate
            
            echo -e "   - Summarizing number of hexagons per nUMI cutoff..."
            command time -v {python} {novascope_scripts}/rule_b03_sdgeAR_segmentviz_nUMI_tab.py \
                --in-dir {segment_dir} \
                --unit-id {params.unit_id} \
                --format {params.sge_format} \
                --density-filter {params.sge_qc} \
                --hex-width {hex_width_joint} \
                --write-numi-per-width
            
            echo -e "     - Plotting number of hexagons per nUMI cutoff..."
            Rscript {novascope_scripts}/rule_b03_sdgeAR_segmentviz_nUMI_viz.R --input {segmentviz_tab} --output {segmentviz_png} --title {params.png_title}  --yaxis space
            """
            )
        # write down a log file to indicate the segmentation is done
        with open(output.segmentviz_log, "w") as f:
            f.write(f"Number of hexagon widths: {len(hex_width_list)}")

