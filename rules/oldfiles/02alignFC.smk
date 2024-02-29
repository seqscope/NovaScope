
#==============================================
#
# 02. Alignment (per fc)
#
#==============================================

def align_resources(fc):
    fqsize = 0
    for seq2_id in fc2seq2[fc]:
        seq2_fqr1 = os.path.join(tmp_root,"seq2", fc, seq2_id + "_1.fastq.gz")
        seq2_fqr2 = os.path.join(tmp_root,"seq2", fc, seq2_id + "_2.fastq.gz")
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

rule alignFC:
    input:
        seq2_fqr1  = lambda wildcards: [os.path.join(tmp_root,"seq2", wildcards.fc, seq2_id + "_1.fastq.gz") for seq2_id in fc2seq2[wildcards.fc]],
        seq2_fqr2  = lambda wildcards: [os.path.join(tmp_root,"seq2", wildcards.fc, seq2_id + "_2.fastq.gz") for seq2_id in fc2seq2[wildcards.fc]],
        smatch_csv = lambda wildcards: [os.path.join(smatch_root,     wildcards.fc, seq2_id + ".match.sorted.uniq.tsv.gz") for seq2_id in fc2seq2[wildcards.fc]],
    output:
        dgeFC_dir = directory(os.path.join(dgeFC_root, "{fc}", "{sp}")),
        dgeFC_bam = os.path.join(dgeFC_root, "{fc}", "{sp}","sttoolsAligned.sortedByCoord.out.bam"),
    params:
        ref     = os.path.join(tmp_root, "ref_align", "{sp}"),
        minfrac = config["alignFC"]["minfrac"],
        minlen  = config["alignFC"]["minlen"] ,
        ram     = lambda wildcards: align_resources(wildcards.fc)["ram"],
    threads: 
        lambda wildcards: align_resources(wildcards.fc)["threads"], #reserve that number of CPU cores from THE TOTAL AVAILABLE!
    resources:
        mem       = lambda wildcards: align_resources(wildcards.fc)["mem"],
        partition = lambda wildcards: align_resources(wildcards.fc)["partition"],
        time      = "48:00:00",
    run:
        shell(
        """
        source {py310_env}/bin/activate

        command time -v {py310} {sttools2}/scripts/align-reads.py \
            --spatula {spatula} \
            --fq1 {input.seq2_fqr1} \
            --fq2 {input.seq2_fqr2} \
            --whitelist-match {input.smatch_csv} \
            --filter-match {input.smatch_csv} \
            --star-index {params.ref} \
            --star-bin {star} \
            --samtools {samtools} \
            --min-match-len  {params.minlen}\
            --min-match-frac {params.minfrac}\
            --out {output.dgeFC_dir}\
            --threads {threads} \
            --star-add-options "--limitBAMsortRAM {params.ram}"
        """
        )

