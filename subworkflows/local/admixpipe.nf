//
// Run Steve Mussmann's Admixture Pipeline (AdmixPipe 3.0)
//

include { TABIX_BGZIP } from '../../modules/nf-core/tabix/bgzip/main'
include { TABIX_TABIX } from '../../modules/nf-core/tabix/tabix/main'
include { ADMIXTUREPIPELINE } from '../../modules/local/admixpipe/admixturepipeline.nf'
include { CLUMPAK } from '../../modules/local/admixpipe/submitclumpak.nf'
include { CVSUM } from '../../modules/local/admixpipe/cvsum.nf'
include { DISTRUCT } from '../../modules/local/admixpipe/distructrerun.nf'
include { UNZIP } from '../../modules/nf-core/unzip/main'

workflow ADMIXPIPE {
    take:
    vcf         // [ val(meta), *.vcf or *.vcf.gz ]
    ch_popmap   // [ val(meta), popmap file ]

    main:
    ch_versions = Channel.empty()

    // Branch input VCF by extension
    vcf
    | branch {
        vcfgz: it[1].name.endsWith('.vcf.gz')
        vcf:   it[1].name.endsWith('.vcf')
    }
    | set { ch_vcf_branch }

    // If input was vcf.gz, decompress
    TABIX_BGZIP( ch_vcf_branch.vcfgz )
    ch_versions = ch_versions.mix( TABIX_BGZIP.out.versions )

    // Combine uncompressed .vcf with bgzipped .vcf
    TABIX_BGZIP.out.output
        | mix( ch_vcf_branch.vcf )
        | set { ch_vcf }

    // Pass to ADMIXTURE pipeline
    ADMIXTUREPIPELINE(
        ch_vcf,
        ch_popmap
    )
    ch_versions = ch_versions.mix( ADMIXTUREPIPELINE.out.versions )

    ADMIXTUREPIPELINE.out.pfiles.view()

    // Run CLUMPAK
    CLUMPAK(
        ADMIXTUREPIPELINE.out.results,
        ADMIXTUREPIPELINE.out.inds,
        ADMIXTUREPIPELINE.out.pops
    )
    ch_versions = ch_versions.mix( CLUMPAK.out.versions )

    // Run Distruct
    DISTRUCT(
        ADMIXTUREPIPELINE.out.pfiles,
        ADMIXTUREPIPELINE.out.qfiles,
        ADMIXTUREPIPELINE.out.pops,
        ADMIXTUREPIPELINE.out.inds,
        ADMIXTUREPIPELINE.out.logs,
        CLUMPAK.out.output
    )

    // Compute best K from crossval
    CVSUM(
        DISTRUCT.out.cv,
        DISTRUCT.out.loglik
    )
    ch_versions = ch_versions.mix( CVSUM.out.versions )


    emit:
    // vcf      = ADMIXTUREPIPELINE.out.vcf      // [meta, vcf]
    // tbi      = ADMIXTUREPIPELINE.out.tbi      // [meta, tbi]
    // popmap   = ADMIXTUREPIPELINE.out.popmap   // [meta, popmap]
    versions = ch_versions                    // [versions.yml]
}
