//
// Rank loci using Rosenberg et al. 2003 importance indices
//
include { INFER_POPULATIONS } from '../../modules/local/infer_populations.nf'

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

    // Convert subsetted VCF to Structure format
    // and subset VCF to samples used for ADMIXTURE

    // Compute indices from Rosenberg et al. (2003)

    // // Fetch results for the best K value
    // BESTK(
    //     CVSUM.out.cv_output,
    //     DISTRUCT.out.best_results
    // )
    // ch_versions = ch_versions.mix( BESTK.out.versions )

    emit:
    versions     = ch_versions
}
