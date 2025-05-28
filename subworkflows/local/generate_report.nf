//
// Rank loci using Rosenberg et al. 2003 importance indices
//
include { PLOT_CV } from '../../modules/local/plot/plot_cv.nf'


workflow GENERATE_REPORT {
    take:
    cv_file

    main:
    ch_versions = Channel.empty()
    ch_mqc_files = Channel.empty()

    //CV plot
    PLOT_CV( cv_file )
    ch_versions = ch_versions.mix( PLOT_CV.out.versions )
    ch_mqc_files = ch_mqc_files.mix( PLOT_CV.out.cv_html )

    //Admixture barplots

    //SNPio plots

    emit:
    mqc_files    = ch_mqc_files
    versions     = ch_versions
}
