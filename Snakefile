#
# ARES Lab MinION Run Processor
# https://github.com/ares-lab/processor
#
from snakemake.utils import min_version
import processor

# Setup
# -----------------------------------------------------------------------------
min_version("5.2")
samples = processor.parse_samplesheet(config['samplesheet_fp'])

rule all:
    input:
        expand(
            config['output_dir']+'/trimmed/{sample}.fastq.gz',
            sample=samples.sample_id)

# Basecalling and demultiplexing
# -----------------------------------------------------------------------------
rule basecall_albacore:
    input:
        config['fast5_dir']
    output:
        expand(
            config['output_dir']+"/albacore/workspace/barcode{bc}/reads.fastq",
            bc = processor.padded_barcodes(samples))
    params:
        save_path = config['output_dir']+"/albacore" 
    threads: 8
    shell:
        """
        read_fast5_basecaller.py \
        --input {input} \
        --save_path {params.save_path} \
        --flowcell {config[flowcell]} \
        --kit {config[kit]} \
        --output_format fastq \
        --recursive \
        --disable_filtering \
        --reads_per_fastq_batch 0 \
        --files_per_batch_folder 0 \
        --worker_threads {threads} && \
        for file in $(find {params.save_path} -name '*.fastq'); do
          mv $file $(dirname $file)/reads.fastq
        done
        """

rule make_sample_fastqs:
    input:
        lambda wc: expand(
            config['output_dir']+"/albacore/workspace/barcode{bc}/reads.fastq",
            bc = processor.padded_barcodes(samples.loc[samples.sample_id == wc['sample']]))
    output:
        config['output_dir']+"/fastq/{sample}.fastq.gz"
    shell:
        """cat {input} | gzip > {output}"""

rule trim_porechop:
    input:
        config['output_dir']+"/fastq/{sample}.fastq.gz"
    output:
        config['output_dir']+"/trimmed/{sample}.fastq.gz"
    conda:
        "envs/porechop.yaml"
    shell:
        "porechop -i {input} -o {output} --discard_middle"
