# aCaMEL/acamel-gtseqdesign: Output

## Introduction

This document describes the output produced by the aCaMEL/gtseqdesign pipeline. The pipeline generates a comprehensive set of outputs including filtered VCF files, population structure analyses, SNP ranking metrics, selected GT-seq panels, and detailed reports with visualizations.

The outputs are organized into several main directories based on the analysis stage:

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/gtseqdesign/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, see the
[pipeline documentation](https://nf-co.re/gtseqdesign/usage#understanding-the-outputs).

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Main Output Directories

### SNPio Filtering Results

<details markdown="1">
<summary>Output files</summary>

- `snpio/`
  - `snpio_filter/`
    - `*.filter.nremover.vcf.gz`: Filtered VCF file with low-quality SNPs and individuals removed
    - `*.filter.nremover.vcf.gz.tbi`: Index file for the filtered VCF
    - `*_output/`: Directory containing detailed SNPio filtering reports
      - `filtering_results_sankey*.html`: Interactive Sankey diagram showing filtering steps
      - `individual_missingness.csv`: Per-individual missing data statistics
      - `pop_individ_locus_missingness.csv`: Population-level missingness statistics
      - `snp_missingness.csv`: Per-SNP missing data statistics
      - `filtering_summary.txt`: Summary of filtering steps and retained data

</details>

The SNPio filtering step removes low-quality SNPs and individuals based on missing data thresholds, minor allele frequency, and flanking sequence requirements. The interactive Sankey diagram provides a visual summary of how many SNPs and individuals were retained at each filtering step.

### Population Structure Analysis (Pre-selection)

<details markdown="1">
<summary>Output files</summary>

- `admixpipe_pre/`
  - `admixturepipeline/`
    - `results.zip`: Complete ADMIXTURE results archive
    - `*.stdout`: ADMIXTURE run logs
    - `*.Q`: Ancestry coefficient files for each K value
    - `*.P`: Allele frequency files for each K value
    - `*_pops.txt`: Population assignments
    - `*_inds.txt`: Individual sample names
    - `*.map` and `*.ped`: PLINK format files
    - `*.qfiles.json`: Metadata for Q files
  - `clumpak/`
    - `clumpakOutput/`: CLUMPAK clustering results
  - `cvsum/`
    - `cv_file.MajClust.png`: Cross-validation plot
    - `loglikelihood_file.MajClust.png`: Log-likelihood plot
    - `cv_output.txt`: Cross-validation values for each K
    - `ll_output.txt`: Log-likelihood values for each K
  - `distruct/`
    - `MajorClusterRuns.txt`: Best clustering runs for each K
    - `*/best_results/`: Best ADMIXTURE results for each K
      - `ClumppIndFile.output.*`: CLUMPP-processed ancestry coefficients
    - `*.pdf`: DISTRUCT population structure plots
  - `bestk/`
    - `bestK.txt`: Optimal K value based on cross-validation
    - `best_clumpp_indfile.out`: Best ancestry coefficients for optimal K
    - `popmap.txt`: Inferred population assignments based on ancestry

</details>

The pre-selection population structure analysis uses ADMIXTURE to infer population structure from the filtered SNP dataset. Cross-validation is used to determine the optimal number of populations (K), and CLUMPAK aligns results across multiple runs. The results are visualized using DISTRUCT plots.

### SNP Selection and Ranking

<details markdown="1">
<summary>Output files</summary>

- `selected_loci/`
  - `snpio_convert_structure/`
    - `*.labeled.stru`: STRUCTURE format file for selected SNPs
    - `*_output/`: SNPio conversion reports
  - `infocalc/`
    - `locus_metrics.txt`: Information theory metrics for each SNP
      - Columns include: Locus, I_n, I_a, ORCA[1-allele], ORCA[2-allele]
  - `rank_loci/`
    - `top_loci.txt`: Top-ranked SNPs selected for GT-seq panel
      - Contains SNP index and ranking metric value
  - `subset_by_index/`
    - `*.selected.vcf.gz`: VCF file containing only selected SNPs
    - `*.selected.vcf.gz.tbi`: Index for selected SNPs VCF

</details>

This section contains the core GT-seq panel selection results. SNPs are ranked using information theory metrics from Rosenberg et al. (2003), which measure how well each SNP distinguishes between populations. The top-ranked SNPs (up to `max_candidates`) are selected for the final GT-seq panel.

### Population Structure Analysis (Post-selection)

<details markdown="1">
<summary>Output files</summary>

- `admixpipe_post/`
  - Similar structure to `admixpipe_pre/` but analyzing only the selected SNPs
  - Allows comparison of population structure resolution before and after SNP selection

</details>

The post-selection analysis re-runs population structure inference using only the selected GT-seq SNPs to evaluate how well the reduced panel captures the original population structure.

### Comprehensive Reports

<details markdown="1">
<summary>Output files</summary>

- `report/`
  - `multiqc_report.html`: Comprehensive interactive report with all analyses
    - Cross-validation plots for optimal K selection
    - Population structure bar plots (pre- and post-selection)
    - SNP filtering summary with Sankey diagrams
    - Information theory metrics distributions and scatter plots
    - Sample statistics and missing data summaries
    - Admixture coefficient comparisons
  - `multiqc_data/`: Supporting data files for the report
  - `multiqc_plots/`: Individual plot files (if generated)

</details>

The MultiQC report provides a comprehensive overview of the entire analysis, allowing users to evaluate the quality of their GT-seq panel design and understand the trade-offs between panel size and population structure resolution.

### Pipeline Information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - `execution_report_*.html`: Nextflow execution report
  - `execution_timeline_*.html`: Timeline of process execution
  - `execution_trace_*.txt`: Detailed trace of all processes
  - `pipeline_dag_*.html`: Directed acyclic graph of the pipeline
  - `nf_core_pipeline_software_mqc_versions.yml`: Software versions used
  - `params_*.json`: Parameters used for the pipeline run

</details>

These files provide detailed information about the pipeline execution, including resource usage, timing, and software versions for reproducibility.

## Optional Outputs

### Pseudo-reference Generation

<details markdown="1">
<summary>Output files</summary>

- `psuedoreference/` (only if `.loci` file provided as reference)
  - `consensus.fa`: Consensus sequences generated from RAD loci

</details>

If a `.loci` file (from ipyrad) is provided instead of a reference genome, the pipeline will generate consensus sequences for use in downstream analyses.

### Position Filtering

<details markdown="1">
<summary>Output files</summary>

- `candidates/` (only if `--fully_contained true`)
  - `*.filtered.vcf.gz`: VCF with SNPs filtered by position within loci
  - `*.filtered.vcf.gz.tbi`: Index for position-filtered VCF

</details>

When `--fully_contained` is enabled, SNPs are filtered to ensure both primers and variants fit within the original sequenced loci (important for de novo RAD-seq datasets).

## Key Output Files for GT-seq Design

The most important files for GT-seq panel design are:

1. **`selected_loci/subset_by_index/*.selected.vcf.gz`**: The final VCF containing your selected GT-seq SNPs
2. **`selected_loci/rank_loci/top_loci.txt`**: List of top-ranked SNPs with their information content scores
3. **`selected_loci/infocalc/locus_metrics.txt`**: Complete ranking metrics for all SNPs
4. **`report/multiqc_report.html`**: Comprehensive analysis report comparing pre- and post- assay design
5. **`admixpipe_post/bestk/bestK.txt`**: Optimal number of populations for the filtered dataset

## Interpreting Results

### SNP Selection Quality

- **Information Content Scores**: Higher values indicate SNPs that better distinguish populations
  - `I_n`: Informativeness for assignment - how well a SNP assigns individuals to populations
  - `I_a`: Informativeness for ancestry - how informative a SNP is for ancestry proportions
  - `ORCA`: One/Two-allele ORCA metrics for population assignment

### Population Structure Resolution

- Compare the population structure plots before and after SNP selection
- The selected panel should maintain the major population clusters while using fewer SNPs
- Cross-validation plots help determine if the optimal K is consistent between full and reduced datasets

### Panel Size Considerations

- The pipeline selects up to `max_candidates` SNPs (default: 500)
- Consider the trade-off between panel size, cost, and population structure resolution
- The MultiQC report includes metrics to help evaluate this trade-off

## Troubleshooting

### Common Issues

1. **Low number of selected SNPs**: Check filtering parameters (`min_maf`, `ind_cov`, `snp_cov`)
2. **Poor population structure resolution**: Consider increasing `max_candidates` or adjusting filtering thresholds
3. **Inconsistent K values**: May indicate population structure is not well-defined in your dataset

### Quality Control

- Review the Sankey diagram to understand how many SNPs were filtered at each step
- Check individual and SNP missingness plots to identify potential data quality issues
- Compare pre- and post-selection population structure to ensure important patterns are preserved

## Citation

If you use aCaMEL/gtseqdesign for your research, please cite:

- The pipeline: [DOI to be added]
- Key methods: Rosenberg et al. (2003) for information theory metrics, Alexander et al. (2009) for ADMIXTURE
- See `CITATIONS.md` for a complete list of tools and references
