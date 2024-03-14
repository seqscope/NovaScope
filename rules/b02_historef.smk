
#==============================================
#
# cart step3. Processing Backgrounds - histology H&E  
#
#==============================================

rule b02_historef:
    input:
        sdge_3in1_png  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".sge_match_sbcd.png"),
    output:
        hist_aligned   = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "histology", "{specie_with_seq2v}", hist_std_fn),
        hist_fit       = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "histology", "{specie_with_seq2v}", hist_fit_fn),
    params:
        hist_std_tif   = hist_std_tif,
        module_cmd     = get_envmodules_for_rule(["python", "gcc", "gdal"], module_config)
    run:
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        source {pyenv}/bin/activate

        # aligned histology
        {python} -m historef.referencer \
            --nge  {input.sdge_3in1_png}\
            --hne {params.hist_std_tif} \
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


