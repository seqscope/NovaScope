rule b02_historef:
    input:
        sdge_3in1_png     = os.path.join(main_dirs["align"],      "{flowcell}", "{chip}", "{run_id}", "sge", "{run_id}.sge_match_sbcd.png"),
        hist_raw          = os.path.join(main_dirs["histology"],  "{flowcell}", "{chip}", "raw", "{hist_std_prefix}.tif"),
    output:
        hist_aligned      = os.path.join(main_dirs["histology"],  "{flowcell}", "{chip}", "aligned", "{run_id}", "{hist_std_prefix}.tif"),
        hist_fit          = os.path.join(main_dirs["histology"],  "{flowcell}", "{chip}", "aligned", "{run_id}", "{hist_std_prefix}-fit.tif"),
    params:
        # params
        hist_buffer_start   = config.get("histology",{}).get("min_buffer_size", 1000),
        hist_buffer_end     = config.get("histology",{}).get("max_buffer_size", None),
        hist_buffer_step    = config.get("histology",{}).get("buffer_step", 100),
        hist_raster_channel = config.get("histology",{}).get("raster_channel", 1),
        # tools
        module_cmd          = get_envmodules_for_rule(["python", "gcc", "gdal"], config.get("env",{}).get("envmodules", {}))
    threads: 3
    resources:
        time = "5:00:00",
        mem  = "20000m",
    run:
        if params.hist_buffer_end is None:
            params.hist_buffer_end = params.hist_buffer_start + 1000
        buffer_sizes = " ".join(str(i) for i in range(params.hist_buffer_start, params.hist_buffer_end, params.hist_buffer_step))
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        source {pyenv}/bin/activate
    
        echo "Params:"
        echo " - Buffer size: {params.hist_buffer_start} to {params.hist_buffer_end} with step {params.hist_buffer_step}..."
        echo " - Raster channel: {params.hist_raster_channel}"
        
        # 1) align histology
        # use a loop to find the right buffer size
        echo "Start aligning the input histology file ..."
        success=false
        # now pass the buffer sizes from 
        buffer_sizes=({buffer_sizes})
        for buffer in "${{buffer_sizes[@]}}"; do
            echo " - Buffer size: $buffer"            
            # Run your Python module with the current buffer size
            if command time -v {python} -m historef.referencer --nge {input.sdge_3in1_png} --hne {input.hist_raw} --aligned {output.hist_aligned} --buffer $buffer --nge_raster_channel {params.hist_raster_channel} ; then
                echo "      - Success with buffer size: $buffer ..."
                success=true
                break
            else
                echo "      - Failed with buffer size: $buffer ..."
            fi
        done

        if ! $success ; then
            echo "Histology file alignment failed with buffer sizes from {params.hist_buffer_start} to {params.hist_buffer_end} with step {params.hist_buffer_step}."
            echo "Try to change the buffer size parameters in the config file or align the histology file manually..."
            exit 1
        else
            echo "Buffer size optimization successful."
        fi

        # fit histology
        INFO=$(gdalinfo "{input.sdge_3in1_png}" 2>&1)

        if [[ $INFO =~ Size\ is\ ([0-9]+),\ ([0-9]+) ]]; then
            WIDTH=${{BASH_REMATCH[1]}}
            HEIGHT=${{BASH_REMATCH[2]}}
            echo "Extracted dimensions: WIDTH=${{WIDTH}}, HEIGHT=${{HEIGHT}}"
        else
            echo "Failed to extract image dimensions."
            exit 1
        fi

        gdalwarp \
        "{output.hist_aligned}" "{output.hist_fit}" -ct "+proj=pipeline +step +proj=axisswap +order=2,-1" \
        -overwrite \
        -te 0 -$HEIGHT $WIDTH 0 -ts $WIDTH $HEIGHT

        echo "gdalwarp command executed with dimensions: width=${{WIDTH}}, height=${{HEIGHT}}"
        """
        )


