process INFER_POPULATIONS {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::awk=5.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'biocontainers/gawk:5.1.0' }"

    input:
        tuple val(meta), path(clumpp)
        tuple val(meta2), path(inds)

    output:
        tuple val(meta), path("popmap.txt"), emit: popmap
        path "versions.yml", emit: versions

    script:
    """
    # Validate that both files have the same number of lines
    n_clumpp=\$(wc -l < ${clumpp})
    n_inds=\$(wc -l < ${inds})
    if [ "\$n_clumpp" -ne "\$n_inds" ]; then
        echo "❌ Mismatch: CLUMPP file has \$n_clumpp lines, inds file has \$n_inds lines" >&2
        exit 1
    fi

    # Clean CLUMPP: remove prefix, trim spaces, normalize spacing
    sed 's/^.*://; s/^ *//; s/ *\$//' ${clumpp} | sed 's/  */\t/g' > coeffs.tsv

    # Get column of max coefficient (1-based index)
    awk '
        {
            maxval = \$1
            maxidx = 1
            for (i = 2; i <= NF; i++) {
                if (\$i > maxval) {
                    maxval = \$i
                    maxidx = i
                }
            }
            print "K" maxidx
        }
    ' coeffs.tsv > assignments.txt

    # Merge IDs with assignments using awk (instead of paste)
    awk 'NR==FNR { ids[FNR] = \$1; next } { print ids[FNR] "\\t" \$1 }' ${inds} assignments.txt > popmap.txt

    # Log version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | grep -oP '(?<=GNU Awk ).*?(?=, )')
    END_VERSIONS
    """
}
