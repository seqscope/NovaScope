
def get_nbcd_from_mtx(file_path):
    with gzip.open(file_path, 'rt') as f:
        row_count = 0

        for line in f:
            # Skip comment lines that start with '%'
            if line.startswith('%'):
                continue

            row_count += 1

            # Once we reach the 3rd non-comment line, return it
            if row_count == 3:
                nbcd=int(line.strip().split()[1])
                return nbcd
    return None

rule c04_sdgeAR_segment_10x_resilient:
    input:
        transcript_raw      = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.transcripts.tsv.gz") if wildcards.sge_qc=="raw" else [],  
        polygonfilter_log   = lambda wildcards: [] if wildcards.sge_qc=="raw" else os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.filtered.log"), 
        xyrange_in          = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv")  if wildcards.sge_qc=="raw" else [],    
        ftr_in              = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", ("{unit_id}.feature.tsv.gz"     if wildcards.sge_qc=="raw" else "{unit_id}.feature.clean.tsv.gz")), 
        sdgeAR_axis         = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "major_axis.tsv"),
    output:
        hexagon_log         = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "{unit_id}.{solo_feature}.{sge_qc}.10x.d_{hexagon_width}.log")
    params:
        # basic params
        solo_feature        = "{solo_feature}",
        hexagon_width       = "{hexagon_width}",
        sge_qc              = "{sge_qc}",
        # aux params
        hex_n_move          = config.get("downstream", {}).get('segment', {}).get('hex_n_move', 1), 
        precision           = config.get("downstream", {}).get('segment', {}).get('precision', 2), 
        min_density_per_unit= config.get("downstream", {}).get('segment', {}).get('10x', {}).get('min_density_per_unit', 0.01), 
        min_ct_per_unit     = config.get("downstream", {}).get('segment', {}).get('10x', {}).get('min_ct_per_unit', 10),
        exist_action        = config.get("downstream", {}).get('segment', {}).get('10x', {}).get('exist_action', "overwrite"), # ["skip", "overwrite"]
        # modules
        module_cmd          = get_envmodules_for_rule(["python", "samtools"], config),
    resources:
        mem  = "7000MB", 
        time = "6:00:00",
    run:
        # dirs/files
        hexagon_dir = os.path.join(os.path.dirname(output.hexagon_log), "10x")
        os.makedirs(hexagon_dir, exist_ok=True)
        hexagon_bcd = os.path.join(hexagon_dir, "barcodes.tsv.gz")
        hexagon_ftr = os.path.join(hexagon_dir, "features.tsv.gz")
        hexagon_mtx = os.path.join(hexagon_dir, "matrix.mtx.gz")

        major_axis = pd.read_csv(input.sdgeAR_axis, sep='\t', header=None).iloc[0, 0]

        # 1) If polygonfilter failed, skip the segmentation
        if params.sge_qc == "filtered":
            # check the status of the previous step
            polygonfilter_status = open(input.polygonfilter_log).read().strip()
            if "Failed" in polygonfilter_status:
                with open(output.hexagon_log, "w") as f:
                    f.write(polygonfilter_status)
                print(f"Skip hexagon segmentation: The polygonfilter step failed (see {input.polygonfilter_log}).")
                return
            
            # update the boundary file
            boundary_in = input.polygonfilter_log.replace(".filtered.log", ".boundary.strict.geojson")
            boundary_args = f"--boundary {boundary_in}"
            # update transcript file
            transcript_in = params.transcript_filtered
        else:
            boundary_args = ""
            transcript_in = input.transcript_raw

        # 2) If the segmentation exists and the exist_action is "skip", skip the segmentation
        if params.exist_action == "skip" and os.path.exists(hexagon_bcd) and os.path.exists(hexagon_ftr) and os.path.exists(hexagon_mtx):
            print("Skip hexagon segmentation: The segmentation exists.")
            with open(output.hexagon_log, "w") as f:
                f.write("Done")
            return 

        # 3) Start the hexagon segmentation
        print("Start hexagon segmentation...")
        try:
            shell(
            r"""
            set -euo pipefail
            {params.module_cmd}

            command time -v {python} {ficture}/ficture/scripts/make_sge_by_hexagon.py \
                --input {transcript_in} \
                --feature {input.ftr_in} \
                --output_path {hexagon_dir} \
                --mu_scale {mu_scale} \
                --major_axis {major_axis} \
                --key {params.solo_feature} \
                --precision {params.precision} \
                --hex_width {params.hexagon_width} \
                --n_move {params.hex_n_move} \
                --min_ct_per_unit {params.min_ct_per_unit} \
                --min_ct_density {params.min_density_per_unit} \
                --transfer_gene_prefix {boundary_args}
            """
            )
            # sanity check: empty sge
            nhex=get_nbcd_from_mtx(hexagon_mtx)
            print(f"The hexagon-indexed SGE has {nhex} hexagons.")
            if nhex > 0:
                with open(output.hexagon_log, "w") as f:
                    f.write("Done")
            else:
                with open(output.hexagon_log, "w") as f:
                    f.write("Failed: c04_sdgeAR_segment_10x_inhouse")
                    f.write("Issue: Returned 0 hexagons")
        except Exception as e:
            print(str(e))
            with open(output.hexagon_log, "w") as f:
                f.write("Failed: c04_sdgeAR_segment_10x_inhouse")
                f.write("Issue: "+str(e))

        
