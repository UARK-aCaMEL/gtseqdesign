//
// Rank loci using Rosenberg et al. 2003 importance indices
//
include { TABIX_BGZIP } from '../../modules/nf-core/tabix/bgzip/main'

workflow SELECT_CANDIDATES {
    // take:
    // vcf         // [ val(meta), *.vcf or *.vcf.gz ]
    // inds        // [ val(meta), *.inds ]
    // clumppfile  // [ val(meta), best_clumpp_indfile.out ]
    // bestk       // [ val(meta), bestK.txt ]

    main:
    ch_versions = Channel.empty()

    // Subset VCF to samples used for ADMIXTURE

    // Assign samples to populations using ancestry coefficients
    // infer_populations

    // Convert subsetted VCF to Structure format

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
