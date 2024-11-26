rule c01_sdge2sdgeAR:
    input:
        sdge_bcd       = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "barcodes.tsv.gz"),
        sdge_ftr       = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "features.tsv.gz"),
        sdge_mtx       = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "matrix.mtx.gz"),
        sdge_3in1_png  = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "{run_id}"+".sge_match_sbcd.png"),
        sdge_xyrange   = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "barcodes.minmax.tsv"),
        sdge_rgb_list  = lambda wildcards: [ os.path.join(main_dirs["align"],  flowcell, chip, "{run_id}", "sge", "{run_id}.sge_visual", sgevisual_id+".png") for sgevisual_id in rid2sgevisual_id[wildcards.run_id]] if drawsge else [],
    output:
        sdgeAR_bcd      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.tsv.gz"),
        sdgeAR_ftr      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "features.tsv.gz"),
        sdgeAR_mtx      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "matrix.mtx.gz"),
        sdgeAR_3in1_png = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "{unit_id}"+".sge_match_sbcd.png"),
        sdgeAR_xyrange  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
        sdgeAR_rgbflag  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "sge_visual.flag")
        sdgeAR_axis     = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "major_axis.tsv"),
    params:
        run_id          = run_id,
        unit_id         = unit_id, 
        boundary        = boundary,
        unit_ann        = unit_ann,
    threads: 2
    resources:
        mem  = "6500MB",
        time = "1:00:00", 
    run:
        sdge_dir   = os.path.dirname(input.sdge_bcd)
        sdgeAR_dir = os.path.dirname(output.sdgeAR_bcd)
        sdge_rgbdir     = os.path.join(sdge_dir, f"{params.run_id}.sge_visual")
        sdgeAR_rgbdir   = os.path.join(sdgeAR_dir, f"{params.unit_id}.sge_visual")
        # write the major axis to the output file
        major_axis = find_major_axis(input.sdge_xyrange, format="col")
        with open(output.sdgeAR_axis, "w") as f:
            f.write(major_axis)
    
        if unit_ann == "default":
            os.makedirs(sdgeAR_dir, exist_ok=True)
            # link sge
            create_symlinks_by_list(sdge_dir, sdgeAR_dir, 
                                    ["barcodes.tsv.gz", "matrix.mtx.gz", "features.tsv.gz", "barcodes.minmax.tsv"], 
                                    match_by_suffix=False)
            # link 3 way plot
            create_symlinks_by_list(sdge_dir, sdgeAR_dir, 
                                    ["sge_match_sbcd.png"], 
                                    input_id=params.run_id, 
                                    output_id=params.unit_id, 
                                    match_by_suffix=True)
            # link rgb images 
            if not os.path.exists(sdge_rgbdir):
                os.makedirs(sdge_rgbdir, exist_ok=True)
            create_symlink( sdge_rgbdir, 
                            sdgeAR_rgbdir, 
                            handle_missing_input="warn", 
                            handle_existing_output="replace", 
                            silent=False)
            with open(output.sdgeAR_rgbflag, "w") as f:
                f.write(f"{datetime.datetime.now()}")
        else:
            raise ValueError("Currently, NovaScope does not support any filtering. If needed, the user can manually filter the data.")       
