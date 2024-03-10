rule a04_align:
    input:
        seq2_fqr1  = lambda wildcards: [os.path.join(main_dirs["seq2nd"], seq2_prefix, seq2_prefix + ".R1.fastq.gz" ) for seq2_prefix in sc2seq2[wildcards.section]],
        seq2_fqr2  = lambda wildcards: [os.path.join(main_dirs["seq2nd"], seq2_prefix, seq2_prefix + ".R2.fastq.gz" ) for seq2_prefix in sc2seq2[wildcards.section]],
        nmatch_tsv = lambda wildcards: [os.path.join(main_dirs["align"],  "{flowcell}", wildcards.section, "match", seq2_prefix+".R1.match.sorted.uniq.tsv.gz") for seq2_prefix in sc2seq2[wildcards.section]],
    output:
        dge_gf_bcd  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}", "sttoolsSolo.out", "GeneFull", "raw", "barcodes.tsv.gz"),
        dge_gf_ftr  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}", "sttoolsSolo.out", "GeneFull", "raw", "features.tsv.gz"),
        dge_gf_mtx  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}", "sttoolsSolo.out", "GeneFull", "raw", "matrix.mtx.gz"),
        dge_gn_mtx  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}", "sttoolsSolo.out", "Gene",     "raw", "matrix.mtx.gz"),
        dge_vl_spl  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}", "sttoolsSolo.out", "Velocyto", "raw", "spliced.mtx.gz"),
        dge_vl_uns  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}", "sttoolsSolo.out", "Velocyto", "raw", "unspliced.mtx.gz"),
        dge_vl_amb  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}", "sttoolsSolo.out", "Velocyto", "raw", "ambiguous.mtx.gz"),
    params:
        # dir 
        bam_dir        = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}"),
        # params
        skip_sbcd      = get_skip_sbcd(config), 
        match_len      = config.get("preprocess", {}).get("nmatch", {}).get('match_len', 27), 
        len_sbcd       = config.get("preprocess", {}).get("align", {}).get('len_sbcd', 30),
        min_match_len  = config.get("preprocess", {}).get("align", {}).get('min_match_len', 30),
        min_match_frac = config.get("preprocess", {}).get("align", {}).get('min_match_frac', 0.66),
        # ref
        refidx         = os.path.join(env_dir, "ref", "align", specie),
        # resource
        ram            = lambda wildcards: assign_resource_for_align(wildcards.section, config, sc2seq2, main_dirs)["ram"],
        # module
        module_cmd        = get_envmodules_for_rule(["python"], module_config, exe_mode)
    threads: 
        lambda wildcards:  assign_resource_for_align(wildcards.section, config, sc2seq2, main_dirs)["threads"], 
    resources: 
        time      = "100:00:00",
        mem       = lambda wildcards: assign_resource_for_align(wildcards.section, config, sc2seq2, main_dirs)["mem"],
        partition = lambda wildcards: assign_resource_for_align(wildcards.section, config, sc2seq2, main_dirs)["partition"],
    run:
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        source {py39_env}/bin/activate

        command time -v {py39} {local_scripts}/rule_a4.align-reads.py \
            --skip-sbcd {params.skip_sbcd} \
            --spatula {spatula} \
            --fq1 {input.seq2_fqr1} \
            --fq2 {input.seq2_fqr2} \
            --whitelist-match {input.nmatch_tsv} \
            --filter-match {input.nmatch_tsv} \
            --star-index {params.refidx} \
            --star-bin {star} \
            --samtools {samtools} \
            --min-match-len  {params.min_match_len}\
            --min-match-frac {params.min_match_frac}\
            --out {params.bam_dir} \
            --threads {threads}  \
            --match-len {params.match_len} \
            --len-sbcd {params.len_sbcd} \
            --star-add-options "--limitBAMsortRAM {params.ram}"

        """)

