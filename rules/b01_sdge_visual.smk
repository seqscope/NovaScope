rule b01_sdge_visual:
    input:
        #sdges from a05_dge2sdge.smk
        sdge_bcd        = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.tsv.gz"),
        sdge_ftr        = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "features.tsv.gz"),
        sdge_mtx        = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "matrix.mtx.gz"),
    output:
        sdge_png        = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_visual", "{sgevisual_id}.png"),
    params:
        sgevisual_id    = "{sgevisual_id}",
        # module
        module_cmd      = get_envmodules_for_rule(["python", "imagemagick"], module_config),
        # config
        visual_coord_per_pixel = config.get("upstream", {}).get("visualization", {}).get("drawsge",{}).get("coord_per_pixel", 1000),
        visual_auto_adjust     = " --auto-adjust " if config.get("upstream", {}).get("visualization", {}).get("drawsge",{}).get("auto_adjust", True) else "",
        visual_adjust_quantile = config.get("upstream", {}).get("visualization", {}).get("drawsge",{}).get("adjust_quantile", 0.99),
    run: 
        sdge_dir = os.path.dirname(input.sdge_bcd)

        visual_colorargs = sgevisual_id2params[params.sgevisual_id]
        
        shell(
        r"""
        set -e
        {params.module_cmd}
        source {pyenv}/bin/activate

        echo "Creating sge image: {output.sdge_png} ..."
        command time -v {spatula} draw-sge \
            --sge {sdge_dir} \
            --out {output.sdge_png} \
            --coord-per-pixel {params.visual_coord_per_pixel} \
            --adjust-quantile {params.visual_adjust_quantile} {params.visual_auto_adjust} \
            {visual_colorargs}
        """)