#==============================================
#
# 03. convert in situ transcript file to sdge (per ln)
#
#
#==============================================

# 2. ${tra_gidsort_f}
        #   - header: 'sbcd_idx', 'lane', 'tile', 'x', 'y', 'gene_id', 'gene', 'sbcd'
        #   - idx; sort by: x, y 

# 3. ${ftr_f}:
        #   - header: 'gene_id', 'gene', 'gene_idx', 'cnts_gene,genefull,spl,unspl,ambi'
        #   - idx; sort by: genesymbol (due to the cases missing gene_id)

# 4. ${bcd_f}:
        #   - header: 'sbcd', 'sbcd_idx', 'sbcd_idx_STARsolo', 'lane', 'tile', 'x', 'y', 'cnts_gene,genefull,spl,unspl,ambi'
        #   - idx; sort by: x, y 
# 5. ${mtx_f}:
        #   - header: 'gene_idx', 'sbcd_idx', 'gene_cnt', 'genefull_cnt', 'spliced_cnt', 'unspliced_cnt', 'ambiguous_cnt'
        #   - merge sbcd_idx by sbcd and gene_idx by gene(genesymbol)
        #   - skip sort (1) by bcd_idx bcuz tra_gidsort_f has been sorted by x,y; awk print out by tra_gidsort_f
        #               (2) by gene_idx bcuz each sbcd should have only 1 gene.

rule insitu2sdgeLN:
    input:
        transcripts = os.path.join(raw_root, "{fc}_transcripts.csv.gz")
    output:
        sdgeLN_bcd   = os.path.join(sdgeFC_root, "{fc}", "{sp}", "{ln}", "barcodes.tsv.gz"),
        sdgeLN_ftr   = os.path.join(sdgeFC_root, "{fc}", "{sp}", "{ln}", "feature.tsv.gz"),
        sdgeLN_mtx   = os.path.join(sdgeFC_root, "{fc}", "{sp}", "{ln}", "matrix.mtx.gz"),
    params:
        add_geneid       = os.path.join(config["insitu2sdge"],"add_geneid.py"),
        fc = "{fc}"
        #xenium_qv        = config["insitu2sdgeLN"]["qv"],
    resources:
        mem  = "7000MB",
        time = "10:00:00",
    threads: 1
    run:
        input_prefix=input.transcripts.replace("_transcripts.csv.gz","")
        gp_json = input.transcripts.replace("_transcripts.csv.gz","_genepanel.json")
        gene_info = os.path.join(tmp_root, "ref_geneinfo", params.fc.lower().split("_")[0]),
        shell(
        r""" 
        source {py310_env}/bin/activate

        if [[ {platform} == "merscope" ]] || [[ {platform} == "vizgen" ]]; then
            IFS=' ' read -r xmin xmax ymin ymax <<< $(zcat {input.transcripts} | cut -d ',' -f 3,4| tail -n +2 | awk -F ',' 'NR == 1 {{ xmin = $1; xmax = $1; ymin = $2; ymax = $2 }} {{
                if ($1 > xmax) {{ xmax = $1 }}
                if ($1 < xmin) {{ xmin = $1 }}
                if ($2 > ymax) {{ ymax = $2 }}
                if ($2 < ymin) {{ ymin = $2 }}
                }} END {{ print xmin, xmax, ymin, ymax }}')
            echo -e "xmin\t${{xmin}}\nxmax\t${{xmax}}\nymin\t${{ymin}}\nymax\t${{ymax}}" > {output.XYlim}
            python {params.add_geneid} --platform merscope --transcripts {input.transcripts} --ref_geneid {gene_info} --xylim {output.XYlim} --output {output.tra_gid_f}
        elif [[ {platform} == "xenium" ]] || [[ {platform} == "10x" ]]; then
            IFS=' ' read -r xmin xmax ymin ymax <<< $(zcat {input.transcripts} | cut -d ',' -f 5,6| tail -n +2 | awk -F ',' 'NR == 1 {{ xmin = $1; xmax = $1; ymin = $2; ymax = $2 }} {{
                if ($1 > xmax) {{ xmax = $1 }}
                if ($1 < xmin) {{ xmin = $1 }}
                if ($2 > ymax) {{ ymax = $2 }}
                if ($2 < ymin) {{ ymin = $2 }}
                }} END {{ print xmin, xmax, ymin, ymax }}')
            echo -e "xmin\t${{xmin}}\nxmax\t${{xmax}}\nymin\t${{ymin}}\nymax\t${{ymax}}" > {output.XYlim}
            python {params.add_geneid} --platform xenium --transcripts {input.transcripts} --gene_panel {gp_json} --xylim {output.XYlim} --output {output.tra_gid_f}
        fi

        zcat {input.tra_gid_f}| sort -S 6G -k3,3n -k4,4n | awk '{{print NR"\t"$0}}' |gzip -c > {output.tra_gidsort_f}
        echo -e  "tra_gidsort_f ready\n"

        zcat {output.tra_gidsort_f}| awk 'BEGIN{{FS=OFS="\t"}}{{print $8,$1,$1,$2,$3,$4,$5,"1,0,0,0,0"}}' | gzip -c > {output.sdgeLN_bcd}
        echo -e  "bcd_f ready\n"

        zcat {output.tra_gidsort_f}| awk -F '\t' '{{print $6"\t"$7}}'| sort -S 6G --key=2 | uniq -c | awk -F ' ' '{{print $2"\t"$3"\t"NR"\t"$1",0,0,0,0"}}' |gzip -c > {output.sdgeLN_ftr}
        echo -e  "ftr_f ready\n"


        N_ftr=$(zcat {input.sdgeLN_ftr}|wc -l)
        N_bcd=$(zcat {input.sdgeLN_bcd}|wc -l)
        awk 'BEGIN{{FS="\t"}}NR==FNR{{ft[$1]=$2; next}} ($7 in ft) {{print ft[$7]" "$1" 1 0 0 0 0"}}' <(zcat {input.sdgeLN_ftr} | cut -f 2,3 )  <(zcat {input.tra_gidsort_f}) |\
            awk -v N_ftr="$N_ftr" -v N_bcd="$N_bcd" -v N_mtx="$N_bcd" 'BEGIN{{print "%%MatrixMarket matrix coordinate integer general\n%\n"N_ftr" "N_bcd" "N_mtx}}{{print}}' |\
            gzip -c > {output.sdgeLN_mtx}
        echo -e "mtx_f ready!\n"
        """
        )
