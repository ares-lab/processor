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
            config['output_dir']+'/trimmed/barcode{bc}.fastq.gz.index.readdb',
            bc=processor.padded_barcodes(samples))

# Basecalling and demultiplexing
# -----------------------------------------------------------------------------
rule demux_deepbinner:
    input:
        config['fast5_dir']
    output:
        flag = touch(config['output_dir']+ "/deepbinner.completed")
    threads: 8
    params:
        out_dir = config['output_dir']+'/deepbinner',
        model = {
            "SQK-RBK004": '--rapid',
            "EXP-NBD103": '--native'}[config['kit']]
    shell:
        """
        deepbinner realtime \
        {params.model} \
        --in_dir {input} \
        --out_dir {params.out_dir} \
        --omp_num_threads {threads} \
        --intra_op_parallelism_threads {threads} \
        --no_batch
        """

rule basecall_albacore:
    input:
        db_flag=ancient(config['output_dir'] + "/deepbinner.completed"),
        bc_dir=ancient(config['output_dir']+'/deepbinner/barcode{bc}')
    output:
        directory(config['output_dir']+'/albacore/albacore{bc}/workspace/barcode{bc}')
    threads: 8
    shell:
        """
        read_fast5_basecaller.py \
        --input {input.bc_dir} \
        --save_path {output} \
        --flowcell {config[flowcell]} \
        --kit {config[kit]} \
        --output_format fastq \
        --recursive \
        --disable_filtering \
        --reads_per_fastq_batch 0 \
        --files_per_batch_folder 0 \
        --worker_threads {threads}
        """

rule keep_consensus:
    input:
        config['output_dir']+'/albacore/albacore{bc}/workspace/barcode{bc}'
    output:
        config['output_dir']+'/consensus/barcode{bc}.fastq.gz'
    shell:
        "cat {input}/*.fastq | gzip > {output}"

rule trim_porechop:
    input:
        config['output_dir']+"/consensus/{barcode}.fastq.gz"
    output:
        config['output_dir']+"/trimmed/{barcode}.fastq.gz"
    conda:
        "envs/porechop.yaml"
    shell:
        "porechop -i {input} -o {output} --discard_middle"

rule index_nanopolish:
    input:
        fast5s = config['output_dir']+'/deepbinner/barcode{bc}',
        summary = config['output_dir']+'/albacore/albacore{bc}/sequencing_summary.txt',
        fastq = config['output_dir']+'/trimmed/barcode{bc}.fastq.gz'
    output:
        config['output_dir']+'/trimmed/barcode{bc}.fastq.gz.index.readdb'
    conda:
        "envs/nanopolish.yaml"
    shell:
        "nanopolish index -d {input.fast5s} -s {input.summary} {input.fastq}"
        
