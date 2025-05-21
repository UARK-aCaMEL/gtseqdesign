process GENERATE_CONSENSUS {
    tag "$meta.id"
    label 'process_small'

    container 'docker.io/btmartin721/snpio:1.3.3'

    input:
        tuple val(meta), path(loci)

    output:
        tuple val(meta), path('consensus.fa')                     , emit: fasta

    script:
    """
    loci_to_consensus.py \\
    --input ${loci} \\
    --prefix "RAD" \\
    --output "consensus.fa"
    """
}
