process SNPIO_CONVERT_STRUCTURE {
    tag "$meta.id"
    label 'process_low'

    container 'docker.io/btmartin721/snpio:1.3.3'

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(tbi)
    tuple val(meta3), path(popmap)

    output:
    tuple val(meta), path("*.labeled.stru"), emit: structure
    tuple val(meta), path("*_output"), emit: snpio_output
    path "versions.yml",     emit: versions

    script:
    def args   = task.ext.args ?: ''

    """
    snpio_convert_structure.py \\
        --vcf ${vcf} \\
        --popmap ${popmap} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        SNPio: 1.3.3
    END_VERSIONS
    """
}
