rule a04b_align_adt:
    input:
        seq2_fqr1  = lambda wildcards: [os.path.join(main_dirs["seq2nd"], seq2_id, seq2_id + ".R1.fastq.gz" ) for seq2_id in rid2seq2[wildcards.run_id]],
        seq2_fqr2  = lambda wildcards: [os.path.join(main_dirs["seq2nd"], seq2_id, seq2_id + ".R2.fastq.gz" ) for seq2_id in rid2seq2[wildcards.run_id]],
        smatch_tsv = lambda wildcards: [os.path.join(main_dirs["match"],  "{flowcell}", "{chip}", seq2_id, seq2_id+".R1.match.sorted.uniq.tsv.gz") for seq2_id in rid2seq2[wildcards.run_id]],
    output:
        adt_input_tsv  = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "adt", "input.tsv"),
        dge_umi_bcd    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "adt", "barcodes.tsv.gz"),
        dge_umi_ftr    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "adt", "features.tsv.gz"),
        dge_umi_mtx    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "adt", "umis.mtx.gz"),
        dge_read_mtx   = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "adt", "reads.mtx.gz"),
        dge_pix_mtx    = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "adt", "pixels.mtx.gz"),
    params:
        # dir 
        adt_dir        = os.path.join(main_dirs["align"],  "{flowcell}", "{chip}", "{run_id}", "adt"),
        # params
        skip_sbcd      = get_skip_sbcd(config), 
        adt_format     = config.get("upstream", {}).get("align", {}).get('adt_format', 'totalseq-a').lower(),
        adt_ref        = config.get("upstream", {}).get("align", {}).get('adt_ref', None), 
        # ref
        #refidx         = sp2alignref[species],
        sp2alignref     = env_config.get("ref", {}).get("align", None),
        # module
        module_cmd        = get_envmodules_for_rule(["python", "samtools"], module_config),
    resources: 
        time = "5:00:00",
        mem  = "6500m"
    run:
        ## parse adt_format
        assert params.adt_ref is not None, "The ADT reference file is not provided. Check your configuration file."

        if params.adt_format == "totalseq-a":
            ## For TotalSeq-A format, We have 1-27 (R1) as BCD, 1-15 (R2) as TAG, 16-16 (R2) as UMI
            bcd_beg = [1 + params.skip_sbcd]
            bcd_end = [27 + params.skip_sbcd]
            tag_beg = [1]
            tag_end = [15]
            umi_beg = [16]
            umi_end = [16]
        elif params.adt_format == "totalseq-c":
            ## For TotalSeq-C format, we have 1-27 (R1) as BCD, 11-25 (R2) as TAG, 1-10,26-34 as UMI.
            bcd_beg = [1 + params.skip_sbcd]
            bcd_end = [27 + params.skip_sbcd]
            tag_beg = [11]
            tag_end = [25]
            umi_beg = [1,26]
            umi_end = [10,34]
        else:
            raise ValueError(f"adt_format should be totalseq-a or totalseq-c, but got {params.adt_format}")
        
        assert len(bcd_beg) == len(bcd_end), "The number of barcode start and end positions are not consistent."
        assert len(tag_beg) == len(tag_end), "The number of tag start and end positions are not consistent."
        assert len(umi_beg) == len(umi_end), "The number of umi start and end positions are not consistent."
        bcd_pos = ",".join([f"{bcd_beg[i]}-{bcd_end[i]}" for i in range(len(bcd_beg))])
        tag_pos = ",".join([f"{tag_beg[i]}-{tag_end[i]}" for i in range(len(tag_beg))])
        umi_pos = ",".join([f"{umi_beg[i]}-{umi_end[i]}" for i in range(len(umi_beg))])
        
        # create TSV files
        assert len(input.seq2_fqr1) == len(input.seq2_fqr2) == len(input.smatch_tsv), "The number of input files are not consistent."
        
        os.makedirs(adt_dir, exist_ok=True)
        with open(output.adt_input_tsv, "w") as fout:
            for i in range(len(input.seq2_fqr1)):
                fout.write(f"{input.seq2_fqr1[i]}\t{input.seq2_fqr2[i]}\t{input.smatch_tsv[i]}\n")
        
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        source {pyenv}/bin/activate

        command time -v {python} {novascope_scripts}/rule_a4b.align-reads-adt.py \
            --tsv {output.adt_input_tsv} \
            --tag {params.adt_ref} \
            --match-tag \
            --build-sge \
            --merge-sge \
            --bcd-pos {bcd_pos} \
            --tag-pos {tag_pos} \
            --umi-pos {umi_pos} \
            --spatula {spatula} \
            --skip-sbcd {params.skip_sbcd} \
            --out {params.adt_dir} 
            {exist_action} 

        """)

