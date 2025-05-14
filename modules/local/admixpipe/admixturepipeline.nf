process ADMIXTUREPIPELINE {
    tag "$meta.id"
    label 'process_large'

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mussmann/admixpipe:3.2' :
        'docker.io/mussmann/admixpipe:3.2'}"

    input:
    tuple val(meta), path(vcf)
    tuple val(meta), path(popmap)

    output:
    path "versions.yml", emit: versions

    script:
    def prefix = meta.id
    """
    # Dynamically add admixpipe paths if present in the container
    if [ -d /app ]; then
        export PATH="/app/bin:/app/scripts/python/admixturePipeline:\$PATH"
    fi

    admixturePipeline.py \\
        -m ${popmap} \\
        -v ${vcf} \\
        -n 8 \\
        -k 1 \\
        -K 3 \\
        -R 10 \\
        -c 10

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        AdmixPipe: \$(admixturePipeline.py --version 2>/dev/null || echo "3.2 (manual)")
    END_VERSIONS
    """
}
