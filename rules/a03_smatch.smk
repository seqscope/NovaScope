rule a03_smatch:
    input:
        seq2_fqr1       = os.path.join(main_dirs["seq2nd"], "{seq2_id}", "{seq2_id}"+".R1.fastq.gz"),
        seq2_fqr2       = os.path.join(main_dirs["seq2nd"], "{seq2_id}", "{seq2_id}"+".R2.fastq.gz"),
        nbcd_tsv        = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_png        = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{chip}", "1_1.sbcds.sorted.png"),
    output:
        smatch_tsv      = os.path.join(main_dirs["match"], "{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.match.sorted.uniq.tsv.gz"),
        smatch_summary  = os.path.join(main_dirs["match"], "{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.summary.tsv"),
        smatch_count    = os.path.join(main_dirs["match"], "{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.counts.tsv"),
        smatch_png      = os.path.join(main_dirs["match"], "{flowcell}", "{chip}", "{seq2_id}", "{seq2_id}"+".R1.match.png"),
    params:
        # smatch
        skip_sbcd       = get_skip_sbcd(config), 
        match_len       = config.get("upstream", {}).get("smatch", {}).get('match_len', 27), 
        # visualization
        visual_coord_per_pixel    = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("coord_per_pixel", 1000),
        visual_intensity_per_obs  = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("intensity_per_obs", 50),
        visual_icol_x             = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("icol_x", 3),
        visual_icol_y             = config.get("upstream", {}).get("visualization", {}).get("drawxy",{}).get("col_y", 4),
        # tools
        module_cmd        = get_envmodules_for_rule(["imagemagick"], config.get("env",{}).get("envmodules", {}))
    resources:
        time = "50:00:00",
        mem  = "13000m"
    run:
        nbcd_dir            = os.path.dirname(input.nbcd_tsv)
        smatch_prefix_w_dir = output.smatch_tsv.replace(".match.sorted.uniq.tsv.gz", "")
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        echo "Runing step1 match-sbcds.\\n"
        command time -v {spatula} match-sbcds \
            --fq {input.seq2_fqr1} \
            --sbcd {nbcd_dir} \
            --skip-sbcd {params.skip_sbcd} \
            --out {smatch_prefix_w_dir} \
            --match-len {params.match_len}

        echo "Runing step2 draw-xy.\\n"
        command time -v {spatula} draw-xy --tsv {output.smatch_tsv} \
            --out {output.smatch_png} \
            --coord-per-pixel {params.visual_coord_per_pixel} \
            --icol-x {params.visual_icol_x} \
            --icol-y {params.visual_icol_y} \
            --intensity-per-obs {params.visual_intensity_per_obs}
        """)
