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
- `data_dir`: this is where Processor expects to find the `fast5` folder, and where it will write output files
- `flowcell`: the flowcell model number
- `kit`: the kit version number
- `samples`: the path to the sample sheet, described below

The sample sheet contains two tab-delimited columns, `sample_id` and `barcode`. The `sample_id` column will be used to generate the names of the resulting fastq.gz files, so it should not contain spaces or invalid characters for a file like `/`.  The barcode column gives the numeric index of what barcode was used during library prep.

## Running

Since this is a Snakemake workflow, execution is just by calling `snakemake` from the `processor` directory.
