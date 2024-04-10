rule a06_sdge2sdgeAR:
    input:
        sdge_bcd      = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "barcodes.tsv.gz"),
        sdge_ftr      = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "features.tsv.gz"),
        sdge_mtx      = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "matrix.mtx.gz"),
        sdge_rgb_png  = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "{run_id}"+".gene_full_mito.png"),
        sdge_3in1_png = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "{run_id}"+".sge_match_sbcd.png"),
        sdge_xyrange  = os.path.join(main_dirs["align"], flowcell, chip, "{run_id}", "sge", "barcodes.minmax.tsv"),
    output:
        sdgeAR_bcd      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.tsv.gz"),
        sdgeAR_ftr      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "features.tsv.gz"),
        sdgeAR_mtx      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "matrix.mtx.gz"),
        sdgeAR_rgb_png  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "{unit_id}"+".gene_full_mito.png"),
        sdgeAR_3in1_png = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "{unit_id}"+".sge_match_sbcd.png"),
        sdgeAR_xyrange  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
    params:
        run_id          = run_id,
        unit_id         = unit_id,   
        boundary        = boundary,
        unit_ann        = unit_ann,
    threads: 2
    resources:
        mem  = "14000MB",
        time = "20:00:00", 
    run:
        sdge_dir   = os.path.dirname(input.sdge_bcd)
        sdgeAR_dir = os.path.dirname(output.sdgeAR_bcd)
        
        if unit_ann == "default":
            link_sdge_to_sdgeAR(input_path=sdge_dir, 
                                output_path=sdgeAR_dir, 
                                run_id=params.run_id,
                                unit_id=params.unit_id
            )
        else:
            raise ValueError("Currently, we does not support boundary filtering.")       
