rule a01_fastq2sbcd:
    input:
        seq1_fq    = os.path.join(main_dirs["seq1st"], "{flowcell}", "fastqs", "{seq1_prefix}"+ ".fastq.gz" ),
    output:
        sbcd_mnfst = os.path.join(main_dirs["seq1st"], "{flowcell}", "sbcds", "{seq1_prefix}", "manifest.tsv"),
    params:
        sbcd_format = config.get("preprocess", {}).get("fastq2sbcd", {}).get('format', "DraI32"),  
        # module
        module_cmd        = get_envmodules_for_rule(["python"], module_config)
    resources:
        time = "50:00:00",
        mem  = "70g",
    run:
        sbcd_dir         = os.path.dirname(output.sbcd_mnfst)
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        source {py39_env}/bin/activate
                
        command time -v {py39} {local_scripts}/rule_a1.build-spatial-barcode-dict.py \
            --spatula {spatula} \
            --fq {input.seq1_fq} \
            --format {params.sbcd_format} \
            --out {sbcd_dir} \
            --skip-sort

        tail -n +2 {output.sbcd_mnfst} | cut -f 1 | xargs -I {{}} -P 20 bash -c ' \
            sort -S 2G {sbcd_dir}/{{}}.sbcds.unsorted.tsv | gzip -c > {sbcd_dir}/{{}}.sbcds.sorted.tsv.gz; \
            rm {sbcd_dir}/{{}}.sbcds.unsorted.tsv \
        '

        """
        )
