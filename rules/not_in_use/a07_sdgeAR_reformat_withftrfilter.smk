def locate_geneinfo(sp2geneinfo, species, ficture):
    if sp2geneinfo is not None:
        sp2geneinfo = sp2geneinfo
    else:
        ficture_info = os.path.join(ficture, "info")
        sp2geneinfo = {
                        "mouse": os.path.join(ficture_info, "Mus_musculus.GRCm39.107.names.tsv.gz"),
                        "human": os.path.join(ficture_info, "Homo_sapiens.GRCh38.107.names.tsv.gz")
                    }            
    geneinfo = sp2geneinfo[species]
    assert geneinfo is not None, f"Error: Missing gene information file for {species}. Please check the 'geneinfo' configuration in your environment configuration file."
    assert os.path.exists(geneinfo), f"Error: The gene information file for {species} does not exist. Please verify the file path in your environment configuration file."
    return geneinfo

rule a07_sdgeAR_reformat:
    input:
        sdgeAR_bcd        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.tsv.gz"),
        sdgeAR_ftr        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "features.tsv.gz"),
        sdgeAR_mtx        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "matrix.mtx.gz"),
        sdgeAR_xyrange    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "sgeAR", "barcodes.minmax.tsv"),
    output:
        sdgeAR_ftr_tab    = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz"),
        sdgeAR_ftr_tabqc  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.clean.tsv.gz"),
        sdgeAR_transcript = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"),
    params:
        sp2geneinfo       = env_config.get("ref", {}).get("geneinfo", None),
        species           = species,
        # gene filtering parameters
        gfilter_mode      = config.get("downstream", {}).get('gene_filter', {}).get('mode', "type,regex,count"),
        kept_gene_type    = config.get("downstream", {}).get('gene_filter', {}).get('kept_gene_type', "protein_coding,lncRNA"),
        rm_gene_regex     = r"{0}".format(config.get("downstream", {}).get('gene_filter', {}).get('rm_gene_regex', "^Gm\\d+|^mt-|^MT-")), 
        min_ct_per_feature= config.get("downstream", {}).get('gene_filter', {}).get('min_ct_per_feature', 50),
        # module
        module_cmd        = get_envmodules_for_rule(["samtools"], module_config)
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
        
        # Temporary files
        sdgeAR_ftr_tabqc_unzip = output.sdgeAR_ftr_tabqc.rstrip(".gz")

        # Gene filtering
        gfilter_modes = params.gfilter_mode.replace(" ","").split(",")
        gfilter_cmds = []
        if len(gfilter_modes) > 0:
            gfilter_cmds.append(f"echo -e \"gene_id\\tgene\\tgn\\tgt\\tspl\\tunspl\\tambig\" > {sdgeAR_ftr_tabqc_unzip}")
            # 1) count
            if "count" in gfilter_modes:
                min_ct_per_feature = params.min_ct_per_feature
                print(f"Gene filtering by count: Use {min_ct_per_feature}...")
            else:
                min_ct_per_feature = 0
                print(f"Gene filtering by count: Skip...")
            # 2) regex:
            if "regex" in gfilter_modes:
                gfilter_cmds.append(f"rm_gene_regex=$(echo \"{params.rm_gene_regex}\" | sed 's/^/\\t/g')")
                regex_cmd = f"| grep -vP \"${{rm_gene_regex}}\""  
                print(f"Gene filtering by regex: Use {params.rm_gene_regex}...")
            else:
                regex_cmd = ""
                print(f"Gene filtering by regex: Skip...")
            # 3) type
            if "type" in gfilter_modes:
                geneinfo = locate_geneinfo(params.sp2geneinfo, params.species, ficture)
                print(f"Gene filtering by gene type: Use {geneinfo}...")
                gfilter_cmds.append(f"kept_gene_type=$(echo \"{params.kept_gene_type}\" | sed 's/,/|/')")
                type_cmd = (
                    f"awk 'BEGIN{{FS=OFS=\"\\t\"}} NR==FNR{{ft[$1]=$1; next}} ($1 in ft && $4 + 0 > {min_ct_per_feature}){{print $0}}' <(zcat {geneinfo} | grep -P \"${{kept_gene_type}}\" | cut -f 4 ) <(zcat {output.sdgeAR_ftr_tab}) {regex_cmd} >> {sdgeAR_ftr_tabqc_unzip}"
                )
            else:
                print(f"Gene filtering by gene type: Skip...")
                type_cmd = (
                    f"zcat {output.sdgeAR_ftr_tab} {regex_cmd} | awk 'BEGIN{{FS=OFS=\"\\t\"}} ($4 + 0 > {min_ct_per_feature}){{print $0}}' >> {sdgeAR_ftr_tabqc_unzip}"
                )
            gfilter_cmds.append(type_cmd)
            gfilter_cmds.append(f"gzip -f {sdgeAR_ftr_tabqc_unzip}")
            gfilter_cmd = "\n".join(gfilter_cmds)    
        else:
            gfilter_cmd=f"ln -s  {output.sdgeAR_ftr_tab}  {output.sdgeAR_ftr_tabqc}"
        shell(
        r"""
        {params.module_cmd}

        # Prepare the feature file
        zcat {input.sdgeAR_ftr} | cut -f 1,2,4 | sed 's/,/\t/g' | sed '1 s/^/gene_id\tgene\tgn\tgt\tspl\tunspl\tambig\n/' | gzip -c > {output.sdgeAR_ftr_tab}

        # feature clean
        {gfilter_cmd}

        # Merge the feature, barcode, and matrix files
        awk 'BEGIN{{FS=OFS="\t"}} NR==FNR{{ft[$3]=$1 FS $2 ;next}} ($1 in ft) {{print $2 FS $3 FS $4 FS $5 FS ft[$1] FS $6 FS $7 FS $8 FS $9 FS $10 }}' \
            <(zcat {input.sdgeAR_ftr}) \
            <(join -t $'\t' -1 1 -2 2 -o '2.1,1.2,1.3,1.4,1.5,2.3,2.4,2.5,2.6,2.7' \
                <(zcat {input.sdgeAR_bcd}   | cut -f 2,4-8) \
                <(zcat {input.sdgeAR_mtx}     | tail -n +4 | sed 's/ /\t/g' )) | \
            sed -E 's/\t[[:alnum:]]+_/\t/' | \
            sort -S 10G -k1,1n {sort_column}| \
            sed '1 s/^/#lane\ttile\tX\tY\tgene_id\tgene\tgn\tgt\tspl\tunspl\tambig\n/' | \
            bgzip -c > {output.sdgeAR_transcript}

        tabix -0 -f -s1 {tabix_column} {output.sdgeAR_transcript}
        """
        )

        ## old code:
        #
        # kept_gene_type=$(echo "{params.kept_gene_type}" | sed 's/,/\|/')
        # rm_gene_regex=$(echo "{params.rm_gene_regex}" | sed 's/\^/\\t/g')
        #echo -e "gene_id\tgene\tgn\tgt\tspl\tunspl\tambig" > {sdgeAR_ftr_tabqc_unzip}
        # awk 'BEGIN{{FS=OFS="\t"}} NR==FNR{{ft[$1]=$1; next}} ($1 in ft && $4 + 0 > {params.min_ct_per_feature}){{print $0}}' \
        #     <(zcat {geneinfo} | grep -P "${{kept_gene_type}}" | cut -f 4 ) \
        #     <(zcat {output.sdgeAR_ftr_tab})| \
        #     grep -vP "${{rm_gene_regex}}" >> {sdgeAR_ftr_tabqc_unzip}
        # gzip -f {sdgeAR_ftr_tabqc_unzip}
