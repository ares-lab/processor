
import processor

configfile: "config.yaml"

samples = processor.parse_samplesheet(config['samples'])

print(samples)

rule all:
    input: expand(config['data_dir']+'/fastq/{sample}.fastq.gz', sample=samples.sample_id)

rule albacore:
    input: config['data_dir']+"/fast5"
    output:
        expand(
            config['data_dir']+"/albacore/workspace/barcode{bc}/reads.fastq",
            bc = processor.padded_barcodes(samples))
    params:
        save_path = config['data_dir']+"/albacore" 
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

rule merge:
    input:
        lambda wc: expand(
            config['data_dir']+"/albacore/workspace/barcode{bc}/reads.fastq",
            bc = processor.padded_barcodes(samples.loc[samples.sample_id == wc['sample']]))
    output:
        config['data_dir']+"/fastq/{sample}.fastq.gz"
    shell:
        """cat {input} | gzip > {output}"""
