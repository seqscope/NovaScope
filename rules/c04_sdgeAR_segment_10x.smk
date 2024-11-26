rule c04_sdgeAR_segment_10x:
    input:
        transcript_in   = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", ("{unit_id}.transcripts.tsv.gz" if wildcards.sge_qc=="raw" else "{unit_id}.{solo_feature}."+wildcards.sge_qc+".transcripts.tsv.gz")),
        ftr_in          = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", ("{unit_id}.feature.tsv.gz"     if wildcards.sge_qc=="raw" else "{unit_id}.feature.clean.tsv.gz")),
        boundary_in     = lambda wildcards: os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.boundary.strict.geojson") if wildcards.sge_qc == "filtered" else [],
        xyrange_in      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.{solo_feature}.{sge_qc}.coordinate_minmax.tsv"),    # This file is not used but is required to make sure every transcript file has a corresponding xyrange file.
        sdgeAR_axis     = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "major_axis.tsv"),
    output:
        hexagon_bcd      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "barcodes.tsv.gz"),
        hexagon_ftr      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "features.tsv.gz"),
        hexagon_mtx      = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "segment", "{solo_feature}.{sge_qc}.d_{hexagon_width}", "10x", "matrix.mtx.gz"),
    params:
        solo_feature        = "{solo_feature}",
        hexagon_width       = "{hexagon_width}",
        sge_qc              = "{sge_qc}",
        hex_n_move          = config.get("downstream", {}).get('segment', {}).get('hex_n_move', 1), 
        precision           = config.get("downstream", {}).get('segment', {}).get('precision', 2), 
        min_density_per_unit = config.get("downstream", {}).get('segment', {}).get('10x', {}).get('min_density_per_unit', 0.01), 
        min_ct_per_unit     = config.get("downstream", {}).get('segment', {}).get('10x', {}).get('min_ct_per_unit', 10),
        # tools
        module_cmd          = get_envmodules_for_rule(["python", "samtools"], config),
    resources:
        mem  = "7000MB", 
        time = "12:00:00",
    run:
        # dirs/files
        hexagon_dir = os.path.dirname(output.hexagon_bcd)
        
        major_axis = pd.read_csv(input.sdgeAR_axis, sep='\t', header=None).iloc[0, 0]
        
        if params.sge_qc == "filtered":
            boundary_args = f"--boundary {input.boundary_in}"
        else:
            boundary_args = ""
        
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}

        command time -v {python} {ficture}/ficture/scripts/make_sge_by_hexagon.py \
            --input {input.transcript_in} \
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
