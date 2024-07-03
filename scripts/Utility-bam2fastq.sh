#!/bin/bash -e
#SBATCH --job-name      Utility-bam2fastq
#SBATCH --cpus-per-task 1
#SBATCH --time          10:00:00
#SBATCH --mem           4G
#SBATCH --output        slurm_Utility_bam2fastq_%A.txt
#SBATCH --error         slurm_Utility_bam2fastq_%A.txt

module purge >/dev/null 2>&1
module load samtools/1.19.2

bam=$1
fastq=$(echo ${bam} | sed 's/\.bam/\.fastq/g')

if [[ ! -f ${fastq} ]] && [[ ! -f ${fastq}.gz ]]
then
    samtools fastq ${bam} > ${fastq}
else
    echo "${fastq} already exists"
fi

if [[ ! -f ${fastq}.gz ]]
then
    pigz --force ${fastq}
else
    echo "${fastq}.gz already exists"
fi

exit 0

