rule a02_sbcd2nbcd:
    input:
        sbcd_mnfst       = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds", sc2seq1[wildcards.section], "manifest.tsv"),
    output:
        nbcd_tsv         = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_mnfst       = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "manifest.tsv"),
        nbcd_png         = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.png"),
    params:
        # general params
        section          = lambda wildcards: wildcards.section,
        # sbcd.part
        input_sbcd_part_layout    = check_path(config.get('input', {}).get('seq1st', {}).get('sbcd_layout', None), job_dir, strict_mode=False),
        input_sbcd_layout_summary = check_path(config.get("input", {}).get("seq1st", {}).get('sbcd_layout_summary',None),job_dir, strict_mode=False),
        sbcd_part_layout          = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds.part", sc2seq1[wildcards.section], wildcards.section, wildcards.section+".layout.tsv"),
        sbcd_part_mnfst           = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds.part", sc2seq1[wildcards.section], wildcards.section, "manifest.tsv"),
        # combine 
        gap_row             = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('gap_row', 0.0517),
        gap_col             = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('gap_col', 0.0048),
        dup_maxnum          = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('dup_maxnum', 1),
        dup_maxdist         = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('dup_maxdist', 1),
        # visualization
        visual_coord_per_pixel    = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("coord_per_pixel", 1000),
        visual_intensity_per_obs  = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("intensity_per_obs", 50),
        visual_icol_x             = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("icol_x", 3),
        visual_icol_y             = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("icol_y", 4),
    resources:
        time = "5:00:00",
        mem  = "6500m"
    run:
        sbcd_dir         = os.path.dirname(input.sbcd_mnfst)
        nbcd_dir         = os.path.dirname(output.nbcd_tsv)
        sbcd_part_dir    = os.path.dirname(params.sbcd_part_layout)

        os.makedirs(sbcd_part_dir, exist_ok=True)

        # s1a
        if params.input_sbcd_part_layout is not None:
            assert os.path.exists(params.input_sbcd_part_layout), f"Provided sbcd layout file does not exist: {params.input_sbcd_part_layout}."
            print(f"Using the provided sbcd lay out file: {params.input_sbcd_part_layout}.")
            print(f"Linking {params.sbcd_part_layout} to {params.sbcd_part_layout}.")
            create_symlink( input_path=params.input_sbcd_part_layout, 
                            output_path=params.sbcd_part_layout,  
                            handle_missing_input="warn",  
                            handle_existing_output="replace",  
                            silent=True)
            args_layout_input = f"--input {params.input_sbcd_part_layout} --input_type layout "
        elif params.input_sbcd_layout_summary is not None:
            assert os.path.exists(params.input_sbcd_layout_summary), f"Provided sbcd layout summary file does not exist: {params.input_sbcd_layout_summary}."
            print(f"Using the provided sbcd lay out summary file: {params.input_sbcd_layout_summary}")
            args_layout_input = f"--input {params.input_sbcd_layout_summary} --input_type summary "
        else:
            raise ValueError("No sbcd layout file or layout summary is provided.")
        
        shell(
        r"""
        set -euo pipefail

        if [[ "{exe_mode}" == "HPC" ]]; then
            module load imagemagick/7.1.0-25.lua
        fi
        
        source {py39_env}/bin/activate
    
        # s1b
        command time -v {py39} {local_scripts}/rule_a2.sbcd_section_from_lane.py \
            --sbcd_dir {sbcd_dir} \
            --sbcd_part_dir {sbcd_part_dir} \
            --section {params.section} {args_layout_input}

        # s2
        echo -e "Combinding sbcds.part to ncbds.\\n"
        command time -v  {spatula} combine-sbcds \
            --layout {params.sbcd_part_layout} \
            --manifest {params.sbcd_part_mnfst} \
            --sbcd {sbcd_part_dir} \
            --out {nbcd_dir} \
            --rowgap {params.gap_row} \
            --colgap {params.gap_col}  \
            --max-dup {params.dup_maxnum} \
            --max-dup-dist-nm {params.dup_maxdist}

        # s3
        echo -e "Runing draw-xy...\\n"
        command time -v  {spatula} draw-xy \
            --tsv {output.nbcd_tsv} \
            --out {output.nbcd_png} \
            --coord-per-pixel {params.visual_coord_per_pixel} \
            --icol-x {params.visual_icol_x} \
            --icol-y {params.visual_icol_y} \
            --intensity-per-obs {params.visual_intensity_per_obs}
        """
        )
