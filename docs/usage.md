# aCaMEL/gtseqdesign: Usage

## Introduction

The **aCaMEL/gtseqdesign** pipeline is designed for developing GT-seq (Genotyping-in-Thousands by sequencing) panels from existing SNP datasets. GT-seq is a targeted sequencing approach that allows for cost-effective genotyping of hundreds to thousands of SNPs across many individuals, making it ideal for population genomics, conservation genetics, and breeding applications.

This pipeline automates the process of selecting the most informative SNPs from a larger dataset by:

1. **Filtering SNPs** based on quality metrics, missing data thresholds, and minor allele frequencies
2. **Inferring population structure** using ADMIXTURE to identify genetic clusters
3. **Ranking SNPs** using information theory metrics from Rosenberg et al. (2003) to identify loci that best distinguish populations
4. **Selecting optimal panels** of SNPs for GT-seq assay design
5. **Generating comprehensive reports** with visualizations and quality metrics

The pipeline is particularly useful for researchers who have existing RAD-seq, ddRAD-seq, or whole-genome sequencing data and want to develop targeted sequencing panels for larger-scale population studies.

### Key Features

- **Automated SNP filtering** with customizable thresholds for coverage, missing data, and allele frequencies
- **Population structure inference** using ADMIXTURE with cross-validation to determine optimal K
- **Information-theoretic SNP ranking** using multiple metrics (I_n, I_a, ORCA)
- **Flexible primer design considerations** for different sequencing platforms
- **Comprehensive reporting** with interactive plots and quality metrics
- **Support for both reference-based and de novo datasets**

## Inputs

The pipeline requires three main input files:

### Required Inputs

#### 1. VCF File (`--input`)

A Variant Call Format (VCF) file containing SNP genotypes for all samples. The file can be either uncompressed (`.vcf`) or compressed (`.vcf.gz`).

**Requirements:**

- Must contain biallelic SNPs only
- Should include all samples you want to consider for panel design
- Must have proper VCF formatting with CHROM, POS, REF, ALT columns
- Genotypes should be in standard VCF format (0/0, 0/1, 1/1, ./.)

**Example:**

```bash
--input /path/to/your/genotypes.vcf.gz
```

#### 2. Population Map (`--popmap`)

A tab-delimited file mapping sample IDs to population assignments. This file is used for initial population structure analysis.

**Format:**

- Column 1: Sample ID (must match VCF sample names exactly)
- Column 2: Population ID
- No header row
- Tab-separated

**Example file content:**

```
Sample001    PopA
Sample002    PopA
Sample003    PopB
Sample004    PopB
```

**Example parameter:**

```bash
--popmap /path/to/your/popmap.txt
```

#### 3. Reference Genome (`--reference`)

A reference genome in FASTA format, used for extracting flanking sequences around selected SNPs for primer design.

**Requirements:**

- FASTA format (`.fa`, `.fasta`, `.fna`)
- Can be compressed (`.gz`) or uncompressed
- Chromosome/scaffold names must match those in the VCF file
- Should be the same reference used for variant calling

**Example:**

```bash
--reference /path/to/reference_genome.fasta.gz
```

### Optional Inputs

#### MultiQC Configuration (`--multiqc_config`)

Custom MultiQC configuration file to modify report appearance and content.

**Example:**

```bash
--multiqc_config /path/to/custom_multiqc_config.yml
```

## Parameters

### Core Analysis Parameters

#### `--maxk` (default: 10)

Maximum number of populations (K) to test in ADMIXTURE analysis. The pipeline will test K values from 1 to this maximum and select the optimal K based on cross-validation.

**Example:**

```bash
--maxk 8
```

#### `--ranking_metric` (default: "I_a")

The information theory metric used to rank SNPs for panel selection. Must be one of:

- `I_n`: Informativeness for assignment (Rosenberg et al. 2003)
- `I_a`: Informativeness for ancestry (Rosenberg et al. 2003)
- `ORCA[1-allele]`: One-allele ORCA metric
- `ORCA[2-allele]`: Two-allele ORCA metric

**Example:**

```bash
--ranking_metric "I_n"
```

#### `--max_candidates` (default: 500)

Maximum number of top-ranked SNPs to select for the final GT-seq panel.

**Example:**

```bash
--max_candidates 300
```

### SNP Filtering Parameters

#### `--ind_cov` (default: 0.9)

Minimum proportion of individuals that must have genotype data for a SNP to be retained (individual coverage threshold).

**Example:**

```bash
--ind_cov 0.8  # Require genotype data in at least 80% of individuals
```

#### `--snp_cov` (default: 0.9)

Minimum proportion of SNPs that must have genotype data for an individual to be retained (SNP coverage threshold).

**Example:**

```bash
--snp_cov 0.85  # Require individuals to have data at 85% of SNPs
```

#### `--min_maf` (default: 0.05)

Minimum minor allele frequency. SNPs with MAF below this threshold will be filtered out.

**Example:**

```bash
--min_maf 0.01  # Keep SNPs with MAF >= 1%
```

### Primer Design Parameters

#### `--primer_length` (default: 75)

Number of invariant bases required upstream of a candidate SNP for primer design. This parameter affects which SNPs are considered suitable for GT-seq assay design.

**Example:**

```bash
--primer_length 100  # Require 100bp of invariant sequence upstream
```

#### `--fully_contained` (default: false)

Set to true if you want both the primer and variant to be fully contained within the sequenced locus. This is particularly relevant for de novo RAD-seq or ddRAD-seq datasets where you want to ensure the entire assay fits within the original sequenced fragment.

**Example:**

```bash
--fully_contained true
```

### Output Parameters

#### `--outdir` (required)

Directory where all pipeline outputs will be saved.

**Example:**

```bash
--outdir /path/to/results
```

#### `--publish_dir_mode` (default: 'copy')

Method for publishing output files. Options include 'copy', 'symlink', 'link', etc.

**Example:**

```bash
--publish_dir_mode 'symlink'
```

### Resource Parameters

#### `--max_memory` (default: '128.GB')

Maximum memory that can be used by any single process.

#### `--max_cpus` (default: 16)

Maximum number of CPUs that can be used by any single process.

#### `--max_time` (default: '240.h')

Maximum time that any single process can run.

**Example:**

```bash
--max_memory '64.GB' --max_cpus 8 --max_time '48.h'
```

### Example Command

Here's a complete example command with commonly used parameters:

```bash
nextflow run aCaMEL/gtseqdesign \
    --input genotypes.vcf.gz \
    --popmap populations.txt \
    --reference genome.fasta.gz \
    --outdir results \
    --maxk 6 \
    --max_candidates 400 \
    --min_maf 0.02 \
    --ind_cov 0.85 \
    --primer_length 80 \
    --ranking_metric "I_a" \
    -profile docker
```

This command will:

- Process SNPs from `genotypes.vcf.gz`
- Use population assignments from `populations.txt`
- Extract flanking sequences from `genome.fasta.gz`
- Test population structure with K=1 to K=6
- Select the top 400 most informative SNPs
- Filter SNPs with MAF < 2%
- Require genotype data in ≥85% of individuals
- Require 80bp of invariant sequence upstream of each SNP
- Use the I_a metric for ranking SNPs
- Run using Docker containers

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run UARK-aCaMEL/gtseqdesign --input genotypes.vcf --outdir ./results --reference reference.fasta --popmap popmap.tsv -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

:::warning
Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).
:::

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run aCaMEL/gtseqdesign -profile docker -params-file params.yaml
```

with `params.yaml` containing:

```yaml
input: './genotypes.vcf'
outdir: './results/'
reference: 'referance.fasta'
popmap: 'popmap.tsv'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull aCaMEL/gtseqdesign
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [aCaMEL/gtseqdesign releases page](https://github.com/aCaMEL/gtseqdesign/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
:::

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

:::info
We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.
:::

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Azure Resource Requests

To be used with the `azurebatch` profile by specifying the `-profile azurebatch`.
We recommend providing a compute `params.vm_type` of `Standard_D16_v3` VMs by default but these options can be changed if required.

Note that the choice of VM size depends on your quota and the overall workload during the analysis.
For a thorough list, please refer the [Azure Sizes for virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
