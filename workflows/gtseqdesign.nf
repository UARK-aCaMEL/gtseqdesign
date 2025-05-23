/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_gtseqdesign_pipeline'
include { ADMIXPIPE as ADMIXPIPE_PRE } from '../subworkflows/local/admixpipe.nf'
include { SELECT_CANDIDATES } from '../subworkflows/local/select_candidates.nf'
include { SNPIO_PRE_FILTER as SNPIO_FILTER } from '../modules/local/snpio/pre_filter.nf'
include { LIST_CHROMS } from '../modules/local/list_chroms.nf'
include { GENERATE_CONSENSUS } from '../modules/local/generate_consensus.nf'
include { FILTER_POSITIONS } from '../modules/local/filter_positions.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GTSEQDESIGN {

    take:
    ch_vcf     // [meta, vcf]
    ch_tbi     // [meta, tbi]
    ch_popmap  // [meta, popmap]
    ch_reference

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // Process reference catalog if needed
    //
    ch_reference
        .branch {
            loci: it[1].name.endsWith('.loci')
            fasta: true
        }
        .set { ch_ref_to_process }
    GENERATE_CONSENSUS ( ch_ref_to_process.loci )
    ch_ref_ready = ch_ref_to_process.fasta
        | mix ( GENERATE_CONSENSUS.out.fasta )

    //
    // VCF pre-processing
    //
    // This step removes individuals with a large amount of missing data,
    // flanking variation within ${params.primer_length} distance, low variation,
    // and generates SNPio missingness reports
    SNPIO_FILTER(
        ch_vcf,
        ch_tbi,
        ch_popmap
    )
    ch_versions = ch_versions.mix(SNPIO_FILTER.out.versions)

    //
    // Run admixture pipeline on full (filtered) dataset
    //
    ADMIXPIPE_PRE(
        SNPIO_FILTER.out.filtered_vcf,
        ch_popmap
    )
    ch_versions = ch_versions.mix(ADMIXPIPE_PRE.out.versions)

    //
    // Denovo assembly handling
    //
    // Removes SNPs if they are not in the first ${params.primer_length}
    // number of bases (for denovo assembled loci only)
    // This forces primer+variant to be fully contained ONLY within the sequences locus
    // Otherwise, flanking sequence will be inferred using the provided reference
    if ( params.fully_contained ) {
        // Get list of denovo loci
        LIST_CHROMS( SNPIO_FILTER.out.filtered_vcf, SNPIO_FILTER.out.filtered_tbi )
        ch_versions = ch_versions.mix ( LIST_CHROMS.out.versions )

        FILTER_POSITIONS(
            SNPIO_FILTER.out.filtered_vcf,
            SNPIO_FILTER.out.filtered_tbi,
            LIST_CHROMS.out.chroms
        )
        ch_versions = ch_versions.mix ( FILTER_POSITIONS.out.versions )

        ch_candidates = FILTER_POSITIONS.out.vcf
        ch_candidates_tbi = FILTER_POSITIONS.out.tbi
    } else {
        ch_candidates = SNPIO_FILTER.out.filtered_vcf
        ch_candidates_tbi = SNPIO_FILTER.out.filtered_tbi
    }


    //
    // Compute locus-wise importance metrics
    //
    SELECT_CANDIDATES(
        SNPIO_FILTER.out.filtered_vcf,
        SNPIO_FILTER.out.filtered_tbi,
        ADMIXPIPE_PRE.out.inds,
        ADMIXPIPE_PRE.out.bestK_clumpp,
        ADMIXPIPE_PRE.out.bestK
    )


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
