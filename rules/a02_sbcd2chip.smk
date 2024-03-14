rule a02_sbcd2chip:
    input:
        sbcd_mnfst       = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds", sc2seq1[wildcards.section], "manifest.tsv"),
    output:
        nbcd_tsv         = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_mnfst       = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "manifest.tsv"),
        nbcd_png         = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.png"),
    params:
        # sbcd layout: tile2section
        sbcd_layout      = check_path(config.get('input', {}).get('seq1st', {}).get('layout', None), job_dir, strict_mode=False),
        sbcd_layout_def  = lambda wildcards: os.path.join(smk_dir, "info", "assets", "layout_per_tile_basis", wildcards.section+".layout.tsv"),
        # combine 
        gap_row             = config.get("preprocess", {}).get("sbcd2chip", {}).get('gap_row', 0.0517),
        gap_col             = config.get("preprocess", {}).get("sbcd2chip", {}).get('gap_col', 0.0048),
        dup_maxnum          = config.get("preprocess", {}).get("sbcd2chip", {}).get('dup_maxnum', 1),
        dup_maxdist         = config.get("preprocess", {}).get("sbcd2chip", {}).get('dup_maxdist', 1),
        # visualization
        visual_coord_per_pixel    = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("coord_per_pixel", 1000),
        visual_intensity_per_obs  = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("intensity_per_obs", 50),
        visual_icol_x             = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("icol_x", 3),
        visual_icol_y             = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("icol_y", 4),
        # module
        module_cmd        = get_envmodules_for_rule(["python", "imagemagick"], module_config)
    resources:
        time = "5:00:00",
        mem  = "6500m"
    run:
        sbcd_dir         = os.path.dirname(input.sbcd_mnfst)
        nbcd_dir         = os.path.dirname(output.nbcd_tsv)

        # Identify the sbcd layout file to use.
        if params.sbcd_layout is not None:
            assert os.path.exists(params.sbcd_layout), f"The provided sbcd layout file does not exist: {params.sbcd_layout}."
            print(f"Using the provided sbcd lay out file: {params.sbcd_layout}.")
            sbcd_layout = params.sbcd_layout
        else:
            assert os.path.exists(params.sbcd_layout_def), f"The default sbcd layout file does not exist: {params.sbcd_layout_def}. Check your section chip ID."
            print(f"Using the default sbcd lay out file: {params.sbcd_layout_def}.")
            sbcd_layout = params.sbcd_layout_def    
            
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        source {py39_env}/bin/activate

        # s1
        echo -e "Combinding sbcds from tile to section.\\n"
        command time -v  {spatula} combine-sbcds \
            --layout {sbcd_layout} \
            --manifest {input.sbcd_mnfst} \
            --sbcd {sbcd_dir} \
            --out {nbcd_dir} \
            --rowgap {params.gap_row} \
            --colgap {params.gap_col}  \
            --max-dup {params.dup_maxnum} \
            --max-dup-dist-nm {params.dup_maxdist}

        # s2
        echo -e "Runing draw-xy...\\n"
        command time -v  {spatula} draw-xy \
            --tsv {output.nbcd_tsv} \
            --out {output.nbcd_png} \
            --coord-per-pixel {params.visual_coord_per_pixel} \
            --icol-x {params.visual_icol_x} \
            --icol-y {params.visual_icol_y} \
            --intensity-per-obs {params.visual_intensity_per_obs}
        """
        )
