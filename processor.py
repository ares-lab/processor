from itertools import chain
import pandas as pd

def padded_barcodes(samples):
    return [b.zfill(2) for b in samples.barcode]

def parse_samplesheet(sample_fp):
    return pd.read_csv(sample_fp, dtype=str, sep='\t')
