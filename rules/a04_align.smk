rule a04_align:
    input:
        seq2_fqr1  = lambda wildcards: [os.path.join(main_dirs["seq2nd"], seq2_id, seq2_id + ".R1.fastq.gz" ) for seq2_id in rid2seq2[wildcards.run_id]],
        seq2_fqr2  = lambda wildcards: [os.path.join(main_dirs["seq2nd"], seq2_id, seq2_id + ".R2.fastq.gz" ) for seq2_id in rid2seq2[wildcards.run_id]],
        smatch_tsv = lambda wildcards: [os.path.join(main_dirs["match"],  "{flowcell}", "{chip}", seq2_id, seq2_id+".R1.match.sorted.uniq.tsv.gz") for seq2_id in rid2seq2[wildcards.run_id]],
    output:
        dge_gf_bcd  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "barcodes.tsv.gz"),
        dge_gf_ftr  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "features.tsv.gz"),
        dge_gf_mtx  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "GeneFull", "raw", "matrix.mtx.gz"),
        dge_gn_mtx  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Gene",     "raw", "matrix.mtx.gz"),
        dge_vl_spl  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "spliced.mtx.gz"),
        dge_vl_uns  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "unspliced.mtx.gz"),
        dge_vl_amb  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam", "sttoolsSolo.out", "Velocyto", "raw", "ambiguous.mtx.gz"),
    params:
        # dir 
        bam_dir        = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "bam"),
        # params
        min_match_len  = config.get("upstream", {}).get("align", {}).get('min_match_len', 30),
        min_match_frac = config.get("upstream", {}).get("align", {}).get('min_match_frac', 0.66),
        match_len      = config.get("upstream", {}).get("smatch", {}).get('match_len', 27), 
        skip_sbcd      = get_skip_sbcd(config), 
        len_sbcd       = config.get("upstream", {}).get("align", {}).get('len_sbcd', 30),
        len_umi        = config.get("upstream", {}).get("align", {}).get('len_umi', 9),
        len_r2         = config.get("upstream", {}).get("align", {}).get('len_r2', 101),
        exist_action   = config.get("upstream", {}).get("align", {}).get('exist_action', "overwrite"),
        # ref
        refidx         = sp2alignref[species],
        # resource
        ram            = lambda wildcards: assign_resource_for_align(wildcards.run_id, config, env_config, rid2seq2, main_dirs)["ram"],
        # module
        module_cmd        = get_envmodules_for_rule(["python", "samtools"], module_config),
    threads: 
        lambda wildcards:  assign_resource_for_align(wildcards.run_id, config, env_config, rid2seq2, main_dirs)["threads"], 
    resources: 
        time      = "100:00:00",
        mem       = lambda wildcards: assign_resource_for_align(wildcards.run_id, config, env_config, rid2seq2, main_dirs)["mem"],
        partition = lambda wildcards: assign_resource_for_align(wildcards.run_id, config, env_config, rid2seq2, main_dirs)["partition"],
    run:
        # exist action
        exist_action = ""
        assert params.exist_action in ["skip", "overwrite"], "exist_action should be skip or overwrite"

        if params.exist_action == "skip":
            exist_action = " --skip-existing "
        elif params.exist_action == "overwrite":
            exist_action =" --overwrite-existing "
        
        # refidx
        assert params.refidx is not None, "The alignment reference file is not provided. Check your environment configuration file."
        assert os.path.exists(params.refidx), f"The alignment reference file does not exist: {params.refidx}. Check your environment configuration file."
        
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        source {pyenv}/bin/activate

        command time -v {python} {local_scripts}/rule_a4.align-reads.py \
            --fq1 {input.seq2_fqr1} \
            --fq2 {input.seq2_fqr2} \
            --whitelist-match {input.smatch_tsv} \
            --filter-match {input.smatch_tsv} \
            --star-index {params.refidx} \
            --star-bin {star} \
            --min-match-len  {params.min_match_len} \
            --min-match-frac {params.min_match_frac} \
            --samtools {samtools} \
            --spatula {spatula} \
            --match-len {params.match_len} \
            --skip-sbcd {params.skip_sbcd} \
            --len-sbcd {params.len_sbcd} \
            --len-umi {params.len_umi} \
            --len-r2 {params.len_r2} \
            --out {params.bam_dir} \
            --threads {threads}  \
            --star-add-options "--limitBAMsortRAM {params.ram}" \
            {exist_action} 

        """)

