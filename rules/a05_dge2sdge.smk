rule a05_dge2sdge:
    input:
        #nbcds
        nbcd_tsv      = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_mnfst    = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{chip}", "manifest.tsv"),
        #smatch
        smatch_tsv    = lambda wildcards: [os.path.join(main_dirs["match"],  "{flowcell}", "{chip}", seq2_id, seq2_id+".R1.match.sorted.uniq.tsv.gz") for seq2_id in rid2seq2[wildcards.run_id]],
        #align
        dge_gf_bcd    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "barcodes.tsv.gz"),
        dge_gf_ftr    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "features.tsv.gz"),
        dge_gf_mtx    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "matrix.mtx.gz"),
        dge_gn_mtx    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Gene",     "raw", "matrix.mtx.gz"),
        dge_vl_spl    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "spliced.mtx.gz"),
        dge_vl_uns    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "unspliced.mtx.gz"),
        dge_vl_amb    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "ambiguous.mtx.gz"),
    output:
        sdge_bcd      = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.tsv.gz"),
        sdge_ftr      = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "features.tsv.gz"),
        sdge_mtx      = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "matrix.mtx.gz"),
        sdge_xyrange  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "barcodes.minmax.tsv"),
        sdge_3in1_png = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_match_sbcd.png"),
    params:
        # module
        module_cmd       = get_envmodules_for_rule(["python", "imagemagick"], module_config)
    resources: 
        mem           = "24000MB", 
        time          = "3:00:00"  
    run:
        sdge_dir = os.path.dirname(output.sdge_bcd)

        # Generate smatch_csvjoin.
        smatch_tsv_warg_match  = " --match ".join(expand(input.smatch_tsv))
        smatch_tsv_warg_smatch = " --nmatch ".join(expand(input.smatch_tsv))
    
        # Create minmax files.
        print("Creating minmax files...")
        df_mnfst=pd.read_csv(input.nbcd_mnfst, sep="\t")
        df_minmax=df_mnfst[["xmin", "xmax", "ymin", "ymax"]]
        df_minmax.to_csv(output.sdge_xyrange, sep="\t", index=False)
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        source {pyenv}/bin/activate
        
        echo -e "Creating sdge files...\\n"
        command time -v {spatula} dge2sdge \
            --bcd {input.dge_gf_bcd} \
            --ftr {input.dge_gf_ftr} \
            --mtx {input.dge_gn_mtx} \
            --mtx {input.dge_gf_mtx} \
            --mtx {input.dge_vl_spl} \
            --mtx {input.dge_vl_uns} \
            --mtx {input.dge_vl_amb} \
            --out {sdge_dir}/ \
            --match {smatch_tsv_warg_match}
        
        echo -e "Creating 3in1 image...\\n"
        command time -v {spatula} draw-3way \
            --manifest {input.nbcd_mnfst} \
            --nbcd {input.nbcd_tsv} \
            --nmatch {smatch_tsv_warg_smatch} \
            --ngebcd {output.sdge_bcd} \
            --out {output.sdge_3in1_png} 
        """
        )
        
