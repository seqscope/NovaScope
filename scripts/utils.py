import os, sys, gzip
from pathlib import Path
from typing import List, Callable, Dict, Union, Iterator, Optional, Any
from contextlib import contextmanager

@contextmanager
def read_maybe_gzip(filepath:Union[str,Path]):
    if isinstance(filepath, Path): filepath = str(filepath)
    is_gzip = False
    with open(filepath, 'rb', buffering=0) as raw_f: # no need for buffers
        if raw_f.read(3) == b'\x1f\x8b\x08':
            is_gzip = True
    if is_gzip:
        with gzip.open(filepath, 'rt', encoding='utf-8') as f:
            yield f
    else:
        with open(filepath, 'rt', encoding='utf-8') as f: # 256KB buffer
            yield f

_iupac_codes = {"A":"A", "C":"C", "G":"G", "T":"T",
                "R":"AG", "Y":"CT", "S":"GC", "W":"AT", "K":"GT", "M":"AC",
                "B":"CGT", "D":"AGT", "H":"ACT", "V":"ACG",
                "N":"ACGT"}
def check_iupac(seq, pattern):
    mismatches = 0 
    for (i, c) in enumerate(pattern):
        if c != "N":
            if seq[i] not in _iupac_codes[c]:
                mismatches += 1
    return mismatches

_complement = {'A': 'T', 'C': 'G', 'G': 'C', 'T': 'A'}
def revcomp(seq):
    return "".join([_complement.get(x, x) for x in reversed(seq)])
    
    
