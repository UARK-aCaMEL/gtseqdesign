process RANK_LOCI {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::awk=5.1.0 coreutils=9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"

    input:
        tuple val(meta), path(metrics_file)

    output:
        tuple val(meta), path("top_loci.txt"), emit: top_loci
        path "versions.yml", emit: versions

    script:
    def metric = params.ranking_metric ?: "I_a"
    def candidates = params.max_candidates ?: 500
    """
    # Extract column index for ranking_metric
    metric_col=\$(awk -v metric="${metric}" '
        NR==1 {
            for (i=1; i<=NF; i++) {
                if (\$i == metric) {
                    print i;
                    exit;
                }
            }
            print "❌ Ranking metric \\"" metric "\\" not found in header." > "/dev/stderr"
            exit 1;
        }
    ' ${metrics_file})

    # Filter valid rows and cache to temp file
    head -n -2 ${metrics_file} \\
        | awk -v col=\$metric_col 'NR > 1 && \$col > -9998.0' > filtered_metrics.tsv

    # Count valid loci
    n_valid=\$(wc -l < filtered_metrics.tsv)

    if [ "\$n_valid" -lt "${candidates}" ]; then
        echo "⚠️  Only \$n_valid valid loci found, fewer than max_candidates=${candidates}" >&2
    fi

    # Write header
    echo -e "Index\\t${metric}" > top_loci.txt

    # Only run sort/head/awk if there's data
    if [ "\$n_valid" -gt 0 ]; then
        ( sort -k\${metric_col},\${metric_col}nr filtered_metrics.tsv \\
            | head -n ${candidates} \\
            | awk -v col=\${metric_col} '{ printf "%s\\t%s\\n", \$1, \$col }' >> top_loci.txt ) || true
    fi

    # Log version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | grep -oP '(?<=GNU Awk ).*?(?=, )')
    END_VERSIONS
    """
}
