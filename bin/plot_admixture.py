#!/usr/bin/env python3
import pandas as pd
import plotly.express as px
import argparse


def load_data(qmat_file, ind_file, pop_file):
    # Parse Q matrix (after ":")
    q_raw = pd.read_csv(qmat_file, sep=":", header=None)
    q_df = q_raw[1].str.strip().str.split(expand=True).astype(float)

    # Load sample IDs and populations
    individuals = pd.read_csv(ind_file, header=None)[0]
    populations = pd.read_csv(pop_file, header=None)[0]

    # Sanity check
    if not (len(individuals) == len(populations) == len(q_df)):
        raise ValueError("Mismatch in number of rows across input files.")

    q_df.columns = [f"Cluster {i+1}" for i in range(q_df.shape[1])]
    q_df["Individual"] = individuals
    q_df["Population"] = populations

    return q_df


def make_plot(df, output_html):
    df_long = df.melt(
        id_vars=["Individual", "Population"],
        var_name="Cluster",
        value_name="Proportion",
    )

    # Maintain sample order
    df_long["Individual"] = pd.Categorical(
        df_long["Individual"], categories=df["Individual"], ordered=True
    )

    # Define color palette
    num_clusters = df.shape[1] - 2
    color_seq = (
        px.colors.qualitative.Set3
        if num_clusters <= 12
        else px.colors.sample_colorscale(
            "Turbo", [i / num_clusters for i in range(num_clusters)]
        )
    )

    # Generate stacked barplot
    fig = px.bar(
        df_long,
        x="Individual",
        y="Proportion",
        color="Cluster",
        color_discrete_sequence=color_seq,
        hover_data=["Individual", "Population", "Cluster", "Proportion"],
    )

    # Add population tick labels (group centers)
    pop_counts = df.groupby("Population").size()
    pop_positions = pop_counts.cumsum() - pop_counts / 2
    fig.update_layout(
        xaxis=dict(
            tickmode="array",
            tickvals=pop_positions.values,
            ticktext=pop_positions.index,
        ),
        barmode="stack",
        xaxis_title="Population",
        yaxis_title="Ancestry Proportion",
        title="ADMIXTURE Ancestry Barplot",
        margin=dict(t=60, b=100),
        xaxis_tickangle=90,
        legend_title="Cluster",
    )

    fig.write_html(output_html, include_plotlyjs="cdn")
    print(f"✅ Plot saved to: {output_html}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate an interactive ADMIXTURE barplot with Plotly."
    )
    parser.add_argument(
        "--qmat", required=True, help="Q matrix file (colon-separated ancestry values)"
    )
    parser.add_argument(
        "--indfile", required=True, help="File with sample IDs (one per line)"
    )
    parser.add_argument(
        "--popfile", required=True, help="File with population IDs (one per line)"
    )
    parser.add_argument("--out", required=True, help="Output HTML file path")

    args = parser.parse_args()
    df = load_data(args.qmat, args.indfile, args.popfile)
    make_plot(df, args.out)
