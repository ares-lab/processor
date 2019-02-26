#=================================================#
# ARES Processor: MinION Run Processing Pipeline  #
# https://github.com/ares-lab/processor           #
#=================================================#

from snakemake.utils import min_version
import processor

# Setup
# ------------------------------------------------
min_version("5.2")
samples = processor.parse_samplesheet(config['samplesheet_fp'])

rule all:
    input:
        expand(
            config['output_dir']+'/demultiplexed/fastq/barcode{bc}/trimmed.fastq.gz',
            bc=processor.padded_barcodes(samples))

# Basecalling and demultiplexing
# ------------------------------------------------
rule demux_fast5:
    output:
        out_dir = directory(expand(
            config['output_dir']+'/demultiplexed/fast5/barcode{bc}',
            bc=processor.padded_barcodes(samples))),
        flag = touch(config['output_dir']+'/demultiplexed/fast5/.deepbinner.completed')
    threads: 8
    params:
        in_dir = config['fast5_dir'],
        out_dir = config['output_dir']+'/demultiplexed/fast5',
        model = {
            "SQK-RBK004": '--rapid',
            "EXP-NBD103": '--native'}[config['kit']]    
    shell:
        """
        deepbinner realtime \
        {params.model} \
        --in_dir {params.in_dir} \
        --out_dir {params.out_dir} \
        --omp_num_threads {threads} \
        --intra_op_parallelism_threads {threads} \
        --no_batch
        """

rule basecall_fast5:
    input:
        fast5=ancient(config['output_dir']+'/demultiplexed/fast5/barcode{bc}'),
        flag=rules.demux_fast5.output.flag
    output:
        out_dir = directory(config['output_dir']+'/demultiplexed/fastq/barcode{bc}/albacore/workspace/barcode{bc}'),
        summary = config['output_dir']+'/demultiplexed/fastq/barcode{bc}/albacore/sequencing_summary.txt'
    threads: 8
    params:
        out_dir = config['output_dir']+'/demultiplexed/fastq/barcode{bc}/albacore'
    shell:
        """
        read_fast5_basecaller.py \
        --input {input.fast5} \
        --save_path {params.out_dir} \
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
        ancient(rules.basecall_fast5.output.out_dir)
    output:
        temp(config['output_dir']+'/demultiplexed/fastq/barcode{bc}/untrimmed.fastq.gz')
    shell:
        "cat {input}/*.fastq | gzip > {output}"

rule trim_adapters:
    input:
        ancient(rules.keep_consensus.output)
    output:
        config['output_dir']+"/demultiplexed/fastq/barcode{bc}/trimmed.fastq.gz"
    conda:
        "envs/porechop.yaml"
    shell:
        "porechop -i {input} -o {output} --discard_middle"

rule index_nanopolish:
    input:
        fast5 = ancient(rules.basecall_fast5.input.fast5),
        fastq = ancient(rules.trim_adapters.output),
        summary = ancient(rules.basecall_fast5.output.summary)
    output:
        config['output_dir']+'/demultiplexed/fastq/barcode{bc}/trimmed.fastq.gz.index.readdb'
    conda:
        "envs/nanopolish.yaml"
    shell:
        "nanopolish index -d {input.fast5} -s {input.summary} {input.fastq}"
        
