rule a01_fastq2sbcd:
    input:
        seq1_fq    = os.path.join(main_dirs["seq1st"], "{flowcell}", "fastqs", "{seq1_prefix}"+ ".fastq.gz" ),
    output:
        sbcd_dir   = directory(os.path.join(main_dirs["seq1st"], "{flowcell}", "sbcds", "{seq1_prefix}")),
        sbcd_mnfst = os.path.join(main_dirs["seq1st"], "{flowcell}", "sbcds", "{seq1_prefix}", "manifest.tsv"),
    params:
        sbcd_format = config.get("preprocess", {}).get("fastq2sbcd", {}).get('format', "DraI32"),  #? format=${3:Gen32}
    resources:
        time = "50:00:00",
        mem  = "6500m"
    run:
        shell(
        """
        source {py39_env}/bin/activate
                
        command time -v {py39} {sttools2}/scripts/build-spatial-barcode-dict.py \
            --spatula {spatula} \
            --fq {input.seq1_fq} \
            --format {params.sbcd_format} \
            --out {output.sbcd_dir} 
        """
        )
