#!/bin/bash

## Script for running bwa
## Date: 12 Jan 2022

## bwaIndexDir options: hg38, mm10, bosTau8, bosTau9, canFam3
## bwaIndex options: hg38.main.fa, mm10.fa, bosTau8.fa, bosTau9.main.fa, canFam3.fa

## General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --time=8:00:00
#SBATCH --mem=16GB

# Job name and output
#SBATCH -J bwa
#SBATCH -o /Users/%u/slurm_out/slurm_%A_%a.out
#SBATCH -e /Users/%u/slurm_err/slurm_%A_%a.err

# Email notifications
#SBATCH --mail-type=ALL
#SBATCH --mail-user=addz6536@colorado.edu

# Set constant variables
genomeChrFile=/Shares/CL_Shared/db/genomes/hg38/fa/hg38.main.chrom.sizes
numThreads=4
nonChrM=$(cat ${genomeChrFile} | awk '{print $1}' | grep -v chrM | tr '\n' ' ')
inDir=/Shares/CL_Shared/data/adam/h_U2_HT_CR/cutrun/b_trimmed_fastq
outDir=/Shares/CL_Shared/data/adam/h_U2_HT_CR/cutrun/c_bwa_bam
bwaIndexDir=/scratch/Shares/chuong/genomes/hg38
bwaIndex=hg38.main.fa

# Load modules
module load bwa
module load samtools
module load bedtools

# Define query files
queries=($(ls ${inDir}/*fq.gz | xargs -n 1 basename | sed --expression='s/_1_bbduk.fq.gz//g' | sed --expression='s/_2_bbduk.fq.gz//g' | uniq))

# Run bwa
pwd; hostname; date

echo "Aligning reads to the genome & outputting sam files"
echo "bwa version: "$(bwa)
echo "Samtools version: "$(samtools --version)
echo "Bedtools version: "$(bedtools --version)

echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}

bwa mem \
-t ${numThreads} \
${bwaIndexDir}/${bwaIndex} \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_1_bbduk.fq.gz \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_2_bbduk.fq.gz \
> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam


samtools view -Sb -q 10 -F 4 ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam \
| samtools sort -@ ${numThreads} - \
> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam

# Note that this will filter out low quality reads (-q 10), unmapped reads (-F 4), and chrM (samtools view -b - ${nonChrM}), then sort the bam.
samtools view -b ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam ${nonChrM} \
| samtools sort -@ ${numThreads} - \
> ${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam


# Create a bai index file
samtools index \
${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam \
> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam.bai


# Remove intermediate files
rm ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam

echo $(date +"[%b %d %H:%M:%S] Done!")

### Explanation of bwa options
### '-t <int' - specifies number of threads to use

### Explanation of samtools options
### '-@ <int>' - number of threads
### '-Sb' - convert sam to bam
### '-q <int>' - quality threshold (filter out reads with quality below int)
### '-F 4' - exclude unmapped reads
### '-c' - print only the count of matching records
