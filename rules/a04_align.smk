
# Q: Better solution to define the mem and time for alignment?
def get_resource_for_align(section):
    fqsize = 0
    for seq2_prefix in sc2seq2[section]:
        seq2_fqr1 = os.path.join(main_dirs["seq2nd"], seq2_prefix, seq2_prefix + ".R1.fastq.gz" )
        seq2_fqr2 = os.path.join(main_dirs["seq2nd"], seq2_prefix, seq2_prefix + ".R2.fastq.gz" )
        fqsize += ( os.path.getsize(seq2_fqr1) / 1e9 )
        fqsize += ( os.path.getsize(seq2_fqr2) / 1e9 )

    if fqsize < 200:
        partition = "standard"
        threads = 10
        mem = "70000m"
        ram = "70000000000"
    elif fqsize < 400:
        partition = "standard"
        threads = 20
        mem = "140000m"
        ram = "140000000000"
    else:
        partition = "largemem"
        threads = 10
        mem = "330000m"
        ram = "330000000000"
    resources = {
        "mem": mem,
        "threads": threads,
        "partition": partition,
        "ram": ram
    }
    return resources

def get_defresource_for_align(section):
    resources = {
        "mem": "70000m",
        "threads": 10,
        "partition": "standard",
        "ram": "70000000000"
    }
    return resources
    
rule a04_align:
    input:
        seq2_fqr1  = lambda wildcards: [os.path.join(main_dirs["seq2nd"], seq2_prefix, seq2_prefix + ".R1.fastq.gz" ) for seq2_prefix in sc2seq2[wildcards.section]],
        seq2_fqr2  = lambda wildcards: [os.path.join(main_dirs["seq2nd"], seq2_prefix, seq2_prefix + ".R2.fastq.gz" ) for seq2_prefix in sc2seq2[wildcards.section]],
        nmatch_tsv = lambda wildcards: [os.path.join(main_dirs["align"],  "{flowcell}", wildcards.section, "match", seq2_prefix+".R1.match.sorted.uniq.tsv.gz") for seq2_prefix in sc2seq2[wildcards.section]],
    output:
        dge_gf_bcd  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "barcodes.tsv.gz"),
        dge_gf_ftr  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "features.tsv.gz"),
        dge_gf_mtx  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "GeneFull", "raw", "matrix.mtx.gz"),
        dge_gn_mtx  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "Gene",     "raw", "matrix.mtx.gz"),
        dge_vl_spl  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "spliced.mtx.gz"),
        dge_vl_uns  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "unspliced.mtx.gz"),
        dge_vl_amb  = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}","sttoolsSolo.out", "Velocyto", "raw", "ambiguous.mtx.gz"),
    params:
        bam_dir        = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "bam", "{specie_with_seq2v}"),
        skip_sbcd      = get_skip_sbcd(config), 
        match_len      = config.get("preprocess", {}).get("nmatch", {}).get('match_len', 27), 
        len_sbcd       = config.get("preprocess", {}).get("align", {}).get('len_sbcd', 30),
        min_match_len  = config.get("preprocess", {}).get("align", {}).get('min_match_len', 30),
        min_match_frac = config.get("preprocess", {}).get("align", {}).get('min_match_frac', 0.66),
        refidx         = os.path.join(env_dir, "ref", "align", specie),
        ram            = lambda wildcards: get_defresource_for_align(wildcards.section)["ram"],
    threads: 
        lambda wildcards: get_defresource_for_align(wildcards.section)["threads"], 
    resources: 
        time      = "100:00:00",
        mem       = lambda wildcards: get_defresource_for_align(wildcards.section)["mem"],
        partition = lambda wildcards: get_defresource_for_align(wildcards.section)["partition"],
    run:
        shell(
        """
        set -euo pipefail

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

