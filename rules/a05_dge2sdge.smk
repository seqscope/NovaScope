rule a05_dge2sdge:
    input:
        #nbcds
        nbcd_tsv      = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_mnfst    = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "manifest.tsv"),
        #smatch
        smatch_tsv    = lambda wildcards: [os.path.join(main_dirs["align"],  "{flowcell}", wildcards.section, "match", seq2_prefix+".R1.match.sorted.uniq.tsv.gz") for seq2_prefix in sc2seq2[wildcards.section]],
        #align
        dge_gf_bcd    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{species_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "barcodes.tsv.gz"),
        dge_gf_ftr    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{species_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "features.tsv.gz"),
        dge_gf_mtx    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{species_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "matrix.mtx.gz"),
        dge_gn_mtx    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{species_with_seq2v}","sttoolsSolo.out", "Gene",     "raw", "matrix.mtx.gz"),
        dge_vl_spl    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{species_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "spliced.mtx.gz"),
        dge_vl_uns    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{species_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "unspliced.mtx.gz"),
        dge_vl_amb    = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{species_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "ambiguous.mtx.gz"),
    output:
        sdge_bcd      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{species_with_seq2v}", "barcodes.tsv.gz"),
        sdge_ftr      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{species_with_seq2v}", "features.tsv.gz"),
        sdge_mtx      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{species_with_seq2v}", "matrix.mtx.gz"),
        sdge_rgb_png  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{species_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{species_with_seq2v}"+".gene_full_mito.png"),
        sdge_3in1_png = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{species_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{species_with_seq2v}"+".sge_match_sbcd.png"),
    params:
        rgb_layout       = check_path(config.get("preprocess", {}).get("dge2sdge", {}).get('layout', None), job_dir, strict_mode=False),
        visual_max_scale = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("max_scale", 50),
        visual_res       = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("resolution", 1000),
        # module
        module_cmd        = get_envmodules_for_rule(["python", "imagemagick"], module_config)
    resources: 
        mem           = "24000MB", 
        time          = "3:00:00"  
    run:
        sdge_dir = os.path.dirname(output.sdge_bcd)

        # Generate smatch_csvjoin.
        smatch_tsv_warg_match  = " --match ".join(expand(input.smatch_tsv))
        smatch_tsv_warg_smatch = " --smatch ".join(expand(input.smatch_tsv))

        # Check the layout for rgb-gene-image.
        if params.rgb_layout is not None:
            rgb_layout = params.rgb_layout
            assert os.path.exists(params.rgb_layout), f"The provided RGB layout file does not exist: {params.rgb_layout}"
            print(f"Using the provided RGB layout file: {params.rgb_layout}.")
        else: 
            rgb_layout = os.path.join(smk_dir, "info", "assets", "layout_per_section_basis", "layout.1x1.tsv")
            assert os.path.exists(rgb_layout), f"The default RGB layout file does not exist: {rgb_layout}."
            print(f"Using the default RGB layout file: {rgb_layout}.")

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

        echo -e "Creating rgb image...\\n"
        command time -v {python} {local_scripts}/rgb-gene-image.py \
            --layout {rgb_layout} \
            --sdge {sdge_dir} \
            --out {output.sdge_rgb_png} \
            -r _all:1:2 \
            -g _all:1:3 \
            -b _all:1:4 \
            --max-scale {params.visual_max_scale} \
            --res {params.visual_res} \
            --transpose
        """)
