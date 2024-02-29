rule a02_sbcd2nbcd:
    input:
        sbcd_dir         = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds", sc2seq1[wildcards.section]),
        sbcd_mnfst       = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds", sc2seq1[wildcards.section], "manifest.tsv"),
    output:
        nbcd_tsv         = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.tsv.gz"),
        nbcd_mnfst       = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "manifest.tsv"),
        nbcd_png         = os.path.join(main_dirs["seq1st"], "{flowcell}", "nbcds", "{section}", "1_1.sbcds.sorted.png"),
    params:
        # general params
        section          = lambda wildcards: wildcards.section,
        # sbcd.part
        sbcd_part_layout = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds.part", "L" + sc2ln[wildcards.section], wildcards.section, wildcards.section+".layout.tsv"),
        sbcd_part_mnfst  = lambda wildcards: os.path.join(main_dirs["seq1st"], wildcards.flowcell, "sbcds.part", "L" + sc2ln[wildcards.section], wildcards.section, "manifest.tsv"),
        # combine 
        layout           = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('layout', "/nfs/turbo/sph-hmkang/index/data/nova6000.section.info.v2.tsv"),  #Deprecated: /nfs/turbo/sph-hmkang/index/data/nova.part.dict.tsv
        gap_row          = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('gap_row', 0.0517),
        gap_col          = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('gap_col', 0.0048),
        dup_maxnum       = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('dup_maxnum', 1),
        dup_maxdist      = config.get("preprocess", {}).get("sbcd2nbcd", {}).get('dup_maxdist', 1),
        # visualization
        visual_coord_per_pixel    = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("coord_per_pixel", 1000),
        visual_intensity_per_obs  = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("intensity_per_obs", 50),
        visual_icol_x             = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("icol_x", 3),
        visual_icol_y             = config.get("preprocess", {}).get("visualization", {}).get("drawxy",{}).get("col_y", 4),
    resources:
        time = "5:00:00",
        mem  = "6500m"
    run:
        nbcd_dir         = os.path.dirname(output.nbcd_tsv)
        sbcd_part_dir    = os.path.dirname(params.sbcd_part_layout)
        shell(
        """
        #module load python/3.9.12
        module load imagemagick/7.1.0-25.lua

        source {py39_env}/bin/activate
    
        echo -e "Creating sbcd.part for the section.\\n"
        command time -v {py39} {local_scripts}/rule-a2_sbcd_section_from_lane.py \
            --input_layout {params.layout} \
            --sbcd_dir {input.sbcd_dir} \
            --sbcd_part_dir {sbcd_part_dir} \
            --section {params.section}

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
