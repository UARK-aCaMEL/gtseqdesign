//
// Rank loci using Rosenberg et al. 2003 importance indices
//
include { PLOT_CV } from '../../modules/local/report/plot_cv.nf'
include { SAMPLE_SUMMARY } from '../../modules/local/report/sample_summary.nf'
include { COMPARE_ADMIXTURE } from '../../modules/local/report/compare_admixture.nf'
include { BCFTOOLS_QUERY as BCFTOOLS_QUERY_PRE } from '../../modules/local/bcftools_query.nf'
include { BCFTOOLS_QUERY as BCFTOOLS_QUERY_POST } from '../../modules/local/bcftools_query.nf'

workflow GENERATE_REPORT {
    take:
    vcf_pre
    tbi_pre
    vcf_post
    tbi_post
    cv_file
    snpio_pre
    snpio_post
    clumpp_pre
    clumpp_post
    inds
    pops

    main:
    ch_versions = Channel.empty()
    ch_mqc_files = Channel.empty()

    //CV plot
    PLOT_CV( cv_file )
    ch_versions = ch_versions.mix( PLOT_CV.out.versions )
    ch_mqc_files = ch_mqc_files.mix( PLOT_CV.out.cv_html )

    //Get individual lists from vcfs
    BCFTOOLS_QUERY_PRE( vcf_pre, tbi_pre )
    BCFTOOLS_QUERY_POST( vcf_post, tbi_post )
    ch_versions = ch_versions.mix( BCFTOOLS_QUERY_PRE.out.versions )

    //SNPio summary
    SAMPLE_SUMMARY(
        BCFTOOLS_QUERY_PRE.out.samples,
        BCFTOOLS_QUERY_POST.out.samples,
        snpio_pre,
        snpio_post
    )
    ch_mqc_files = ch_mqc_files.mix( SAMPLE_SUMMARY.out.summary_txt )
    ch_versions = ch_versions.mix( SAMPLE_SUMMARY.out.versions )

    //Admixture comparison
    COMPARE_ADMIXTURE(
        clumpp_pre,
        clumpp_post,
        inds,
        pops
    )
    ch_mqc_files = ch_mqc_files
        | mix( COMPARE_ADMIXTURE.out.min_max_html )
        | mix( COMPARE_ADMIXTURE.out.entropy_html )
        | mix( COMPARE_ADMIXTURE.out.summary_json )
    ch_versions = ch_versions.mix( COMPARE_ADMIXTURE.out.versions )

    //Admixture barplots

    //SNPio plots

    emit:
    mqc_files    = ch_mqc_files
    versions     = ch_versions
}
