def create_layout(layout, lane, tile1, tile2, colshift, shifttype):
    if shifttype == "odd":
        with open(layout, 'w') as f:
            f.write(f"lane\ttile\trow\tcol\trowshift\tcolshift\n")
            f.write(f"{lane}\t{tile1}\t1\t1\t0\t0\n")
            f.write(f"{lane}\t{tile2}\t2\t1\t0\t{colshift}\n")
    elif shifttype == "even":
        with open(layout, 'w') as f:
            f.write(f"lane\ttile\trow\tcol\trowshift\tcolshift\n")
            f.write(f"{lane}\t{tile1}\t1\t1\t0\t{colshift}\n")
            f.write(f"{lane}\t{tile2}\t2\t1\t0\t0\n")

rule b03_sbcd_layout:
    input:
        sbcd_mnfst        = os.path.join(main_dirs["seq1st"], "{flowcell}", "sbcds", "L{lane}", "manifest.tsv"),
    output:
        nbcd_png          = os.path.join(main_dirs["seq1st"], "{flowcell}", "images", "{flowcell}.{lane}.{layer}.{tile_1}_{tile_2}.{shifttype}shift.nbcds.png"),
    params:
        lane                = "{lane}",
        shifttype           = "{shifttype}",
        tile_1              = "{tile_1}",
        tile_2              = "{tile_2}",
        # combine 
        gap_row             = config.get("upstream", {}).get("sbcd2chip", {}).get('gap_row', 0.0517),
        gap_col             = config.get("upstream", {}).get("sbcd2chip", {}).get('gap_col', 0.0048),
        dup_maxnum          = config.get("upstream", {}).get("sbcd2chip", {}).get('dup_maxnum', 1),
        dup_maxdist         = config.get("upstream", {}).get("sbcd2chip", {}).get('dup_maxdist', 1),
        colshift            = config.get("upstream", {}).get("sbcd_layout", {}).get('colshift', 0.1715),
        # visualization
        visual_coord_per_pixel    = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("coord_per_pixel", 1000),
        visual_intensity_per_obs  = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("intensity_per_obs", 50),
        visual_icol_x             = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("icol_x", 3),
        visual_icol_y             = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("icol_y", 4),
        # env
        module_cmd          = get_envmodules_for_rule(["imagemagick"], config),
    resources:
        time = "50:00:00",
        mem  = "70g",
    run: 
        sbcd_dir = os.path.dirname(input.sbcd_mnfst)
        image_dir = output.nbcd_png.replace(".nbcds.png", ".nbcds")
        os.makedirs(image_dir, exist_ok=True)
        
        # 1. create the sbcd layout
        layout=output.nbcd_png.replace(".nbcds.png", ".layout.tsv")
        create_layout(
            layout    = layout,
            lane      = params.lane,
            tile1     = params.tile_1,
            tile2     = params.tile_2,
            colshift  = params.colshift,
            shifttype = params.shifttype
        )
        
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        
        # 2. combine sbcds with minimal layout
        command time -v  {spatula} combine-sbcds --layout {layout} \
                    --manifest {input.sbcd_mnfst} \
                    --sbcd {sbcd_dir} \
                    --out {image_dir} \
                    --rowgap {params.gap_row} \
                    --colgap {params.gap_col} \
                    --max-dup {params.dup_maxnum} \
                    --max-dup-dist-nm {params.dup_maxdist}

        # 3. plot the nbcds
        command time -v  {spatula} draw-xy --tsv {image_dir}/1_1.sbcds.sorted.tsv.gz \
                    --out {output.nbcd_png} \
                    --coord-per-pixel {params.visual_coord_per_pixel} \
                    --icol-x {params.visual_icol_x} \
                    --icol-y {params.visual_icol_y} \
                    --intensity-per-obs {params.visual_intensity_per_obs}
        """
        )
