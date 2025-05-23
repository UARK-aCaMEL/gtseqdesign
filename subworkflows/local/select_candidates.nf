//
// Rank loci using Rosenberg et al. 2003 importance indices
//
include { INFER_POPULATIONS } from '../../modules/local/infer_populations.nf'
include { SNPIO_CONVERT_STRUCTURE } from '../../modules/local/snpio/convert_structure.nf'
include { INFOCALC } from '../../modules/local/infocalc.nf'


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

    // // Fetch results for the best K value
    // BESTK(
    //     CVSUM.out.cv_output,
    //     DISTRUCT.out.best_results
    // )
    // ch_versions = ch_versions.mix( BESTK.out.versions )

    emit:
    versions     = ch_versions
}
