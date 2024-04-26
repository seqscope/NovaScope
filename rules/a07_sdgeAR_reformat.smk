rule a07_sdgeAR_reformat:
    input:
        sdgeAR_bcd        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.tsv.gz"),
        sdgeAR_ftr        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "features.tsv.gz"),
        sdgeAR_mtx        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "matrix.mtx.gz"),
        sdgeAR_xyrange    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
    output:
        sdgeAR_ftr_tab    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz"),
        sdgeAR_ftr_tabqc  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.clean.tsv.gz"),
        sdgeAR_transcript = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.merged.matrix.tsv.gz"),
    params:
        # gene filtering parameters
        kept_gene_type    = config.get("downstream", {}).get('gene_filter', {}).get('kept_gene_type', "protein_coding,lncRNA"),
        rm_gene_regex     = r"{0}".format(config.get("downstream", {}).get('gene_filter', {}).get('rm_gene_regex', "^Gm\\d+|^mt-|^MT-")), 
        # geneinfo
        geneinfo          = sp2geneinfo[species],
        # module
        module_cmd        = get_envmodules_for_rule(["samtools"], module_config)
    threads: 2
    resources:
        mem  = "14000MB",
        time = "20:00:00", 
    run:
        # Sanity Check: geneinfo
        assert params.geneinfo is not None, "The reference file for gene information is not provided. Check your environment configuration file."
        assert os.path.exists(params.geneinfo), "The reference file for gene information does not exist. Check your environment configuration file."

        # Major axis
        major_axis=find_major_axis(input.sdgeAR_xyrange, format="col")

        # Determine the sort column based on the major_axis value
        if major_axis == "Y":
            sort_column="-k4,4n"
            tabix_column="-b4 -e4"
        else:
            sort_column="-k3,3n"
            tabix_column="-b3 -e3"
        
        print("flag1 ")
        # Temporary files
        sdgeAR_ftr_tabqc_unzip = output.sdgeAR_ftr_tabqc.rstrip(".gz")
        
        shell(
        r"""
        {params.module_cmd}

        # Prepare the feature file
        zcat {input.sdgeAR_ftr} | cut -f 1,2,4 | sed 's/,/\t/g' | sed '1 s/^/gene_id\tgene\tgn\tgt\tspl\tunspl\tambig\n/' | gzip -c > {output.sdgeAR_ftr_tab}

        echo "flag2"

        kept_gene_type=$(echo "{params.kept_gene_type}" | sed 's/,/\|/')
        rm_gene_regex=$(echo "{params.rm_gene_regex}" | sed 's/\^/\\t/g')
        echo "flag2.1"
        echo -e "gene_id\tgene\tgn\tgt\tspl\tunspl\tambig" > {sdgeAR_ftr_tabqc_unzip}
        echo "flag2.2"

        awk 'BEGIN{{FS=OFS="\t"}} NR==FNR{{ft[$1]=$1; next}} ($1 in ft && $4 + 0 > 50){{print $0}}' \
            <(zcat {params.geneinfo} | grep -P "${{kept_gene_type}}" | cut -f 4 ) \
            <(zcat {output.sdgeAR_ftr_tab})| \
            grep -vP "${{rm_gene_regex}}" >> {sdgeAR_ftr_tabqc_unzip}
        echo "flag3.1"

        gzip -f {sdgeAR_ftr_tabqc_unzip}

        echo "flag3.2"

        # Merge the feature, barcode, and matrix files
        ls -hlt {input.sdgeAR_ftr} {input.sdgeAR_bcd} {input.sdgeAR_mtx}

        awk 'BEGIN{{FS=OFS="\t"}} NR==FNR{{ft[$3]=$1 FS $2 ;next}} ($1 in ft) {{print $2 FS $3 FS $4 FS $5 FS ft[$1] FS $6 FS $7 FS $8 FS $9 FS $10 }}' \
            <(zcat {input.sdgeAR_ftr}) \
            <(join -t $'\t' -1 1 -2 2 -o '2.1,1.2,1.3,1.4,1.5,2.3,2.4,2.5,2.6,2.7' \
                <(zcat {input.sdgeAR_bcd}   | cut -f 2,4-8) \
                <(zcat {input.sdgeAR_mtx}     | tail -n +4 | sed 's/ /\t/g' )) | \
            sed -E 's/\t[[:alnum:]]+_/\t/' | \
            sort -S 10G -k1,1n {sort_column}| \
            sed '1 s/^/#lane\ttile\tX\tY\tgene_id\tgene\tgn\tgt\tspl\tunspl\tambig\n/' | \
            bgzip -c > {output.sdgeAR_transcript}

        echo "flag4"

        tabix -0 -f -s1 {tabix_column} {output.sdgeAR_transcript}


        """
        )


