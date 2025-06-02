process BCFTOOLS_QUERY {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5a/5acacb55c52bec97c61fd34ffa8721fce82ce823005793592e2a80bf71632cd0/data' :
        'community.wave.seqera.io/library/bcftools:1.21--4335bec1d7b44d11' }"

    input:
        tuple val(meta), path(vcf)
        tuple val(meta2), path(index)

    output:
        tuple val(meta), path("${meta.id}.samples.txt"), emit: samples
        path "versions.yml", emit: versions

    script:
    """
    echo "📋 Extracting sample names from: ${vcf}"
    bcftools query -l ${vcf} > ${meta.id}.samples.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
