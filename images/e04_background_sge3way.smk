rule e04_background_sge3way:
    input:
        bucket_flag       = os.path.join(main_dirs["cart"], "{unit_id}", "{cdate}", "flag", "e01_s3_bucket.flag"),
        sdge_3way_png     = os.path.join(main_dirs["align"], flowcell, chip, run_id, "sge", run_id+".sge_match_sbcd.png"),
    output:
        bg_3way_tif       = os.path.join(main_dirs["cart"], "{unit_id}", "{cdate}", "background", "{unit_id_bg}"+"_sge_match_sbcd.tif"),
        bg_sge3way_flag   = os.path.join(main_dirs["cart"], "{unit_id}", "{cdate}", "flag", "e04_background_sge3way_{unit_id_bg}.flag"),
    params:
        # s3
        aws_bkgd_dir      = f"s3://{unit_id}/asset-{cdate}/background",
        # module
        module_cmd        = get_envmodules_for_rule(["aws-cli", "gcc", "gdal", "singularity", "python"], module_config)
    run:
        shell(
        r"""
        set -e 
        {params.module_cmd}
        source {pyenv}/bin/activate

        # rotate 90-dgree
        gdalwarp {input.sdge_3way_png} {output.bg_3way_tif} \
        -to SRC_METHOD=NO_GEOTRANSFORM  \
        -ct "+proj=pipeline +step +proj=axisswap +order=2,1" \
        -overwrite

        # upload to s3
        aws s3 cp {output.bg_3way_tif} \
        {aws_sqs_dir}/sge_match_sbcd.tif \
        --profile default

        # Once done, create the flag file
        current_datetime=$(date "+%Y-%m-%d %H:%M:%S")
        {{
            echo "Date and Time: ${{current_datetime}}"
            echo "The uploaded sge figure: {output.bg_3way_tif}"
        }} >> {output.bg_sge3way_flag}
        """
        )

