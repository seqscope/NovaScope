rule b03_sdgeAR_segmentviz:
    input:
        # start with only ficture hexagons 
        # hexagon_10x_d12  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_12", "10x", "matrix.mtx.gz"),
        # hexagon_10x_d18  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_18", "10x", "matrix.mtx.gz"),
        # hexagon_10x_d24  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_24", "10x", "matrix.mtx.gz"),
        # hexagon_10x_d36  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_36", "10x", "matrix.mtx.gz"),
        # hexagon_10x_d48  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_48", "10x", "matrix.mtx.gz"),
        # hexagon_10x_d72  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_72", "10x", "matrix.mtx.gz"),
        # hexagon_10x_d96  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_96", "10x", "matrix.mtx.gz"),
        # hexagon_10x_d120 = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_120", "10x", "matrix.mtx.gz")
        hexagon_ficture_d12  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_12", "{unit_id}.{solo_feature}.{sge_qc}.d_12.hexagon.tsv.gz"),
        hexagon_ficture_d18  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_18", "{unit_id}.{solo_feature}.{sge_qc}.d_18.hexagon.tsv.gz"),
        hexagon_ficture_d24  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_24", "{unit_id}.{solo_feature}.{sge_qc}.d_24.hexagon.tsv.gz"),
        hexagon_ficture_d36  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_36", "{unit_id}.{solo_feature}.{sge_qc}.d_36.hexagon.tsv.gz"),
        hexagon_ficture_d48  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_48", "{unit_id}.{solo_feature}.{sge_qc}.d_48.hexagon.tsv.gz"),
        hexagon_ficture_d72  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_72", "{unit_id}.{solo_feature}.{sge_qc}.d_72.hexagon.tsv.gz"),
        hexagon_ficture_d96  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_96", "{unit_id}.{solo_feature}.{sge_qc}.d_96.hexagon.tsv.gz"),
        hexagon_ficture_d120 = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_120", "{unit_id}.{solo_feature}.{sge_qc}.d_120.hexagon.tsv.gz")
    output:
        hexagon_ficture_tab  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{unit_id}.{solo_feature}.{sge_qc}.hexagon_nUMI.ficture.tsv")
        hexagon_ficture_png  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{unit_id}.{solo_feature}.{sge_qc}.hexagon_nUMI.ficture.png")
    params:
        unit_id        = "{unit_id}",
        png_title      = "{unit_id}_ficture_{sge_qc}",
        # module
        module_cmd     = get_envmodules_for_rule(["python", "R"], module_config)
    resources:
        mem  = "28000MB", 
        time = "72:00:00"
    run:
        # dirs/files
        segment_dir = os.path.dirname(os.path.dirname(input.hexagon_d12))
        
        shell(
        r"""
        {params.module_cmd}
        source {pyenv}/bin/activate
        
        command time -v {python} {novascope_scripts}/rule_b03_sdgeAR_segmentviz_nUMI_tab.py \
            --in-dir {segment_dir} \
            --format ficture \
            --density_filter {sge_qc} \
            --unit-id {params.unit_id} \
            --write-numi-per-width

        R CMD BATCH {novascope_scripts}/rule_b03_sdgeAR_segmentviz_nUMI_viz.R --input {output.hexagon_ficture_tab} --output {output.hexagon_ficture_png} --title {params.png_title} 
            
        """
        )



