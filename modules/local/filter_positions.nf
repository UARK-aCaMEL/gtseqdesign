process FILTER_POSITIONS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5a/5acacb55c52bec97c61fd34ffa8721fce82ce823005793592e2a80bf71632cd0/data' :
        'community.wave.seqera.io/library/bcftools:1.21--4335bec1d7b44d11' }"

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(tbi)
    tuple val(meta3), path(chroms)

    output:
    tuple val(meta), path("${meta.id}.filtered.vcf.gz"), emit: vcf
    tuple val(meta), path("${meta.id}.filtered.vcf.gz.tbi"), emit: tbi, optional: true
    path "versions.yml", emit: versions

    script:
    def position = params.primer_length ?: 75

    """
    echo "📋 Building regions file using position cutoff: ${position}"
    awk -v pos=${position} 'BEGIN{OFS="\\t"} {print \$1, 1, pos - 1}' ${chroms} > regions.txt


    echo "🔍 Filtering VCF using bcftools view..."
    bcftools view \\
        -T ^regions.txt \
        --targets-overlap 1 \
        --output-type z \\
        --output ${meta.id}.filtered.vcf.gz \\
        --threads $task.cpus \\
        ${vcf}

    echo "📦 Indexing filtered VCF..."
    bcftools index ${meta.id}.filtered.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
