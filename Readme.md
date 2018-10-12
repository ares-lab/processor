# <img src="ARES_Small.png" width=150> MinION Run Processor  

This workflow aims to automate basecalling, demultiplexing, adaptor trimming, and assembly of our MinION runs. There's nothing specific to the ARES group here, so it may be applicable for anybody doing bacterial genome assemblies from a MinION.

## Installation

Requirements:

- snakemake 5.2.0 or greater
- albacore 2.3.3 or greater (link: https://mirror.oxfordnanoportal.com/software/analysis/ont_albacore-2.3.3-cp36-cp36m-manylinux1_x86_64.whl)

1. Create a conda environment with `conda create -n processor snakemake -c bioconda`
2. Change into conda environment: `source activate processor`
3. Download albacore and install into the `processor` environment

## Configuration

Configuration is done through the `config.yaml` file. 
The relevant keys are:
- `fast5_dir`: the folder containing the fast5 files, which will be explored recursively
- `output_dir`: the folder to write all the resulting output
- `flowcell`: the flowcell model number
- `kit`: the kit version number
- `samplesheet_fp`: the path to the sample sheet, described below

The sample sheet contains two tab-delimited columns, `sample_id` and `barcode`. The `sample_id` column will be used to generate the names of the resulting fastq.gz files, so it should not contain spaces or invalid characters for a file like `/`.  The barcode column gives the numeric index of what barcode was used during library prep.

## Running

Since this is a Snakemake workflow, execution is just by calling `snakemake` from the `processor` directory.
