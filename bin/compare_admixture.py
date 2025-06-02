#!/usr/bin/env python3
import argparse
import pandas as pd
import numpy as np
from scipy.stats import entropy, linregress, spearmanr
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import os
import csv
from pathlib import Path

def parse_q_file(path):
    df = pd.read_csv(path, delim_whitespace=True, comment='#', header=None)
    q_start = df.columns[df.iloc[0] == ':'].tolist()[0] + 1
    q = df.iloc[:, q_start:].astype(float).values
    return q

def load_labels(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip()]

def compute_metrics(q_pre, q_post):
    k_equal = q_pre.shape[1] == q_post.shape[1]
    pre_max = q_pre.max(axis=1)
    pre_min = q_pre.min(axis=1)
    post_max = q_post.max(axis=1)
    post_min = q_post.min(axis=1)

    reg_max = linregress(pre_max, post_max)
    reg_min = linregress(pre_min, post_min)

    ent_pre = np.array([entropy(p) for p in q_pre])
    ent_post = np.array([entropy(p) for p in q_post])
    ent_corr = spearmanr(ent_pre, ent_post).correlation

    frac_conf_pre = np.mean(pre_max < 0.9)
    frac_conf_post = np.mean(post_max < 0.9)
    frac_conf_diff = frac_conf_post - frac_conf_pre

    mean_ent_pre = np.mean(ent_pre)
    mean_ent_post = np.mean(ent_post)
    delta_entropy = mean_ent_post - mean_ent_pre

    metrics = {
        "K Match": k_equal,
        "R² (Max Assignment)": reg_max.rvalue ** 2,
        "Slope (Max Assignment)": reg_max.slope,
        "R² (Min Assignment)": reg_min.rvalue ** 2,
        "Slope (Min Assignment)": reg_min.slope,
        "Spearman Correlation (Entropy)": ent_corr,
        "Mean Entropy (Pre)": mean_ent_pre,
        "Mean Entropy (Post)": mean_ent_post,
        "Delta Entropy": delta_entropy,
        "% Admixed (Pre)": frac_conf_pre,
        "% Admixed (Post)": frac_conf_post,
        "Delta % Admixed": frac_conf_diff
    }

    return metrics, pre_max, post_max, pre_min, post_min, ent_pre, ent_post

def make_entropy_plot(ent_pre, ent_post, individuals, populations, output_html):
    df = pd.DataFrame({
        "Pre_Entropy": ent_pre,
        "Post_Entropy": ent_post,
        "Individual": individuals,
        "Population": populations
    })
    fig = px.scatter(
        df, x="Pre_Entropy", y="Post_Entropy", hover_name="Individual", color="Population",
        labels={"Pre_Entropy": "Pre Entropy", "Post_Entropy": "Post Entropy"},
        title="Comparison of Assignment Entropy"
    )
    fig.write_html(output_html)

def make_side_by_side_regression(pre_max, post_max, pre_min, post_min, individuals, populations, output_html):
    df = pd.DataFrame({
        "Max_Pre": pre_max,
        "Max_Post": post_max,
        "Min_Pre": pre_min,
        "Min_Post": post_min,
        "Individual": individuals,
        "Population": populations
    })

    fig = make_subplots(rows=1, cols=2, subplot_titles=("Max Assignment", "Min Assignment"))

    for pop in df["Population"].unique():
        subdf = df[df["Population"] == pop]
        fig.add_trace(
            go.Scatter(
                x=subdf["Max_Pre"], y=subdf["Max_Post"],
                mode='markers', name=pop,
                marker=dict(size=6),
                text=subdf["Individual"], hoverinfo="text"
            ), row=1, col=1
        )
        fig.add_trace(
            go.Scatter(
                x=subdf["Min_Pre"], y=subdf["Min_Post"],
                mode='markers', name=pop,
                marker=dict(size=6),
                text=subdf["Individual"], hoverinfo="text",
                showlegend=False
            ), row=1, col=2
        )

    fig.update_xaxes(title_text="Pre", row=1, col=1)
    fig.update_yaxes(title_text="Post", row=1, col=1)
    fig.update_xaxes(title_text="Pre", row=1, col=2)
    fig.update_yaxes(title_text="Post", row=1, col=2)
    fig.update_layout(title_text="Regression Comparison of Max and Min Assignments", height=500, width=1000)

    fig.write_html(output_html)

def save_metrics_table(metrics, output_path):
    df = pd.DataFrame([metrics])
    df.to_csv(output_path if output_path.endswith(".csv") else output_path + ".csv",
            index=False,
            quoting=csv.QUOTE_ALL)

def main():
    parser = argparse.ArgumentParser(description="Compare pre- and post-filter Q matrices.")
    parser.add_argument("--q_pre", required=True)
    parser.add_argument("--q_post", required=True)
    parser.add_argument("--individuals", required=True)
    parser.add_argument("--populations", required=True)
    parser.add_argument("--prefix", required=True, help="Prefix for output files (may include directories)")
    args = parser.parse_args()

    prefix_path = Path(args.prefix)
    if prefix_path.parent != Path('.'):
        os.makedirs(prefix_path.parent, exist_ok=True)

    q_pre = parse_q_file(args.q_pre)
    q_post = parse_q_file(args.q_post)
    individuals = load_labels(args.individuals)
    populations = load_labels(args.populations)

    metrics, pre_max, post_max, pre_min, post_min, ent_pre, ent_post = compute_metrics(q_pre, q_post)

    print("=== Summary Metrics ===")
    for k, v in metrics.items():
        print(f"{k}: {v:.4f}" if isinstance(v, float) else f"{k}: {v}")

    make_entropy_plot(
        ent_pre, ent_post, individuals, populations,
        f"{args.prefix}_entropy_comparison.html"
    )

    make_side_by_side_regression(
        pre_max, post_max, pre_min, post_min,
        individuals, populations,
        f"{args.prefix}_regression_min_max.html"
    )

    save_metrics_table(metrics, f"{args.prefix}_summary_metrics.csv")

if __name__ == "__main__":
    main()
