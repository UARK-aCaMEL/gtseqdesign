#!/usr/bin/env python3
import pandas as pd
import argparse
import json
import re


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
        return (
            sum(~alleles.isin(["A", "C", "G", "T", "N"])) / len(alleles)
            if len(alleles) > 0
            else 0
        )

    df["Heterozygosity"] = df.apply(het, axis=1)
    return df[["SampleID", "Heterozygosity"]].set_index("SampleID")


def parse_html_header(path):
    """
    Parses HTML-style comment metadata into a dictionary.
    """
    meta = {}
    with open(path) as f:
        for line in f:
            match = re.match(r'^\s*([a-zA-Z0-9_]+):\s*"?(.*?)"?\s*$', line.strip("<!--> "))
            if match:
                key, value = match.groups()
                meta[key] = value
    return meta


def write_mqc_json(df, metadata, output_path):
    """
    Write a MultiQC-style table JSON with one row per sample,
    including all metadata fields from the header.
    """
    data_block = {
        str(row["Sample"]): {
            k: v for k, v in row.items() if k != "Sample"
        }
        for _, row in df.iterrows()
    }

    # Build base structure
    json_obj = {
        "data": data_block,
        "pconfig": {
            "id": metadata.get("id", metadata.get("section_name", "summary_plot")),
            "title": metadata.get("section_name", "Sample Summary Table"),
            "ylab": "Value",
            "xlab": "Metric",
            "xDecimals": False,
            "tt_label": "Metric",
            "min": 0,
            "max": 1,
            "scale": "YlGnBu"
        }
    }

    # Add all top-level metadata fields
    for key, value in metadata.items():
        if key != "pconfig":  # Already handled above
            json_obj[key] = value

    with open(output_path, "w") as f:
        json.dump(json_obj, f, indent=2)


def main(args):
    inds_pre = load_list(args.inds_pre)
    inds_post = load_list(args.inds_post)

    df = pd.DataFrame({"Sample": inds_pre})
    df.set_index("Sample", inplace=True)

    miss_pre = load_missingness(args.miss_pre)
    df["Missing_Pre"] = miss_pre["Missing"].values

    miss_post = load_missingness(args.miss_post)
    miss_post_series = pd.Series(
        miss_post["Missing"].values, index=pd.Index(inds_post, name="Sample")
    )
    df["Missing_Post"] = miss_post_series.reindex(df.index)

    het_pre = compute_heterozygosity(args.het_pre)
    df["Heterozygosity_Pre"] = het_pre["Heterozygosity"]

    het_post = compute_heterozygosity(args.het_post)
    df["Heterozygosity_Post"] = het_post["Heterozygosity"].reindex(df.index)

    df.reset_index(inplace=True)

    if args.header:
        metadata = parse_html_header(args.header)
        write_mqc_json(df, metadata, args.output)
    else:
        df.to_csv(args.output, sep="\t", index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--inds-pre", required=True)
    parser.add_argument("--inds-post", required=True)
    parser.add_argument("--miss-pre", required=True)
    parser.add_argument("--miss-post", required=True)
    parser.add_argument("--het-pre", required=True)
    parser.add_argument("--het-post", required=True)
    parser.add_argument("--output", required=True, help="Output JSON or TSV file")
    parser.add_argument("--header", required=False, help="Optional HTML header file to generate MultiQC JSON")
    main(parser.parse_args())
