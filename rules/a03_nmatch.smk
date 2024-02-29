rule a03_nmatch:
    input:
        seq2_fqr1        = os.path.join(main_dirs["seq2nd"], "{seq2_prefix}", "{seq2_prefix}" + ".R1.fastq.gz"),
        seq2_fqr2        = os.path.join(main_dirs["seq2nd"], "{seq2_prefix}", "{seq2_prefix}" + ".R2.fastq.gz"),
        nbcd_tsv         = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_png         = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.png"),
    output:
        nmatch_tsv      = os.path.join(main_dirs["align"], "{flowcell}", "{section}", "match", "{seq2_prefix}"+".R1.match.sorted.uniq.tsv.gz"),
        nmatch_summary  = os.path.join(main_dirs["align"], "{flowcell}", "{section}", "match", "{seq2_prefix}"+".R1.summary.tsv"),
        nmatch_count    = os.path.join(main_dirs["align"], "{flowcell}", "{section}", "match", "{seq2_prefix}"+".R1.counts.tsv"),
        nmatch_png      = os.path.join(main_dirs["align"], "{flowcell}", "{section}", "match", "{seq2_prefix}"+".R1.match.png"),
    params:
        # nmatch
        skip_sbcd       = config.get("preprocess", {}).get("nmatch", {}).get('skip_sbcd', 0), # Set 1 for N3-HG5MC, 0 for others.
        match_len       = config.get("preprocess", {}).get("nmatch", {}).get('match_len', 27), 
        # visualization
        visual_coord_per_pixel    = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("coord_per_pixel", 1000),
        visual_intensity_per_obs  = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("intensity_per_obs", 50),
        visual_icol_x             = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("icol_x", 3),
        visual_icol_y             = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("col_y", 4),
    resources:
        time = "50:00:00",
        mem  = "13000m"
    run:
        nbcd_dir        = os.path.dirname(input.nbcd_tsv)
        nmatch_prefix   = output.nmatch_tsv.replace(".match.sorted.uniq.tsv.gz", "")
        shell(
        """
        module load imagemagick/7.1.0-25.lua
        source {py39_env}/bin/activate

        echo "Runing step1 match-sbcds.\\n"
        command time -v {spatula} match-sbcds \
            --fq {input.seq2_fqr1} \
            --sbcd {nbcd_dir} \
            --skip-sbcd {params.skip_sbcd} \
            --out {nmatch_prefix} \
            --match-len {params.match_len}

        echo "Runing step2 draw-xy.\\n"
        command time -v {spatula} draw-xy --tsv {output.nmatch_tsv} \
            --out {output.nmatch_png} \
            --coord-per-pixel {params.visual_coord_per_pixel} \
            --icol-x {params.visual_icol_x} \
            --icol-y {params.visual_icol_y} \
            --intensity-per-obs {params.visual_intensity_per_obs}
        """)
