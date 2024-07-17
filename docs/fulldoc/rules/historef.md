# Rule `historef`

## Purpose
The goal of `historef` rule is to match the histology image with the spatial coordinates of the spatial digital gene expression (SGE) matrix. This is achieved by aligning fiducial markers observable in both the histology image and the [composite image](./align.md#3-a-comprehensive-view-of-sbcd-smatch-and-sge-images) of "sbcd", "smatch", and "sge" images. The current pipeline allows multiple input histology files.

## Input Files

* **A histology image**
Th histology image with fiducial markers is required. The [`historef`](https://github.com/seqscope/historef) identifies fiducial marks by detecting the brightness in the input histology image, so it is crucial that fiducial markers are the brightest area in the histology image.

* **The composite image**
The [composite image](./align.md#3-a-comprehensive-view-of-sbcd-smatch-and-sge-images), which shows "sbcd", "smatch", and "sge" images side-by-side, will also be applied to [`historef`](https://github.com/seqscope/historef).

## Output Files
The rule generates the following output in the specified directory path:
```
<output_directory>/histology/<flowcell_id>/<chip_id>/aligned/<run_id>
```

### (1) A referenced Histology File
**Description**:
The referenced histology file, which is in [GeoTIFF](https://en.wikipedia.org/wiki/GeoTIFF)format, allows the coordinate transformation between the SGE matrix and the input histology image.

**File Naming Convention**:

```
<magnification><flowcell_abbreviation>-<chip_id>-<species>-<figtype>.tif"
```

 * The `magnification` and `figtype` are derived from the `magnification` and `figtype` fields within the `histology` in the `input` section of the [job configuration](../../basic_usage/job_config.md) file.
 * The `flowcell_abbreviation` is derived by splitting the `flowcell_id`, which is sourced from the `flowcell` field in `input` section of the [job configuration](../../basic_usage/job_config.md) file, by "-" and taking the first part.

**File Visualization**:
<figure markdown="span">
![hne_image](../../images/10XN3-B08C-mouse-hne.png){ width="60%" }
</figure>

The image displayed above only serves an initial glimpse into the results but has been substantially reduced in size and is presented in PNG format.

For an in-depth examination, access the full-size referenced histology file within the [`B08Cshallow_20240319_SGE_withHE.tar.gz`](https://doi.org/10.5281/zenodo.10841778) tarball.


### (2) A Re-sized Referenced Histology File
**Description**:
A TIFF file shares the identical dimensions with both the ["smatch" image](./smatch.md#2-a-smatch-image) and the ["sge" image](./sdge_visual.md#output-files), acilitating the comparison of consistency between the histology file and these images.

**File Naming Convention**:

```
<magnification><flowcell_abbreviation>-<chip_id>-<species>-<figtype>-fit.tif"
```

 * The `magnification` and `figtype` are derived from the `magnification` and `figtype` fields within the `histology` section of the [job configuration](../../basic_usage/job_config.md) file.
 * The `flowcell_abbreviation` is derived by splitting the `flowcell_id`, which is sourced from the `flowcell` field in `input` section of the [job configuration](../../basic_usage/job_config.md) file, by "-" and taking the first part.

**File Visualization**:
<figure markdown="span">
![hne_image](../../images/10XN3-B08C-mouse-hne-fit.png){ width="100%" }
</figure>

The full-size TIFF is provided in the [`B08Cshallow_20240319_SGE_withHE.tar.gz`](https://doi.org/10.5281/zenodo.10841778).

## Output Guidelines
To verify the accuracy of the alignment, it is recommended to compare the [re-sized referenced histology file](#2-a-re-sized-referenced-histology-file) against the ["smatch" image](./smatch.md#2-a-smatch-image) and the ["sge" image](./sdge_visual.md#output-files), ensuring a precise match with the histology images. A clear visibility of fiducial marks in both images indicates an accurate match with submicrometer resolution upon overlay. If the fiducial marks are insufficiently visible or aligned incorrectly, manual adjustment of the histology images is required.

## Parameters

The following parameter in the [job configuration](../../basic_usage/job_config.md) file will be applied in this rule.

```yaml
histology:
    min_buffer_size: 1000   
    max_buffer_size: 2000
    step_buffer_size: 100
    raster_channel: 1      
```

* **The `histology` Parameters**
    * `min_buffer_size`, `max_buffer_size` and `step_buffer_size` will create a list of buffer size help historef to do the alignment. For example, the default `min_buffer_size`, `max_buffer_size` and `step_buffer_size` are 1000, 2000, and 100, respectively, and this will return a buffer size list of 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000.
    * `raster_channel` specifies which channel from the ["sge" image](./sdge_visual.md#output-files) will used for historef alignment

## Dependencies
Rule `historef` commences only after Rule [`dge2sdge`](./dge2sdge.md) has successfully executed. An overview of the rule dependencies are provided in the [Workflow Structure](../../home/workflow_structure.md).

## Code Snippet
The code for this rule is provided in [b02_historef.smk](https://github.com/seqscope/NovaScope/blob/main/rules/b02_historef.smk)
