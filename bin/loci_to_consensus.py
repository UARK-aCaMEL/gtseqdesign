#!/usr/bin/env python3
import argparse
import numpy as np
import re
from multiprocessing import Pool, cpu_count

def parse_loci_file(filepath):
    """Parse .loci file into list of (index, [sequences]) tuples."""
    alignments = []
    current_locus = []
    index = 0
    idx_regex = re.compile(r'\|(\d+)\|$')

    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith('//'):
                match = idx_regex.search(line)
                if match:
                    index = int(match.group(1))
                else:
                    raise ValueError(f"Could not parse index from line: {line}")
                if current_locus:
                    alignments.append((index, current_locus))
                    current_locus = []
            else:
                parts = line.split(maxsplit=1)
                if len(parts) == 2:
                    _, seq = parts
                    current_locus.append(seq.replace('>', '').strip())

    return alignments

def compute_consensus(index_and_sequences):
    """Return (index, consensus sequence) for one locus."""
    index, sequences = index_and_sequences
    arr = np.array([list(seq) for seq in sequences], dtype='U1')
    consensus = []

    for col in arr.T:
        mask = (col != '-') & (col != 'N') & (col != 'n')
        filtered = col[mask]
        if filtered.size == 0:
            consensus.append('N')
        else:
            values, counts = np.unique(filtered, return_counts=True)
            consensus.append(values[np.argmax(counts)])

    return index, ''.join(consensus)

def write_fasta(consensus_dict, prefix, output_path):
    lines = []
    for index in sorted(consensus_dict):
        lines.append(f">{prefix}_{index}\n{consensus_dict[index]}")
    with open(output_path, 'w') as out:
        out.write('\n'.join(lines) + '\n')

def main():
    parser = argparse.ArgumentParser(description="Generate consensus FASTA from .loci alignments")
    parser.add_argument('--input', required=True, help='Input .loci file')
    parser.add_argument('--output', required=True, help='Output FASTA file')
    parser.add_argument('--prefix', default='RAD', help='Prefix for sequence names')
    parser.add_argument('--threads', type=int, default=cpu_count(), help='Number of processes to use')

    args = parser.parse_args()

    loci = parse_loci_file(args.input)

    with Pool(processes=args.threads) as pool:
        results = pool.map(compute_consensus, loci)

    consensus_dict = dict(results)
    write_fasta(consensus_dict, args.prefix, args.output)

if __name__ == '__main__':
    main()
