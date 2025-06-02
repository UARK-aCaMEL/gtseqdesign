process SNPIO_PRE_FILTER {
    tag "$meta.id"
    label 'process_medium'

    container 'docker.io/btmartin721/snpio:1.3.3'

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(tbi)
    tuple val(meta3), path(popmap)

    output:
    tuple val(meta), path("${meta.id}.filter.nremover.vcf.gz"), emit: filtered_vcf
    tuple val(meta), path("${meta.id}.filter.nremover.vcf.gz.tbi"), emit: filtered_tbi
    tuple val(meta), path("*_output"), emit: snpio_output
    path "versions.yml",     emit: versions

    script:
    def args   = task.ext.args ?: ''

    """
    snpio_filter.py \\
        --vcf ${vcf} \\
        --popmap ${popmap} \\
        --ind_cov ${params.ind_cov} \\
        --flank_dist ${params.primer_length} \\
        --min_maf ${params.min_maf} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        SNPio: 1.3.3
    END_VERSIONS
    """
}
