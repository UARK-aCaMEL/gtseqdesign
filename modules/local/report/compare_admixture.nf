process COMPARE_ADMIXTURE {
    tag "$meta.id"
    label 'process_single'

    container "docker.io/tkchafin/plotly:1.1"

    input:
        tuple val(meta),  path(clumpp_pre,  stageAs: 'pre.q')
        tuple val(meta2), path(clumpp_post, stageAs: 'post.q')
        tuple val(meta3), path(inds,        stageAs: 'individuals.txt')
        tuple val(meta4), path(pops,        stageAs: 'populations.txt')

    output:
        path("*_regression_min_max.html"), emit: min_max_html
        path("*_entropy_comparison.html"), emit: entropy_html
        path("*_summary_metrics.csv"), emit: summary_csv
        path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    compare_admixture.py \\
        --q_pre pre.q \\
        --q_post post.q \\
        --individuals individuals.txt \\
        --populations populations.txt \\
        --prefix "comparison" \\
        ${args}

    plotly_version=\$(python3 -c 'import plotly; print(plotly.__version__)')

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plotly: \${plotly_version}
    END_VERSIONS
    """
}
