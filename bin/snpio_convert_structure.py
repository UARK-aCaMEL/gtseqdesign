#!/usr/bin/env python3
import argparse
import os
from snpio import VCFReader


def get_prefix_from_vcf_path(vcf_path):
    basename = os.path.basename(vcf_path)
    for ext in [".vcf.gz", ".vcf"]:
        if basename.endswith(ext):
            return basename[: -len(ext)]
    return basename  # fallback


def parse_popmap(popmap_path):
    popmap = {}
    with open(popmap_path) as f:
        for line in f:
            sample, group = line.strip().split()
            popmap[sample] = int(group.lstrip("K"))
    return popmap


def main():
    parser = argparse.ArgumentParser(
        description="Create STRUCTURE input from VCF with labeled populations"
    )
    parser.add_argument("--vcf", required=True, help="Path to VCF file")
    parser.add_argument("--popmap", required=True, help="Path to popmap (sample\\tKx)")
    args = parser.parse_args()

    prefix = get_prefix_from_vcf_path(args.vcf)

    # Read VCF using snpio
    gd = VCFReader(
        filename=args.vcf,
        popmapfile=args.popmap,
        force_popmap=True,
        verbose=True,
        plot_format="png",
        plot_fontsize=8,
        plot_dpi=300,
        prefix=prefix,
    )

    # generate missingness reports
    gd.missingness_reports()

    # convert to structure format
    output_raw = f"{prefix}.stru"
    gd.write_structure(output_raw)

    popmap = parse_popmap(args.popmap)
    output_final = f"{prefix}.labeled.stru"

    with open(output_raw, "r") as fin, open(output_final, "w") as fout:
        # Peek at first line to determine number of loci
        first_line = fin.readline()
        if not first_line:
            raise ValueError("STRUCTURE file is empty")

        num_loci = len(first_line.strip().split()) - 2
        fout.write("\t".join(str(i) for i in range(num_loci)) + "\n")

        # Process the rest of the file (including the first line)
        fin.seek(0)
        while True:
            line1 = fin.readline()
            line2 = fin.readline()
            if not line2:
                break  # EOF or malformed pair

            parts1 = line1.strip().split()
            parts2 = line2.strip().split()
            sample = parts1[0]

            if sample != parts2[0]:
                raise ValueError(f"Mismatched pair: {sample} vs {parts2[0]}")

            pop_id = popmap.get(sample)
            if pop_id is None:
                raise ValueError(f"Sample {sample} not found in popmap")

            parts1[1] = str(pop_id)
            parts2[1] = str(pop_id)

            fout.write("\t".join(parts1) + "\n")
            fout.write("\t".join(parts2) + "\n")


if __name__ == "__main__":
    main()
