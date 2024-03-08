
#==============================================
#
# cart step3. Processing Backgrounds - histology H&E  
#
#==============================================

rule b02_hist_align:
    input:
        sdge_3in1_png  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".sge_match_sbcd.png"),
    output:
        hist_aligned   = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "histology", "{specie_with_seq2v}", hist_std_fn),
        hist_fit       = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "histology", "{specie_with_seq2v}", hist_fit_fn),
    params:
        hist_std_tif   = hist_std_tif
    run:
        shell(
        r"""
        set -euo pipefail

        if [[ "{exe_mode}" == "HPC" ]]; then
            module load gcc/10.3.0 gdal/3.5.1
        fi
        
        source {py39_env}/bin/activate

        # aligned histology
        {py39} -m historef.referencer \
            --nge  {input.sdge_3in1_png}\
            --hne {params.hist_std_tif} \
            --aligned {output.hist_aligned}

      
        # fit histology
        INFO=$(gdalinfo "{input.sdge_3in1_png}" 2>&1)

        if [[ $INFO =~ Size\ is\ ([0-9]+),\ ([0-9]+) ]]; then
            WIDTH=${BASH_REMATCH[1]}
            HEIGHT=${BASH_REMATCH[2]}
            echo "Extracted dimensions: WIDTH=${WIDTH}, HEIGHT=${HEIGHT}"
        else
            echo "Failed to extract image dimensions."
            exit 1
        fi

        # Step 3: Run gdalwarp with the extracted width and height
        gdalwarp \
        "{output.hist_aligned}" "{output.hist_fit}" -ct "+proj=pipeline +step +proj=axisswap +order=2,-1" \
        -overwrite \
        -te 0 -$HEIGHT $WIDTH 0 -ts $WIDTH $HEIGHT

        echo "gdalwarp command executed with dimensions: width=${WIDTH}, height=${HEIGHT}"
        """
        )


