#==============================================
#
# 04. from sdgeLN to sdgeAR (per ar, i.e., uid)
#
#   * 
#
#==============================================

rule postsdgeLN2AR:
    input:
        sdgeFC_dir = lambda wildcards: [os.path.join(sdgeFC_root, iid[0], iid[1]) for iid in uid2iid[wildcards.uid]],
        sbcd_mnfst = lambda wildcards: list(set(os.path.join(sbcd_root, iid[0], "manifest.tsv") for iid in uid2iid[wildcards.uid])),
    output:
        sdgeAR_ftr       = os.path.join(sdgeAR_root, "{uid}", "features.tsv.gz"),
        sdgeAR_bcd       = os.path.join(sdgeAR_root, "{uid}", "barcodes.tsv.gz"),
        sdgeAR_mtx       = os.path.join(sdgeAR_root, "{uid}", "matrix.mtx.gz"),
        sdgeAR_layout_fig= os.path.join(sdgeAR_root, "{uid}", "{uid}.layout.velo.png"),
        sdgeAR_hillsd_fig= os.path.join(sdgeAR_root, "{uid}", "{uid}.hillshade.tif"),
    params:
        uid              = "{uid}",
        species          = lambda wildcards: uid2sp[wildcards.uid],
        seqplf           = lambda wildcards: uid2seqplf[wildcards.uid],
        untp             = lambda wildcards: uid2untp[wildcards.uid],
#        bdtp             = lambda wildcards: uid2bdtp[wildcards.uid],
        sdgeAR_lo        = lambda wildcards: uid2lo[wildcards.uid],
        sdgeLN_dir       = lambda wildcards: [os.path.join(sdgeFC_root, iid[0], iid[1], iid[2]) for iid in uid2iid[wildcards.uid]], #fc:sp:ln:
        sdgeLN_lo_path   = config["layout"]["path"],
        sdgeLN_lo_opt    = config.get("layout", {}).get("opt", {}).get("postsdgeLN2AR", "full"),
        lofig_maxscl     = config["postsdge"]["LN2AR"]["lofig_maxscale"],
        lofig_res        = config["postsdge"]["LN2AR"]["lofig_res"],
        gbd              = lambda wildcards: uid2gbd[wildcards.uid],
    threads: 2
    resources:
        mem  = "14000MB",
        time = "24:00:00", 
    run:
        sdgeAR_dir=os.path.dirname(output.sdgeAR_ftr)
        seqplf = params.seqplf.lower()
        # Get the layout file
        sdgeLN_lo_opt = params.sdgeLN_lo_opt.lower()
        if sdgeLN_lo_opt == "full" or sdgeLN_lo_opt is None:
            sdgeLN_layout = os.path.join(params.sdgeLN_lo_path, seqplf + ".layout.tsv")
        else:
            sdgeLN_layout = os.path.join(params.sdgeLN_lo_path, seqplf + "_" + sdgeLN_lo_opt + ".layout.tsv")
        # Get the custom opt:
        custom_unit =params.untp.lower()
        # get the sdgeLN from layout file
        sdgeLN_list = []
        with open(params.sdgeAR_lo, "r") as infile:
            for line in infile:
                if line.startswith("#"):
                    continue 
                sdgeLN_i = ":".join(line.strip().split())
                sdgeLN_list.append(sdgeLN_i)

        sdgeLN_subsets = '\"'+' '.join(sdgeLN_list)+'\"'

        shell(
        r"""
        module load Bioinformatics
        module load samtools
        module load python/3.9.12
        source {py39_env}/bin/activate

        mkdir -p {sdgeAR_dir}
        ## sanity check - 1a
        sdgeLN_items=()
        IFS=" " read -ra sdgeLN_items <<< {sdgeLN_subsets}
        sdgeLN_N=${{#sdgeLN_items[@]}}
        if   [[ "{custom_unit}" == "single-unit" && $sdgeLN_N -ne 1 ]]; then
            echo "==>Error: The InputUnit and FilterInfo in the analysis.index do not match."
            exit 1
        elif [[ "{custom_unit}" == "multi-unit" && $sdgeLN_N -eq 1 ]]; then
            echo "==>Error: The InputUnit and FilterInfo in the analysis.index do not match."
            exit 1
        fi


        ## 1. generate a global sge
        auxparams=""
        echo "==> Step1. Generate a global sDGE"
        echo "==> The input unit type is: {custom_unit} "

        if [[ "{custom_unit}" == "single-unit" ]]; then
            # if single-unit, then only 1 sdgeLN_i in sdgeLN_items
            sdgeLN_i="${{sdgeLN_items[0]}}"
            IFS=":" read -r fc_i ln_i bdtp_i fi_i row_i col_i <<< "$sdgeLN_i"
            sp_i={params.species}
            if [[ "$bdtp_i" != "default" && "$bdtp_i" != "tile-range" &&  "$bdtp_i" != "tile-single" &&  "$bdtp_i" != "boundary-local" && "$bdtp_i" != "boundary-global" && "$bdtp_i" != "rectangle-local" && "$bdtp_i" != "rectangle-global" ]]; then
                echo "==> Error: The border type in the layout file is invalid."
                exit 1
            fi

            echo "==> Processing input unit $sdgeLN_i"
            echo "==>       Border-type: $bdtp_i "
            echo "==>       Filter-info: $fi_i"
            echo "==>       Position-info: $row_i, $col_i"

            input_sgedir="{params.sdgeLN_dir}"
            input_manifest="{input.sbcd_mnfst}"
            input_layout="{sdgeLN_layout}"

            # if default; skip add filtering input
            if [[ "$bdtp_i" == "boundary-global" ]]; then
                if [[ "{params.gbd}" == "-" || ! -f "{params.gbd}" ]]; then
                    echo "==> Error: The current global boundary file {params.gbd} is invalid."
                    exit 1
                fi
                auxparams=" --boundary {params.gbd}" 
            elif [[ "$bdtp_i" == "boundary-local" ]]; then
                if [[ "$fi_i" == "-" || ! -f "$fi_i" ]]; then
                    echo "==> Error: The current local boundary file $fi_i is invalid."
                    exit 1
                fi
                auxparams=" --boundary $fi_i" 
            elif [[ "$bdtp_i" == "tile-range" ]]; then
                input_sgedir="{sdgeAR_root}/{params.uid}/rawdat/1"
                input_manifest="{sdgeAR_root}/{params.uid}/rawdat/manifest.tsv"
                input_layout="{sdgeAR_root}/{params.uid}/rawdat/layout.tsv"

                mkdir -p $input_sgedir

                command time -v {py39} {local_scripts}/create_single_lane.py \
                    --single-unit \
                    --sgeAR_layout {params.sdgeAR_lo} \
                    --species {params.species}\
                    --sgeLN_layout {sdgeLN_layout}\
                    --sgeFC_root {sdgeFC_root}\
                    --sbcd_root {sbcd_root} \
                    --output_dir {sdgeAR_root}/{params.uid}/rawdat 
            fi
        elif [[ "{custom_unit}" == "multi-unit" ]]; then
            # if multi-unit: the border type may be different. Therefore, loop the input unit and process them individually.
            input_sgedir="{sdgeAR_root}/{params.uid}/rawdat/1"
            input_manifest="{sdgeAR_root}/{params.uid}/rawdat/manifest.tsv"
            input_layout="{sdgeAR_root}/{params.uid}/rawdat/layout.tsv"

            mkdir -p $input_sgedir

            echo -e "lane\ttile\trow\tcol" > $input_layout
            echo -e "id\txmin\txmax\tymin\tymax" > $input_manifest

            tile_i=1100
            # convert each input unit, usually this should be all input regions within a lane, to a tile tile_i:
            for sdgeLN_i in "${{sdgeLN_items[@]}}"; do
                tile_i=$((tile_i+1))
                IFS=":" read -r fc_i ln_i bdtp_i fi_i row_i col_i <<< "$sdgeLN_i"
                sp_i={params.species}

                input_sgedir_i="{sdgeFC_root}/$fc_i/$sp_i/$ln_i"
                input_manifest_i="{sbcd_root}/$fc_i/manifest.tsv"
                input_sdgeLN_lo_i="{sdgeLN_layout}"
                input_auxparams_i=""

                echo "==> Processing input unit $sdgeLN_i into tile: $tile_i"
                echo "==>       Border-type: $bdtp_i "
                echo "==>       Filter-info: $fi_i"
                echo "==>       Position-info: $row_i, $col_i"

                # if default; skip add filtering input
                if [[ "$bdtp_i" == "boundary-global" ]]; then 
                    echo "==>       Add boundary: {params.gbd}"
                    if [[ "{params.gbd}" == "-" || ! -f "{params.gbd}" ]]; then
                        echo "==> Error: The current global boundary file {params.gbd} is invalid."
                        exit 1
                    fi
                    auxparams=" --boundary {params.gbd}" 
                elif [[  "$bdtp_i" == "boundary-local" ]]; then
                    if [[ "$fi_i" == "-" || ! -f "$fi_i" ]]; then
                        echo "==> Error: The current local boundary file $fi_i is invalid."
                        exit 1
                    fi
                    input_auxparams_i=" --boundary $fi_i" 
                elif [[ "$bdtp_i" == "tile-range" ]]; then
                    input_sgedir_i="{sdgeAR_root}/{params.uid}/rawdat/temp/${{fc_i}}_${{sp_i}}_${{ln_i}}/1"
                    input_sgedir_dirname_i="{sdgeAR_root}/{params.uid}/rawdat/temp/${{fc_i}}_${{sp_i}}_${{ln_i}}"
                    input_manifest_i="{sdgeAR_root}/{params.uid}/rawdat/temp/${{fc_i}}_${{sp_i}}_${{ln_i}}/manifest.tsv"
                    input_lo_i="{sdgeAR_root}/{params.uid}/rawdat/temp/${{fc_i}}_${{sp_i}}_${{ln_i}}/layout.tsv"

                    mkdir -p $input_sgedir_i

                    echo "==>       Tile filtering"
                    echo "==>           command time -v {py39} {local_scripts}/create_single_lane.py --single-unit --species {params.species} --sgeLN_subsets $sdgeLN_i --sgeLN_layout {sdgeLN_layout} --sgeFC_root {sdgeFC_root} --sbcd_root {sbcd_root} --output_dir $input_sgedir_dirname_i"

                    # create a new dir including only the tiles within the range
                    command time -v {py39} {local_scripts}/create_single_lane.py \
                        --single-unit \
                        --species {params.species}\
                        --sgeLN_subsets "${{fc_i}}:${{sp_i}}:${{ln_i}}:${{bdtp_i}}:${{fi_i}}"\
                        --sgeLN_layout {sdgeLN_layout}\
                        --sgeFC_root {sdgeFC_root}\
                        --sbcd_root {sbcd_root} \
                        --output_dir $input_sgedir_dirname_i

                    input_sdgeLN_lo_i=$input_lo_i
                fi
                echo "==>       Convert a lane to a tile"
                echo "==>           command time -v {py39} {sttools2}/scripts/tile-to-global-sge.py --sge $input_sgedir_i --manifest $input_manifest_i --layout {sdgeLN_layout} --single-lane  --out {sdgeAR_root}/{params.uid}/rawdat/1/$tile_i --out-minmax-fixed --spatula {spatula} $input_auxparams_i"
                command time -v {py39} {sttools2}/scripts/tile-to-global-sge.py \
                    --sge $input_sgedir_i \
                    --manifest $input_manifest_i \
                    --layout  $input_sdgeLN_lo_i\
                    --single-lane \
                    --out {sdgeAR_root}/{params.uid}/rawdat/1/$tile_i \
                    --out-minmax-fixed \
                    --spatula {spatula} $input_auxparams_i

                # get the corresponding pos in layout file
                echo -e "1\t$tile_i\t$row_i\t$col_i" >> $input_layout
                awk -v tile_i="$tile_i" 'NR>1 {{print "1_"tile_i"\t"$0}}' {sdgeAR_root}/{params.uid}/rawdat/1/$tile_i/barcodes.minmax.tsv >> $input_manifest
            done
        fi

        echo "==> Step2. Create a sDGE for the task"
        echo "==>               command time -v {py39} {sttools2}/scripts/tile-to-global-sge.py --sge $input_sgedir --manifest $input_manifest --layout $input_layout --single-lane --out {sdgeAR_dir} --out-minmax-fixed --spatula {spatula} $auxparams"
        command time -v {py39} {sttools2}/scripts/tile-to-global-sge.py \
            --sge $input_sgedir \
            --manifest $input_manifest\
            --layout $input_layout\
            --single-lane\
            --out {sdgeAR_dir}\
            --out-minmax-fixed \
            --spatula {spatula} $auxparams

        echo "==> Step3. Create the layout figure"
        echo "==>               command time -v {py39} {sttools2}/scripts/rgb-gene-image-AR.py --sge {sdgeAR_dir} --out {output.sdgeAR_layout_fig} -r _all:1:2 -g _all:1:3 -b _all:1:4 --max-scale {params.lofig_maxscl} --res {params.lofig_res} "
        command time -v {py39} {sttools2}/scripts/rgb-gene-image-AR.py \
            --sge {sdgeAR_dir} \
            --out {output.sdgeAR_layout_fig}\
            -r _all:1:2 -g _all:1:3 -b _all:1:4 --max-scale {params.lofig_maxscl} --res {params.lofig_res} 

        echo "==> Step4. Create a hillshade figure"
        echo "==>               {cart}/script/hillshade.sh {output.sdgeAR_bcd} {output.sdgeAR_hillsd_fig} "
        {cart}/script/hillshade.sh {output.sdgeAR_bcd} {output.sdgeAR_hillsd_fig}
        """
        )


