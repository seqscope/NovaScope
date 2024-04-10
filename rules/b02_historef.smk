rule b02_historef:
    input:
        sdge_3in1_png     = os.path.join(main_dirs["align"],      "{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_match_sbcd.png"),
        hist_raw          = os.path.join(main_dirs["histology"],  "{flowcell}", "{chip}", "raw", "{hist_std_prefix}.tif"),
    output:
        hist_aligned      = os.path.join(main_dirs["histology"],  "{flowcell}", "{chip}", "aligned", "{run_id}", "{hist_std_prefix}.tif"),
        hist_fit          = os.path.join(main_dirs["histology"],  "{flowcell}", "{chip}", "aligned", "{run_id}", "{hist_std_prefix}-fit.tif"),
    params:
        #hist_raw_stdpath  = hist_raw_stdpath,
        module_cmd        = get_envmodules_for_rule(["python", "gcc", "gdal"], module_config)
    run:
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        source {pyenv}/bin/activate

        # aligned histology
        {python} -m historef.referencer \
            --nge  {input.sdge_3in1_png}\
            --hne  {input.hist_raw} \
            --aligned {output.hist_aligned}
      
        # fit histology
        INFO=$(gdalinfo "{input.sdge_3in1_png}" 2>&1)

        if [[ $INFO =~ Size\ is\ ([0-9]+),\ ([0-9]+) ]]; then
            WIDTH=${{BASH_REMATCH[1]}}
            HEIGHT=${{BASH_REMATCH[2]}}
            echo "Extracted dimensions: WIDTH=${{WIDTH}}, HEIGHT=${{HEIGHT}}"
        else
            echo "Failed to extract image dimensions."
            exit 1
        fi

        gdalwarp \
        "{output.hist_aligned}" "{output.hist_fit}" -ct "+proj=pipeline +step +proj=axisswap +order=2,-1" \
        -overwrite \
        -te 0 -$HEIGHT $WIDTH 0 -ts $WIDTH $HEIGHT

        echo "gdalwarp command executed with dimensions: width=${{WIDTH}}, height=${{HEIGHT}}"
        """
        )


