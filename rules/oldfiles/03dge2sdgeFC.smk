#==============================================
#
# 03. convert dge to sdge, and draw a layout figure (per fc/ln)
#
#   * mem test log: 
#       - If mem=6500MB, HD22 human-mouse was killed due to out-of-memory. 10G works for HD22.
#       - If mem=20000MB, HD42 got killed due to out-of-memory at the step to draw the fig. 
#   * The hillshade figure will be created for each lane & species as a sgeAR.
#
#   TODO: revise the resource assignment according to dge size!
#==============================================

rule dge2sdgeFC:
    input:
        dgeFC_dir  = os.path.join(dgeFC_root, "{fc}", "{sp}"),
        smatch_csv = lambda wildcards: [os.path.join(smatch_root, wildcards.fc, seq2_id + ".match.sorted.uniq.tsv.gz") for seq2_id in fc2seq2[wildcards.fc]],
    output:
        sdgeFC_dir = directory(os.path.join(sdgeFC_root, "{fc}", "{sp}")),
        sdgeFC_fig = os.path.join(sdgeFC_root, "{fc}", "{sp}","layout.velo.png"),
    params:
        sdgeFC_lofig_maxscl = config["dge2sdgeFC"]["lofig_maxscale"],
        sdgeFC_lofig_res    = config["dge2sdgeFC"]["lofig_res"],
        lo_path             = config["layout"]["path"],
        lo_opt              = config.get("layout", {}).get("opt", {}).get("dge2sdgeFC", "righthalf"),
        seqplf              = lambda wildcards: fc2seqplf[wildcards.fc],
    resources:
        mem  = "24000MB", 
        time = "3:00:00"  # It took 15min for HD22. <2h for HD42
    run:
        # Generate smatch_csvjoin
        smatch_csvjoin = " --match ".join(expand(input.smatch_csv))
        sdgeFC_figpref = output.sdgeFC_fig.rstrip(".png")
        seqplf = params.seqplf.lower()
        # Get the layout file
        lo_opt = params.lo_opt.lower()
        if lo_opt == "full" or lo_opt is None:
            layout = os.path.join(params.lo_path, seqplf + ".layout.tsv")
        else:
            layout = os.path.join(params.lo_path, seqplf + "_" + lo_opt + ".layout.tsv")

        shell(
        """
        source {py310_env}/bin/activate

        {spatula} dge2sdge \
            --bcd {input.dgeFC_dir}/sttoolsSolo.out/GeneFull/raw/barcodes.tsv.gz \
            --ftr {input.dgeFC_dir}/sttoolsSolo.out/GeneFull/raw/features.tsv.gz \
            --mtx {input.dgeFC_dir}/sttoolsSolo.out/Gene/raw/matrix.mtx.gz \
            --mtx {input.dgeFC_dir}/sttoolsSolo.out/GeneFull/raw/matrix.mtx.gz \
            --mtx {input.dgeFC_dir}/sttoolsSolo.out/Velocyto/raw/spliced.mtx.gz \
            --mtx {input.dgeFC_dir}/sttoolsSolo.out/Velocyto/raw/unspliced.mtx.gz \
            --mtx {input.dgeFC_dir}/sttoolsSolo.out/Velocyto/raw/ambiguous.mtx.gz \
            --out {output.sdgeFC_dir}/ \
            --match {smatch_csvjoin}

        command time -v {py310} {sttools2}/scripts/update-features-with-zeros.py {output.sdgeFC_dir}

        command time -v {py310} {sttools2}/scripts/rgb-gene-image.py \
            --layout {layout} \
            --out {sdgeFC_figpref} -r _all:1:2 -g _all:1:3 -b _all:1:4 \
            --sdge {output.sdgeFC_dir} \
            --max-scale {params.sdgeFC_lofig_maxscl} \
            --res {params.sdgeFC_lofig_res}
        """
        )


