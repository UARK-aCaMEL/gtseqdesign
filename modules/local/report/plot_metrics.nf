// nextflow.config (or your module .nf snippet)
process PLOT_METRICS {
    tag "$meta.id"
    label 'process_single'

    container "docker.io/tkchafin/plotly:1.1"

    input:
        tuple val(meta), path(metrics)
        tuple val(meta2), path(top_loci)

    output:
        path("metrics_hist_mqc.html"), emit: hist_html
        path("metrics_scatter_mqc.html"), emit: scatter_html
        path("versions.yml")             , emit: versions

    script:
    // choose defaults or override via params
    def metric     = params.ranking_metric    ?: "I_a"
    def candidates = params.max_candidates    ?: 500

    """
    plot_metrics.py \\
        --metrics      ${metrics}       \\
        --top-loci     ${top_loci}      \\
        --out-hist     metrics_hist_mqc.html     \\
        --out-scatter  metrics_scatter_mqc.html  \\
        --template-hist    ${baseDir}/assets/multiqc_metrics_histogram.html  \\
        --template-scatter ${baseDir}/assets/multiqc_metrics_pairwise.html \\
        ${task.ext.args ?: ''}

    plotly_version=\$(python3 -c 'import plotly; print(plotly.__version__)')

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plotly: \${plotly_version}
    END_VERSIONS
    """
}
