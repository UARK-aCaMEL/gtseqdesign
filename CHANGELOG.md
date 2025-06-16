# aCaMEL/acamel-gtseqdesign: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0 - Cemetery Gates - [16-05-2025]

Initial release of aCaMEL/acamel-gtseqdesign, created with the [nf-core](https://nf-co.re/) template.

### Enhancements & fixes

Initial release of aCaMEL/gtseqdesign :tada:

This release introduces a comprehensive Nextflow DSL2 pipeline for GT-seq (Genotyping-in-Thousands by sequencing) panel design from genotyped SNP data. The pipeline filters and scores SNPs based on their utility for distinguishing population structure, using information theory metrics from Rosenberg et al. (2003) and population structure results from ADMIXTURE.

### Parameters

| Old parameter | New parameter      |
| ------------- | ------------------ |
|               | --input            |
|               | --popmap           |
|               | --reference        |
|               | --maxk             |
|               | --ind_cov          |
|               | --snp_cov          |
|               | --primer_length    |
|               | --fully_contained  |
|               | --min_maf          |
|               | --max_candidates   |
|               | --ranking_metric   |

> **NB:** Parameter has been **updated** if both old and new parameter information is present. </br> **NB:** Parameter has been **added** if just the new parameter information is present. </br> **NB:** Parameter has been **removed** if new parameter information isn't present.

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference. Both `Docker` and `Singularity` containers are supported, as well as `Conda` environments.

| Dependency      | Old version | New version |
| --------------- | ----------- | ----------- |
| nextflow        |             | >=23.04.0   |
| multiqc         |             | 1.21        |
| htslib          |             | 1.21        |
| tabix           |             | 1.11        |
| bcftools        |             | 1.21        |
| coreutils       |             | 9.5         |
| gzip            |             | 1.13        |
| p7zip           |             | 16.02       |
| gawk            |             | 5.1.0       |
| perl            |             | 5.32        |
| snpio           |             | 1.3.21      |
| admixpipe       |             | 3.2         |
| admixture       |             | 1.30        |
| vcftools        |             | 0.1.16      |
| plink           |             | 20220402    |
| clumpak         |             | 1.1         |
| distruct        |             | 1.1         |
| plotly          |             | 1.1         |
| infocalc        |             | 1.1         |

> **NB:** Dependency has been **updated** if both old and new version information is present. </br> **NB:** Dependency has been **added** if just the new version information is present. </br> **NB:** Dependency has been **removed** if version information isn't present.
