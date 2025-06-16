#!/usr/bin/env python3
import re
import sys
import argparse
from pathlib import Path

import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.io as pio


def parse_template(template_file):
    """Extract MultiQC metadata from the <!-- … --> block."""
    text = Path(template_file).read_text()
    m = re.search(r"<!--(.*?)-->", text, re.DOTALL)
    if not m:
        raise ValueError(f"No <!--…--> block in {template_file}")
    meta = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            meta[k.strip()] = v.strip().strip("\"'")
    return meta


def build_comment(meta):
    lines = ["<!--"]
    for k, v in meta.items():
        lines.append(f'{k}: "{v}"')
    lines.append("-->")
    return "\n".join(lines)


def load_whitespace_table(path):
    """
    Reads a whitespace-delimited table and skips malformed lines.
    Returns DataFrame with first column=int, rest=float.
    """
    raw = Path(path).read_text().splitlines()
    header_idx = next(i for i, line in enumerate(raw)
                      if line.strip() and not line.lstrip().startswith("#"))
    cols = re.split(r"\s+", raw[header_idx].strip())
    records = []
    for line in raw[header_idx+1:]:
        s = line.strip()
        if not s or s.startswith("#"): continue
        parts = re.split(r"\s+", s)
        if not re.match(r"^\d+$", parts[0]) or len(parts) != len(cols):
            continue
        records.append(parts)
    df = pd.DataFrame(records, columns=cols)
    df[cols[0]] = df[cols[0]].astype(int)
    for c in cols[1:]:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    return df


def main():
    p = argparse.ArgumentParser(
        description="Plot overlaid-histogram + interactive scatter of loci metrics."
    )
    p.add_argument("--metrics",      required=True)
    p.add_argument("--top-loci",     required=True)
    p.add_argument("--out-hist",     required=True)
    p.add_argument("--out-scatter",  required=True)
    p.add_argument("--template-hist",    help="MultiQC header for histogram")
    p.add_argument("--template-scatter", help="MultiQC header for scatter")
    args = p.parse_args()

    # 1) Load data
    metrics_df  = load_whitespace_table(args.metrics)
    top_df      = load_whitespace_table(args.top_loci)
    idx = metrics_df.columns[0]
    metrics_df = metrics_df.sort_values(idx)
    sel_set = set(top_df.iloc[:,0])
    metrics_df['selected'] = metrics_df[idx].isin(sel_set)
    # filter negative
    metric_cols = [c for c in metrics_df.columns if c not in (idx, 'selected')]
    metrics_df = metrics_df[(metrics_df[metric_cols] >= 0).all(axis=1)]

    # 2) Histogram with common bins + dynamic axis label
    fig_h = go.Figure()
    buttons = []
    for i, col in enumerate(metric_cols):
        un = metrics_df.loc[~metrics_df.selected, col]
        se = metrics_df.loc[ metrics_df.selected, col]
        combined = pd.concat([un, se])
        mn, mx = combined.min(), combined.max()
        bins = dict(start=mn, end=mx, size=(mx-mn)/30 if mx>mn else 1)

        fig_h.add_trace(go.Histogram(
            x=un,
            name='Unselected',
            opacity=0.6,
            xbins=bins,
            visible=(i==0)
        ))
        fig_h.add_trace(go.Histogram(
            x=se,
            name='Selected',
            opacity=0.6,
            xbins=bins,
            visible=(i==0)
        ))

        vis = [False] * (len(metric_cols) * 2)
        vis[2*i] = True
        vis[2*i+1] = True
        buttons.append(dict(
            label=col,
            method='update',
            args=[
                {'visible': vis},
                {
                    'xaxis.title.text': col,
                    'yaxis.title.text': 'Count'
                }
            ]
        ))

    fig_h.update_layout(
        updatemenus=[dict(
            buttons=buttons,
            direction='down',
            showactive=True,
            x=0.1, y=1.15
        )],
        barmode='overlay',
        template='plotly_white',
        margin={'t':80,'b':40},
        xaxis=dict(title=metric_cols[0]),
        yaxis=dict(title='Count')
    )

    html_h = fig_h.to_html(full_html=False, include_plotlyjs='cdn')
    if args.template_hist:
        html_h = Path(args.template_hist).read_text() + html_h
    Path(args.out_hist).write_text(html_h)
    print(f'✅ {args.out_hist}')

    # 3) Interactive scatter: independent X/Y selectors with axis titles
    fig_s = go.Figure()
    x0, y0 = metric_cols[0], metric_cols[1] if len(metric_cols)>1 else metric_cols[0]
    df_u = metrics_df.loc[~metrics_df.selected]
    df_s = metrics_df.loc[ metrics_df.selected]
    fig_s.add_trace(go.Scatter(x=df_u[x0], y=df_u[y0], mode='markers', name='Unselected'))
    fig_s.add_trace(go.Scatter(x=df_s[x0], y=df_s[y0], mode='markers', name='Selected'))

    x_buttons = [dict(
        label=x,
        method='update',
        args=[
            {'x': [
                metrics_df.loc[~metrics_df.selected, x],
                metrics_df.loc[metrics_df.selected, x]
            ]},
            {
                'xaxis.title.text': x,
                'title.text': f'{x} vs {y0}'
            }
        ]
    ) for x in metric_cols]

    y_buttons = [dict(
        label=y,
        method='update',
        args=[
            {'y': [
                metrics_df.loc[~metrics_df.selected, y],
                metrics_df.loc[metrics_df.selected, y]
            ]},
            {
                'yaxis.title.text': y,
                'title.text': f'{x0} vs {y}'
            }
        ]
    ) for y in metric_cols]

    fig_s.update_layout(
        updatemenus=[
            dict(buttons=x_buttons, direction='down', x=0.1, y=1.15, showactive=True),
            dict(buttons=y_buttons, direction='down', x=0.4, y=1.15, showactive=True)
        ],
        xaxis=dict(title=x0),
        yaxis=dict(title=y0),
        template='plotly_white',
        margin={'t':80,'b':40}
    )

    html_s = fig_s.to_html(full_html=False, include_plotlyjs='cdn')
    if args.template_scatter:
        html_s = Path(args.template_scatter).read_text() + html_s
    Path(args.out_scatter).write_text(html_s)
    print(f'✅ {args.out_scatter}')

if __name__=='__main__':
    main()