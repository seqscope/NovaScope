rule a05_dge2sdge:
    input:
        #nbcds
        nbcd_tsv      = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_mnfst    = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "manifest.tsv"),
        #nmatch
        nmatch_tsv    = lambda wildcards: [os.path.join(main_dirs["align"],  "{flowcell}", wildcards.section, "match", seq2_prefix+".R1.match.sorted.uniq.tsv.gz") for seq2_prefix in sc2seq2[wildcards.section]],
        #align
        dge_gf_bcd    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "barcodes.tsv.gz"),
        dge_gf_ftr    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "features.tsv.gz"),
        dge_gf_mtx    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "matrix.mtx.gz"),
        dge_gn_mtx    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "Gene",     "raw", "matrix.mtx.gz"),
        dge_vl_spl    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "spliced.mtx.gz"),
        dge_vl_uns    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "unspliced.mtx.gz"),
        dge_vl_amb    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "ambiguous.mtx.gz"),
    output:
        sdge_bcd      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "barcodes.tsv.gz"),
        sdge_ftr      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "features.tsv.gz"),
        sdge_mtx      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "matrix.mtx.gz"),
        sdge_rgb_png  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".gene_full_mito.png"),
        sdge_3in1_png = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".sge_match_sbcd.png"),
    params:
        rgb_layout       = rgb_layout,
        visual_max_scale = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("max_scale", 50),
        visual_res       = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("resolution", 1000),
    resources: 
        mem           = "24000MB", 
        time          = "3:00:00"  
    run:
        sdge_dir = os.path.dirname(output.sdge_bcd)
        # Generate smatch_csvjoin
        nmatch_tsv_warg_match  = " --match ".join(expand(input.nmatch_tsv))
        nmatch_tsv_warg_nmatch = " --nmatch ".join(expand(input.nmatch_tsv))
        shell(
        """
        module load imagemagick/7.1.0-25.lua
        source {py39_env}/bin/activate
        
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
            --match {nmatch_tsv_warg_match}
        
        echo -e "Creating 3in1 image...\\n"
        command time -v {spatula} draw-3way \
            --manifest {input.nbcd_mnfst} \
            --nbcd {input.nbcd_tsv} \
            --nmatch {nmatch_tsv_warg_nmatch} \
            --ngebcd {output.sdge_bcd} \
            --out {output.sdge_3in1_png} 

        echo -e "Creating rgb image...\\n"
        command time -v {py39} {local_scripts}/rgb-gene-image.py \
            --layout {params.rgb_layout} \
            --sdge {sdge_dir} \
            --out {output.sdge_rgb_png} \
            -r _all:1:2 \
            -g _all:1:3 \
            -b _all:1:4 \
            --max-scale {params.visual_max_scale} \
            --res {params.visual_res} \
            --transpose
        """)
