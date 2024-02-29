rule b01_gene_visual:
    input:
        sdge_bcd      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "barcodes.tsv.gz"),
        sdge_ftr      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "features.tsv.gz"),
        sdge_mtx      = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "matrix.mtx.gz"),
    output:
        gof_rgb_tar   = os.path.join(main_dirs["align"],  "{flowcell}", "{section}", "sge", "{specie_with_seq2v}", "gene_visual.tar.gz"),
    params:
        layout            = config.get("preprocess", {}).get("dge2sdge", {}).get('layout', "/nfs/turbo/umms-leeju/experimental/nova/nbcds/layout.1x1.tsv"),
        visual_gof        = config.get("preprocess", {}).get("genes_of_interest", None), # by default it will be the top five genes
        visual_max_scale  = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("max_scale", 50),
        visual_res        = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("resolution", 1000),
        visual_gene_scale = config.get("preprocess", {}).get("visualization", {}).get("rgb",{}).get("gene_scale", 20),
    resources: 
        mem           = "13000MB", 
        time          = "5:00:00"  
    run:
        sdge_dir = os.path.dirname(input.sdge_bcd)
        visual_dir = os.path.join(sdge_dir, "gene_visual")
        os.makedirs(visual_dir, exist_ok=True)

        if params.visual_gof is None:
            visual_gof = subprocess.check_output(f"zcat {input.sdge_ftr} | sort -k4,4nr | head -n 5 | cut -f2", shell=True).decode().strip().split("\n")
        else:
            # read the file which only have one column and store it in a list
            assert os.path.exists(params.visual_gof), f"File {params.visual_gof} does not exist"
            visual_gof = [x.strip() for x in open(params.visual_gof).readlines()]
        
        print(f"Visualizing the following genes: {visual_gof}")

        #make a subdirectory for the visualizations
        shell(
        """
        module load imagemagick/7.1.0-25.lua
        source {py39_env}/bin/activate
        
        echo -e "Creating RGB images for each gene of interest...\\n"
        for gene in {visual_gof}; do 
            echo -e " - $gene \\n"
            command time -v {py39} {sttools2}/scripts/rgb-gene-image.py \
                --layout {params.layout} \
                --sdge {sdge_dir} \
                --out {visual_dir}/rgb.${{gene}}.png \
                -r _all:1:2 \
                -g _all:1:3 \
                -b _all:1:4 \
                --max-scale {params.visual_max_scale} \
                --res {params.visual_res} \
                --scale {params.visual_gene_scale} \
                --transpose
        done

        # now, compress the visual_dir
        tar -czvf {output.gof_rgb_tar} {visual_dir}
        """
        )
           