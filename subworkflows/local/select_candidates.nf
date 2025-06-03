//
// Rank loci using Rosenberg et al. 2003 importance indices
//
include { INFER_POPULATIONS } from '../../modules/local/infer_populations.nf'
include { SNPIO_CONVERT_STRUCTURE } from '../../modules/local/snpio/convert_structure.nf'
include { INFOCALC } from '../../modules/local/infocalc.nf'
include { RANK_LOCI } from '../../modules/local/rank_loci.nf'
include { SUBSET_BY_INDEX } from '../../modules/local/subset_by_index.nf'


workflow SELECT_CANDIDATES {
    take:
    vcf         // [ val(meta), *.vcf or *.vcf.gz ]
    tbi         // [ val(meta), *.tbi ]
    inds        // [ val(meta), *.inds ]
    clumppfile  // [ val(meta), best_clumpp_indfile.out ]
    bestk       // [ val(meta), bestK.txt ]

    main:
    ch_versions = Channel.empty()

    // Assign samples to populations using ancestry coefficients
    // infer_populations
    INFER_POPULATIONS( clumppfile, inds )
    ch_versions = ch_versions.mix( INFER_POPULATIONS.out.versions )

    // Convert subsetted VCF to Structure format
    // and subset VCF to samples used for ADMIXTURE
    SNPIO_CONVERT_STRUCTURE(
        vcf,
        tbi,
        INFER_POPULATIONS.out.popmap
    )
    ch_versions = ch_versions.mix( SNPIO_CONVERT_STRUCTURE.out.versions )

    // Compute indices from Rosenberg et al. (2003)
    INFOCALC(
        SNPIO_CONVERT_STRUCTURE.out.structure,
        bestk
    )
    ch_versions = ch_versions.mix( INFOCALC.out.versions )

    // Get indices for top loci
    RANK_LOCI(
        INFOCALC.out.metrics
    )
    ch_versions = ch_versions.mix( INFOCALC.out.versions )

    // Subset selected loci and output new VCF
    SUBSET_BY_INDEX(
        vcf,
        tbi,
        RANK_LOCI.out.top_loci
    )

    emit:
    vcf          = SUBSET_BY_INDEX.out.vcf
    tbi          = SUBSET_BY_INDEX.out.tbi
    snpio_output = SNPIO_CONVERT_STRUCTURE.out.snpio_output
    versions     = ch_versions
}
