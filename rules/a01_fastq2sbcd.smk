rule a01_fastq2sbcd:
    input:
        seq1_fq     = os.path.join(main_dirs["seq1st"], "{flowcell}", "fastqs", "{seq1_id}" + ".fastq.gz" ),
    output:
        sbcd_mnfst  = os.path.join(main_dirs["seq1st"], "{flowcell}", "sbcds", "{seq1_id}", "manifest.tsv"),
    params:
        sbcd_format = config.get("upstream", {}).get("fastq2sbcd", {}).get('format', "DraI32"),  
        # module
        module_cmd  = get_envmodules_for_rule(["python"], config.get("env",{}).get("envmodules", {})),
        spatula     = config.get("env",{}).get("tools", {}).get("spatula", "spatula"),
        pyenv       = config.get("env",{}).get("pyenv", None),
    resources:
        time = "50:00:00",
        mem  = "70g",
    run:
        python      = get_python(params.pyenv)
        sbcd_dir    = os.path.dirname(output.sbcd_mnfst)
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        source {params.pyenv}/bin/activate
                
        command time -v {python} {novascope_scripts}/rule_a01.build-spatial-barcode-dict.py \
            --spatula {params.spatula} \
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
