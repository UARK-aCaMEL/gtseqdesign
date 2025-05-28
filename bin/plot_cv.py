#!/usr/bin/env python3
import sys
import pandas as pd
import plotly
import plotly.graph_objs as go
import plotly.io as pio

# Metadata block to prepend to HTML
HTML_COMMENT = """<!--
parent_id: genetic_structure
id: 'cvp'
-->"""

def main(input_file, output_file="cvplot_mqc.html"):
    # Read input file (tab- or space-delimited)
    df = pd.read_csv(input_file, delim_whitespace=True)

    # Create Plotly figure
    fig = go.Figure()

    fig.add_trace(go.Scatter(
        x=df["K"],
        y=df["Mean"],
        error_y=dict(
            type="data",
            array=df["StDev"],
            visible=True
        ),
        mode="lines+markers",
        name="Mean CV Error",
        marker=dict(size=8),
        line=dict(width=2)
    ))

    fig.update_layout(
        title="Cross-validation Error by K",
        xaxis_title="K",
        yaxis_title="Mean CV Error",
        template="plotly_white"
    )

    # Generate HTML and prepend comment
    html = pio.to_html(fig, full_html=False, include_plotlyjs="cdn")
    with open(output_file, "w") as f:
        f.write(HTML_COMMENT + "\n" + html)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python plot_cv.py <cv_summary.txt>")
        sys.exit(1)

    main(sys.argv[1])
