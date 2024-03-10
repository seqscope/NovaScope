rule b01_gene_visual:
    input:
        sdge_bcd      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "barcodes.tsv.gz"),
        sdge_ftr      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "features.tsv.gz"),
        sdge_mtx      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "matrix.mtx.gz"),
    output:
        gof_rgb_tar   = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "{flowcell}"+"."+"{section}"+"."+"{specie_with_seq2v}"+".gene_visual.tar.gz"),
    params:
        rgb_layout        = check_path(config.get("preprocess", {}).get("dge2sdge", {}).get('layout', None), job_dir, strict_mode=False),
        visual_gof        = config.get("preprocess", {}).get("gene_visual", None), # by default it will be the top five genes
        visual_max_scale  = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("max_scale", 50),
        visual_res        = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("resolution", 1000),
        visual_gene_scale = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("gene_scale", 20),
        # module
        module_cmd        = get_envmodules_for_rule(["python", "imagemagick"], module_config, exe_mode)
    resources: 
        mem           = "13000MB", 
        time          = "5:00:00"  
    run:
        sdge_dir = os.path.dirname(input.sdge_bcd)

        visual_dir = output.gof_rgb_tar.replace(".tar.gz", "")
        os.makedirs(visual_dir, exist_ok=True)

        visual_dirprefix = os.path.basename(visual_dir)

        # Check the layout for rgb-gene-image.
        rgb_layout = setup_rgb_layout(params.rgb_layout, sdge_dir)

        # Obtain genes of interest.
        if params.visual_gof is None:
            visual_gof = subprocess.check_output(f"zcat {input.sdge_ftr} | sort -k4,4nr | head -n 5 | cut -f 2", shell=True).decode().strip().split("\n")
        else:
            assert os.path.exists(params.visual_gof), f"File {params.visual_gof} does not exist"
            visual_gof = [x.strip() for x in open(params.visual_gof).readlines()]
        
        print(f"Visualizing the following genes: {visual_gof}")

        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        source {py39_env}/bin/activate

        #  ## 1:gene 2:genefull 3:spliced 4:unspliced 5:ambiguous
        echo -e "Creating RGB images for each gene of interest...\\n"
        for gene in {visual_gof}; do 
            echo -e " - $gene \\n"
            command time -v {py39} {local_scripts}/rgb-gene-image.py \
                --layout {rgb_layout} \
                --sdge {sdge_dir} \
                --out {visual_dir}/rgb.${{gene}}.png \
                -r ${{gene}}:1:2 \
                -g ${{gene}}:1:3 \
                -b ${{gene}}:1:4 \
                --max-scale {params.visual_max_scale} \
                --res {params.visual_res} \
                --scale {params.visual_gene_scale} \
                --transpose
        done

        # now, compress the visual_dir
        tar -czvf {output.gof_rgb_tar} -C {sdge_dir} {visual_dirprefix}

        """
        )
           