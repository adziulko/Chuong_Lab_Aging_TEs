#!/bin/bash

## Script for running hisat2
##
## Example usage:
## sbatch --array 0-x hisat2_PE_k100.sbatch

# important note:
# for single-ended data, rnaStrandness is R (for reverse) or F (for forward)
# for paired-ended data, rnaStrandness is RF (for reverse) or FR (for forward)

## General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -c 8
#SBATCH --time=8:00:00
#SBATCH --mem=32GB

# Job name and output
#SBATCH -J hisat2_PE_k100
#SBATCH --output=/Users/%u/slurm_out/slurm_%A_%a.out
#SBATCH --error=/Users/%u/slurm_err/slurm_%A_%a.err

# Set constant variables
numThreads=8
inDir=/scratch/Users/addz6536/r_CCLE/rna_seq/a_raw_fastq/batch1
outDir=/scratch/Users/addz6536/r_CCLE/rna_seq/k_hisat2
hisatIdxDir=/Shares/CL_Shared/db/genomes/hg38/index/hisat2
hisatIdx=hg38.main
rnaStrandness=RF

# Set query files
# note: remove R1/R2 to generate a unique identifier for each pair of files
queries=($(ls $inDir/*_trimmed.fastq.gz | xargs -n 1 basename | sed 's/_R1_trimmed.fastq.gz//g' | sed 's/_R2_trimmed.fastq.gz//g' | uniq))

# Load modules
module load hisat2 samtools

# Run hisat2
pwd; hostname; date

echo "Starting HISAT2 alignment..."
echo "HISAT2 version: "$(hisat2 --version)
echo "samtools version: "$(samtools --version)
echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}

hisat2 --no-softclip \
--rna-strandness ${rnaStrandness} \
-k 100 \
-p ${numThreads} \
-x ${hisatIdxDir}/${hisatIdx} \
-1 $inDir/${queries[$SLURM_ARRAY_TASK_ID]}_R1_trimmed.fastq.gz \
-2 $inDir/${queries[$SLURM_ARRAY_TASK_ID]}_R2_trimmed.fastq.gz \
| samtools sort -@ ${numThreads} - -o $outDir/${queries[$SLURM_ARRAY_TASK_ID]%.fastq.gz}.k100.bam

# Create a bai index file for upload to UCSC browser
samtools index $outDir/${queries[$SLURM_ARRAY_TASK_ID]%.fastq.gz}.k100.bam

echo $(date +"[%b %d %H:%M:%S] Done!")
