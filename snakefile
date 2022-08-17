#!/bin/python 

import pandas as pd
import numpy as np
import os
import pdb

# For debugging
# pdb.set_trace()

# Call as 
# /home/panten/miniconda3/bin/snakemake -s snakefile_old --cluster "bsub -n16 -q verylong -R rusage[mem=200GB]"
# -j30 --use-envmodules -n

# Define parent dir (could be done automatically)
parent_dir = "/omics/groups/OE0538/internal/users/panten/projects/f1_multiOmics/snakemake_alignment/"

# Give paths to cellranger references (could be in config)
reference_cast="/omics/groups/OE0538/internal/users/panten/projects/genome_files/CellRangerRNA/B6_masked_cast/"
reference_spret="/omics/groups/OE0538/internal/users/panten/projects/genome_files/CellRangerRNA/B6_masked_spret/"

# Give paths to SNP files (for allelic mapping only)
snps_cast="/icgc/dkfzlsdf/analysis/B080/crg/panten/Spermatogenesis/JP_Spermatogenesis2020/misc_files/snp_files/wasp_processed/"
snps_spret="/omics/groups/OE0538/internal/users/panten/projects/f1_multiOmics/make_masked_genomes/b6_mask_spret/wasp_processed/"

# Give the paths to the odcf files
path_b6_cas="/omics/odcf/project/OE0538/DO-0009/f1_b6_mcas/sequencing/10x_scRNA_sequencing/core/"
path_cas_b6="/omics/odcf/project/OE0538/DO-0009/f1_mcas_b6/sequencing/10x_scRNA_sequencing/core/"

# Read the sample information as exported from the ODCF database image
# We also subset on the experiments we need as given by the ILSE ID
ILSE_INCLUDE = [23028, 23364, 23766, 23963, 24338, 24703, 24886, 28387]
metadata_b6_mcas=pd.read_csv("./2022-06-22-16-20-01_OE0538_DO-0009_F1_B6_mcas-data-files.csv")
metadata_mcas_b6=pd.read_csv("./2022-06-22-16-20-01_OE0538_DO-0009_F1_mcas_B6-data-files.csv")
metadata_b6_mcas=pd.concat([metadata_b6_mcas, metadata_mcas_b6])
metadata_b6_mcas=metadata_b6_mcas[metadata_b6_mcas["ILSE_NO"].isin(ILSE_INCLUDE)]
INDIVIDUALS = metadata_b6_mcas["Sample ID"].unique()

# Define a dictionary with genomes for the different strains for snakemake to call
reference_dict = {"spret/eij x c57bl6-ly5.1(4791)" : reference_spret, "c57bl6-ly5.1 x cast/eij" : reference_cast}
sample_to_genome = {str(metadata_b6_mcas["Sample ID"].iloc[i]): reference_dict[metadata_b6_mcas["STRAIN"].iloc[i]] for i in
        range(metadata_b6_mcas.shape[0])}

# Same for the SNPs (for allelic mapping only)
snpdir_dict = {"spret/eij x c57bl6-ly5.1(4791)" : snps_spret, "c57bl6-ly5.1 x cast/eij" : snps_cast}
sample_to_snp = {str(metadata_b6_mcas["Sample ID"].iloc[i]): snpdir_dict[metadata_b6_mcas["STRAIN"].iloc[i]] for i in
        range(metadata_b6_mcas.shape[0])}

# Define final targets for rule all
all_targets = ["cellranger_output/" + str(ind) + "/outs/allele_specific_counts/ase_feature_matrix/" for ind in INDIVIDUALS]

rule all:
    input:
        all_targets

# Create a folder linked_files, create one folder per sample in there which contains links to all sample fastqs
# The format of the link names prepares the samples for cellranger: 
# {SAMPLE_ID}_{S1-4}_{LaneNr}_{R1|2}_001.fastq.gz
# I didnt have multiple lanes per sample, so this would need to be added
rule link_files:
    output: directory("linked_files/{sample}/")
    run:
        INDIVIDUAL = wildcards.sample
        fastqs_R1 = metadata_b6_mcas[metadata_b6_mcas["Sample ID"] == int(INDIVIDUAL)]["FastQ Path"]
        fastqs_R2 = metadata_b6_mcas[metadata_b6_mcas["Sample ID"] == int(INDIVIDUAL)]["FastQ Path"]

        fastqs_R1 = fastqs_R1[fastqs_R1.str.contains("R1")]
        fastqs_R2 = fastqs_R2[fastqs_R2.str.contains("R2")]

        individual_dir = "linked_files/" + str(INDIVIDUAL) + "/"

        if not os.path.exists(individual_dir):
            os.makedirs(individual_dir)

        for i in np.arange(1, len(fastqs_R1) + 1):
            print(i)
            file_here = fastqs_R1.iloc[i - 1]
            print(file_here)
            os.system("ln -s " + file_here + " " +  parent_dir + "/linked_files/" + str(INDIVIDUAL) + "/" + str(INDIVIDUAL) + "_S" + str(i) + "_L001_R1_001.fastq.gz")

    
        for i in np.arange(1, len(fastqs_R2) + 1):
            print(i)
            file_here = fastqs_R2.iloc[i - 1]
            print(file_here)
            os.system("ln -s " + file_here + " " +  parent_dir + "/linked_files/" + str(INDIVIDUAL) + "/" + str(INDIVIDUAL) + "_S" + str(i) + "_L001_R2_001.fastq.gz")


# Run cellranger for each sample in linked_files and put output into new folder cellranger_output
# Note that I'm using --include-introns, you might now want to do that
rule cellranger_sample:
    input: "linked_files/{sample}/"
    output: 
        touch("cellranger_output/cellranger_done/{sample}.done")
    params:
        genome = lambda wildcards: sample_to_genome[wildcards.sample]
    envmodules:
        "cellranger/6.1.1",
    shell: 
        """
        cd cellranger_output
        cellranger count \
            --id {wildcards.sample} \
            --transcriptome {params.genome} \
            --fastqs ../{input} \
            --localcores=16 \
            --include-introns \
            --sample {wildcards.sample}
        """

rule intersecting_snps:
    input:
        "cellranger_output/cellranger_done/{sample}.done"
#        "cellranger_output/{sample}/outs/possorted_genome_bam.bam"
    output: 
        "cellranger_output/{sample}/outs/allele_specific_counts/possorted_genome_bam.keep.bam"
    params: 
        snpdir = lambda wildcards: sample_to_snp[wildcards.sample], 
        output_dir =  "cellranger_output/{sample}/outs/allele_specific_counts/",
        input_file = "cellranger_output/{sample}/outs/possorted_genome_bam.bam"
    shell:
        """
        ~/to_omics/Standalone_Software/miniconda3/bin/python \
            ~/to_omics/Standalone_Software/WASP-master/mapping/find_intersecting_snps_10x.py \
            --is_sorted \
            --output_dir {params.output_dir} \
            --snp_dir {params.snpdir} \
            {params.input_file}
        """

rule process_bam:
    input: 
        bam_file = "cellranger_output/{sample}/outs/allele_specific_counts/possorted_genome_bam.keep.bam", 
    output: 
        "cellranger_output/{sample}/outs/allele_specific_counts/possorted_genome_bam.keep.bam.bam"
    envmodules:
        "samtools"
    shell:
        """
            samtools view -b {input.bam_file} > {output}
            samtools index {output}
        """

#rule realign_bam:
 #   input: "cellranger_output/{sample}/outs/allele_specific_counts/possorted_genome_bam.remap.fq.gz"
 #   output: directory("cellranger_output/{sample}/outs/allele_specific_counts/star_realign/")
 #   params:
 #       genome_STAR = lambda wildcards: sample_to_genome[wildcards.sample]
 #   envmodules:
 #       "STAR/2.5.1b"
 #   shell:
 #       """
 #       mkdir {output}
 #       STAR \
 #           --runMode alignReads \
 #           --genomeDir {params.genome_STAR}/star/ \
 #           --outSAMmultNmax 1 \
 #           --outSAMtype SAM \
 #           --readFilesCommand zcat \
 #           --outFileNamePrefix {output}/ \
 #           --readFilesIn {input}
#        """
#rule wasp_filter_reads:
#    input: 
#        snp_reads = "cellranger_output/{sample}/outs/allele_specific_counts/possorted_genome_bam.to.remap.bam",
#        remapped_reads = "cellranger_output/{sample}/outs/allele_specific_counts/star_realign/Aligned.out.sam"
#    output: "cellranger_output/{sample}/outs/allele_specific_counts/usable_reads.bam"
#    shell:
#        """
#        ~/miniconda3/bin/python ~/to_omics/Standalone_Software/WASP-master/mapping/filter_remapped_reads.py \
#            {input.snp_reads} \
#            {input.remapped_reads} \
#            {output}
 #       """

rule count_allelespecific_reads:
    input: "cellranger_output/{sample}/outs/allele_specific_counts/possorted_genome_bam.keep.bam.bam"
    output: directory("cellranger_output/{sample}/outs/allele_specific_counts/ase_feature_matrix/")
    params: 
        "cellranger_output/{sample}/"
    shell:
        """
            ~/miniconda3/bin/python count_ase_10x.py {params}
        """

#rule collect_outputs:
#    input: expand("cellranger_output/{sample}/outs/", samples = SAMPLES)
#    output: directory("all_outputs")
#    shell:
#        """
#        ...
#        """
