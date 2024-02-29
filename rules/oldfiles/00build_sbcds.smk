#==============================================
#
# 00. Build sbcds from 1stseq (per fc)
#
#    * this step will generate sbcd files for a flowcell (1 sbcd file per lane per tile)
#    * all sbcds files for a flowcell will be saved in a folder named by its flowcell id.
#    * a manifest file will be generated to record the Nbarcodes, matches/mismatches, and coordinates per lane per tile. 
#
#==============================================

rule build_sbcds:
    input:
        seq1_fq    = os.path.join(tmp_root, "seq1", "{fc}" + ".fastq.gz" ),
    output:
        sbcd_dir   = directory(os.path.join(sbcd_root, "{fc}")),
        sbcd_mnfst = os.path.join(sbcd_root, "{fc}", "manifest.tsv"),
    params:
        sbcd_format = lambda wildcards: fc2ezyfmt[wildcards.fc] #config.get("build_sbcd", {}).get('format', "DraI32"), ##TODO: use 1stseq idx
    resources:
        time = "3:00:00",
    run:
        shell(
        """
        source {py310_env}/bin/activate
        
        mkdir -p {output.sbcd_dir}
        
        command time -v {py310} {sttools2}/scripts/build-spatial-barcode-dict.py \
            --spatula {spatula} \
            --fq {input.seq1_fq} \
            --format {params.sbcd_format} \
            --out {output.sbcd_dir} 
        """
        )


fcid=$1

inpath=/nfs/turbo/sph-hmkang/index/v2/sbcds/HD30-HML22
outpath=/nfs/turbo/sph-hmkang/index/nova/nbcds/HD30-HML22/L12

module load python/3.9.12
module load imagemagick/7.1.0-25.lua
venv=/nfs/turbo/sph-hmkang/hmkang/venvs/hmk_st
${venv}/bin/activate
python=${venv}/bin/python

spatula=/nfs/turbo/sph-hmkang/tools/dev/spatula/bin/spatula
layoutf=/nfs/turbo/sph-hmkang/tools/sttools2/data/hiseq_righthalf.layout.tsv

cat /nfs/turbo/sph-hmkang/index/v2/sbcds/HD30-HML22/manifest.tsv | grep -v ^1_1 | grep -v ^2_1 > ${inpath}/manifest.righthalf.tsv

echo time ${spatula} combine-sbcds --layout ${layoutf} --manifest ${inpath}/manifest.righthalf.tsv --sbcd ${inpath} --out ${outpath} --rowgap 0 --colgap 0 --max-dup 5 --max-dup-dist-nm 10000 --pixel-to-nm 37.50
time ${spatula} combine-sbcds --layout ${layoutf} --manifest ${inpath}/manifest.righthalf.tsv --sbcd ${inpath} --out ${outpath} --rowgap 0 --colgap 0 --max-dup 5 --max-dup-dist-nm 10000 --pixel-to-nm 37.50

echo ${spatula} draw-xy --tsv ${outpath}/1_1.sbcds.sorted.tsv.gz --out ${outpath}/1_1.sbcds.sorted.png --coord-per-pixel 1000 --icol-x 3 --icol-y 4 --intensity-per-obs 50
time ${spatula} draw-xy --tsv ${outpath}/1_1.sbcds.sorted.tsv.gz --out ${outpath}/1_1.sbcds.sorted.png --coord-per-pixel 1000 --icol-x 3 --icol-y 4 --intensity-per-obs 50
