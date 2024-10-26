rule a02_sbcd2chip:
    input:
        sbcd_mnfst  = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds", sc2seq1[wildcards.chip], "manifest.tsv"),
    output:
        nbcd_tsv    = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_mnfst  = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{chip}", "manifest.tsv"),
        nbcd_png    = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.png"),
    params:
        chip         = "{chip}",
        # sbcd layout: tile2chip
        sbcd_layout  = check_path(config.get('input', {}).get('seq1st', {}).get('layout', None), job_dir, strict_mode=False),
        layout_shift = config.get('input', {}).get('seq1st', {}).get('layout_shift', "tobe"),
        # combine 
        gap_row      = config.get("upstream", {}).get("sbcd2chip", {}).get('gap_row', 0.0517),
        gap_col      = config.get("upstream", {}).get("sbcd2chip", {}).get('gap_col', 0.0048),
        dup_maxnum   = config.get("upstream", {}).get("sbcd2chip", {}).get('dup_maxnum', 1),
        dup_maxdist  = config.get("upstream", {}).get("sbcd2chip", {}).get('dup_maxdist', 1),
        # visualization
        visual_coord_per_pixel    = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("coord_per_pixel", 1000),
        visual_intensity_per_obs  = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("intensity_per_obs", 50),
        visual_icol_x             = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("icol_x", 3),
        visual_icol_y             = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("icol_y", 4),
        # tools
        module_cmd    = get_envmodules_for_rule(["imagemagick"], config.get("env",{}).get("envmodules", {}))
    resources:
        time = "5:00:00",
        mem  = "6500m"
    run:
        sbcd_dir = os.path.dirname(input.sbcd_mnfst)
        nbcd_dir = os.path.dirname(output.nbcd_tsv)

        # Identify the sbcd layout file to use.
        if params.sbcd_layout is not None:
            print(f"Using the user-provided sbcd layout file: {params.sbcd_layout}.")
            sbcd_layout = params.sbcd_layout
        else:
            assert params.layout_shift in ["tobe", "tebo"], "Invalid shift type in seq1st in the input field."
            sbcd_layout = os.path.join(smk_dir, "info", "assets", "layout_per_tile_basis", params.layout_shift, params.chip+".layout.tsv")
            print (f"Using the default sbcd layout file {sbcd_layout}.")
        
        assert os.path.exists(sbcd_layout), f"Missing sbcd layout file: {sbcd_layout}."
                    
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        # s1
        echo -e "Combinding sbcds from tile to chip.\\n"
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