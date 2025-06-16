process INFOCALC{
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::perl=5.32"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.32' :
        'biocontainers/perl:5.32' }"

    input:
        tuple val(meta), path(structure)
        tuple val(meta2), path(bestk_file)

    output:
        tuple val(meta), path("locus_metrics.txt"), emit: metrics
        path "versions.yml", emit: versions

    script:
    def args   = task.ext.args ?: ''
    """
    # Read best K
    K=\$(cat ${bestk_file})

    # Run infocalc.pl (assumes it's in PATH or cwd)
    infocalc.pl \\
    -input ${structure} \\
    -column 2 \\
    -numpops \$K \\
    -output "locus_metrics.txt" \\
    ${args}

    # Log version manually
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        infocalc: 1.1
        perl: \$(perl -v | grep "v5" | head -n1 | sed 's/^.*(v/v/' | sed 's/).*//')
    END_VERSIONS
    """
}
