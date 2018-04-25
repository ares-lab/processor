from itertools import chain

data_dir = "ARES0002"

mapping = {
    'S-180222-00127-1': ['7','9']
}

def barcodes(sample=None):
    if sample == None:
        return list(chain.from_iterable(
            [[n.zfill(2) for n in b] for b in mapping.values()]))
    return [n.zfill(2) for n in mapping.get(sample)]

print(barcodes())

def barcodes_from_wc(wildcards):
    return barcodes(wildcards['sample'])

rule all:
    input: "ARES0002/fastq/S-180222-00127-1.fastq.gz"

rule albacore:
    input: data_dir+"/fast5"
    output:
        expand(
            data_dir+"/albacore/workspace/barcode{bc}/reads.fastq",
            bc = barcodes())
    params:
        save_path = data_dir+"/albacore" 
    threads: 32
    shell:
        """
        read_fast5_basecaller.py \
        --input {input} \
        --save_path {params.save_path} \
        --flowcell FLO-MIN106 \
        --kit SQK-RBK001 \
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
            data_dir+"/albacore/workspace/barcode{bc}/reads.fastq",
            bc = barcodes_from_wc(wc))
    output:
        data_dir+"/fastq/{sample}.fastq.gz"
    shell:
        """cat {input} | gzip > {output}"""
