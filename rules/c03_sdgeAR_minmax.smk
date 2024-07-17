rule c03_sdgeAR_minmax:
    input:
        transcript       = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz"),
        transcript_tbi   = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz.tbi"),
    output:
        xyrange_raw      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.raw.coordinate_minmax.tsv"),
    params:
        # module
        module_cmd       = get_envmodules_for_rule(["python", "samtools"], module_config),
    run:
        shell(
        r"""
        {params.module_cmd}
        source {pyenv}/bin/activate

        gzip -cd {input.transcript} | \
            awk 'BEGIN{{FS=OFS="\t"}} NR==1{{for(i=1;i<=NF;i++){{if($i=="X")x=i;if($i=="Y")y=i}}print $x,$y;next}}{{print $x,$y}}' | \
            perl -slane 'print join("\t",$F[0]/{mu_scale},$F[1]/{mu_scale})' -- -mu_scale="{mu_scale}" | \
            awk 'BEGIN {{FS=OFS="\t"; min1 = "undef"; max1 = "undef"; min2 = "undef"; max2 = "undef";}} {{if (NR == 2 || $1 < min1) min1 = $1; if (NR == 2 || $1 > max1) max1 = $1; if (NR == 2 || $2 < min2) min2 = $2; if (NR == 2 || $2 > max2) max2 = $2;}} END {{print "xmin", min1; print "xmax", max1; print "ymin", min2; print "ymax", max2;}}' > {output.xyrange_raw}
        """
        )