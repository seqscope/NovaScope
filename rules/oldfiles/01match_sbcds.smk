#==============================================
#
# 01. smatch (per seq2_id per fc)
#
#   * seq2_id = fastq + dir, as the new libname
#   * ask snakemake to detect all seq2_ids for a fc and process each separately.
#
#==============================================
rule match_sbcds:
    input:
        sbcd_dir      = os.path.join(sbcd_root, "{fc}"),
        sbcd_manifest = os.path.join(sbcd_root, "{fc}", "manifest.tsv"),
        seq2_fqr1     = os.path.join(tmp_root, "seq2", "{fc}","{seq2_id}" + "_1.fastq.gz"),
        #seq2_fqr1   = lambda wildcards: glob( os.path.join(tmp_root, "seq2", wildcards.fc, wildcards.seq2_id + "_1.fastq.gz")),
    output:
        smatch_csv     = os.path.join(smatch_root, "{fc}", "{seq2_id}" + ".match.sorted.uniq.tsv.gz"),
        smatch_count   = os.path.join(smatch_root, "{fc}", "{seq2_id}" + ".counts.tsv"),
        smatch_summary = os.path.join(smatch_root, "{fc}", "{seq2_id}" + ".summary.tsv"),
        smatch_fig     = os.path.join(smatch_root, "{fc}", "{seq2_id}" + ".match.png"),
    params:
        smatch_dir  = directory(os.path.join(smatch_root, "{fc}")),
        smatch_name = os.path.join(smatch_root, "{fc}", "{seq2_id}"),
        seqplf      = lambda wildcards: fc2seqplf[wildcards.fc],
        lo_path     = config["layout"]["path"],
        lo_opt      = config.get("layout", {}).get("opt", {}).get("match_sbcds", "full")
    resources: 
        time = "5:00:00" # <20min for HD22, ~2h for HD42 
    run:
        lo_opt = params.lo_opt.lower()
        seqplf = params.seqplf.lower()
        if lo_opt == "full" or lo_opt is None:
            layout = os.path.join(params.lo_path, seqplf+ ".layout.tsv")
        else:
            layout = os.path.join(params.lo_path, seqplf  + "_" + lo_opt + ".layout.tsv")

        shell(
        """
        source {py310_env}/bin/activate

        mkdir -p {params.smatch_dir}

        {spatula} match-sbcds \
            --fq {input.seq2_fqr1} \
            --sbcd {input.sbcd_dir} \
            --out {params.smatch_name} 

        command time -v {py310} {sttools2}/scripts/mono-match-image.py \
            -m {output.smatch_csv} \
            -l {layout}\
            -o {output.smatch_fig} 
        """
        )

