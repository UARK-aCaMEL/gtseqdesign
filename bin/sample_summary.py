#!/usr/bin/env python3
import pandas as pd
import argparse

def load_list(file):
    with open(file) as f:
        return [line.strip() for line in f if line.strip()]

def load_missingness(file):
    return pd.read_csv(file, header=None, names=["Missing"])

def compute_heterozygosity(file):
    df = pd.read_csv(file, low_memory=False)
    df = df.drop(columns=["Population"], errors="ignore")  # Drop if present
    locus_cols = df.columns.difference(["SampleID"])
    def het(row):
        alleles = row[locus_cols].dropna().astype(str)
        return sum(~alleles.isin(["A", "C", "G", "T", "N"])) / len(alleles) if len(alleles) > 0 else 0
    df["Heterozygosity"] = df.apply(het, axis=1)
    return df[["SampleID", "Heterozygosity"]].set_index("SampleID")

def main(args):
    inds_pre = load_list(args.inds_pre)
    inds_post = load_list(args.inds_post)

    df = pd.DataFrame({"Sample": inds_pre})
    df.set_index("Sample", inplace=True)

    miss_pre = load_missingness(args.miss_pre)
    df["Missing_Pre"] = miss_pre["Missing"].values

    miss_post = load_missingness(args.miss_post)
    miss_post_series = pd.Series(miss_post["Missing"].values, index=pd.Index(inds_post, name="Sample"))
    df["Missing_Post"] = miss_post_series.reindex(df.index)

    het_pre = compute_heterozygosity(args.het_pre)
    df["Heterozygosity_Pre"] = het_pre["Heterozygosity"]

    het_post = compute_heterozygosity(args.het_post)
    df["Heterozygosity_Post"] = het_post["Heterozygosity"].reindex(df.index)

    df.reset_index(inplace=True)
    df.to_csv(args.output, sep="\t", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--inds-pre", required=True)
    parser.add_argument("--inds-post", required=True)
    parser.add_argument("--miss-pre", required=True)
    parser.add_argument("--miss-post", required=True)
    parser.add_argument("--het-pre", required=True)
    parser.add_argument("--het-post", required=True)
    parser.add_argument("--output", required=True)
    main(parser.parse_args())
