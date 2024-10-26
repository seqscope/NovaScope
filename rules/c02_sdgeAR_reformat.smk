rule c02_sdgeAR_reformat:
    input:
        sdgeAR_bcd        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.tsv.gz"),
        sdgeAR_ftr        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "features.tsv.gz"),
        sdgeAR_mtx        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "matrix.mtx.gz"),
        sdgeAR_xyrange    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
    output:
        ftr               = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz"),
        transcript        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"),
        transcript_tbi    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz.tbi"),
    params:
        sp2geneinfo       = config.get("env",{}).get("ref", {}).get("geneinfo", None),
        species           = species,
        # tools
        module_cmd        = get_envmodules_for_rule(["samtools"], config.get("env",{}).get("envmodules", {}))
    threads: 2
    resources:
        mem  = "14000MB",
        time = "20:00:00", 
    run:
        # Determine the sort column based on the major_axis value
        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col")
        if major_axis == "Y":
            sort_column="-k4,4n"
            tabix_column="-b4 -e4"
        else:
            sort_column="-k3,3n"
            tabix_column="-b3 -e3"
        
        shell(
        r"""
        {params.module_cmd}

        # Prepare the feature file
        zcat {input.sdgeAR_ftr} | cut -f 1,2,4 | sed 's/,/\t/g' | sed '1 s/^/gene_id\tgene\tgn\tgt\tspl\tunspl\tambig\n/' | gzip -c > {output.ftr}

        # Merge the feature, barcode, and matrix files
        awk 'BEGIN{{FS=OFS="\t"}} NR==FNR{{ft[$3]=$1 FS $2 ;next}} ($1 in ft) {{print $2 FS $3 FS $4 FS $5 FS ft[$1] FS $6 FS $7 FS $8 FS $9 FS $10 }}' \
            <(zcat {input.sdgeAR_ftr}) \
            <(join -t $'\t' -1 1 -2 2 -o '2.1,1.2,1.3,1.4,1.5,2.3,2.4,2.5,2.6,2.7' \
                <(zcat {input.sdgeAR_bcd}   | cut -f 2,4-8) \
                <(zcat {input.sdgeAR_mtx}     | tail -n +4 | sed 's/ /\t/g' )) | \
            sed -E 's/\t[[:alnum:]]+_/\t/' | \
            sort -S 10G -k1,1n {sort_column}| \
            sed '1 s/^/#lane\ttile\tX\tY\tgene_id\tgene\tgn\tgt\tspl\tunspl\tambig\n/' | \
            bgzip -c > {output.transcript}

        tabix -0 -f -s1 {tabix_column} {output.transcript}
        """
        )