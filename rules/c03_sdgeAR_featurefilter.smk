def locate_geneinfo(sp2geneinfo, species, novascope_dir):
    if sp2geneinfo is not None:
        sp2geneinfo = sp2geneinfo
    else:
        sp2geneinfo = {
                        "mouse": os.path.join(novascope_dir, "info", "geneinfo", "Mus_musculus.GRCm39.107.names.tsv.gz"),
                        "human": os.path.join(novascope_dir, "info", "geneinfo", "Homo_sapiens.GRCh38.107.names.tsv.gz"),
                        "chick": os.path.join(novascope_dir, "info", "geneinfo", "Gallus_gallus.GRCg6a.106.names.tsv.gz"),
                    }
    geneinfo = sp2geneinfo[species]
    assert geneinfo is not None, f"Error: Missing gene information file for {species}. Please check the 'geneinfo' configuration in your environment configuration file."
    assert os.path.exists(geneinfo), f"Error: The gene information file for {species} does not exist. Please verify the file path in your environment configuration file."
    return geneinfo

rule c03_sdgeAR_featurefilter:
    input:
        ftr        = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.tsv.gz"),
    output:
        ftr_clean  = os.path.join(main_dirs["analysis"], "{run_id}", "{unit_id}", "preprocess", "{unit_id}.feature.clean.tsv.gz"),
    params:
        sp2geneinfo       = config.get("env",{}).get("ref", {}).get("geneinfo", None),
        species           = species,
        # gene filtering parameters
        kept_gene_type    = config.get("downstream", {}).get('gene_filter', {}).get('kept_gene_type', "protein_coding|lncRNA"),
        rm_gene_regex     = r"{0}".format(config.get("downstream", {}).get('gene_filter', {}).get('rm_gene_regex', "^Gm\\d+|^mt-|^MT-")), 
        min_ct_per_feature= config.get("downstream", {}).get('gene_filter', {}).get('min_ct_per_feature', 50),
        # module
        module_cmd        = get_envmodules_for_rule(["samtools"], config.get("env",{}).get("envmodules", {}))
    threads: 2
    resources:
        mem  = "14000MB",
        time = "20:00:00", 
    run:

        if params.kept_gene_type is None or params.kept_gene_type == "":
            gtype_args = ""
        else:
            geneinfo = locate_geneinfo(params.sp2geneinfo, params.species, smk_dir)
            gtype_args = f"--kept_gene_type \"{params.kept_gene_type}\" --geneinfo {geneinfo}"

        if params.rm_gene_regex is None or params.rm_gene_regex == "":
            gname_args = ""
        else:
            gname_args = f"--rm_gene_regex \"{params.rm_gene_regex}\""

        if params.min_ct_per_feature is None or params.min_ct_per_feature == "":
            gct_args = ""
        else:
            gct_args = f"--min_ct_per_feature {params.min_ct_per_feature}"

        # sdgeAR_ftr_clean_unzip = output.ftr_clean.replace(".gz", "")
        shell(
        r"""
        set -euo pipefail
        {params.module_cmd}
        source {pyenv}/bin/activate

        command time -v {python} {novascope_scripts}/rule_c03.feature_filter.py --input {input.ftr} --output {output.ftr_clean}  {gtype_args} {gname_args} {gct_args}
        """
        )