
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
    params:
        hist_std_tif   = hist_std_tif
    run:
        shell(
        """
        set -e 
        module load gcc/10.3.0 gdal/3.5.1
        source {py39_env}/bin/activate

        {py39} -m historef.referencer \
            --nge  {input.sdge_3in1_png}\
            --hne {params.hist_std_tif} \
            --aligned {output.hist_aligned}
        """
        )


