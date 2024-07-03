#!/bin/bash -e
#SBATCH --account       ga03513
#SBATCH --job-name      Utility-duplexfilter
#SBATCH --cpus-per-task 1
#SBATCH --time          10:00:00
#SBATCH --mem           4G
#SBATCH --output        slurm_Utility_duplexfilter_%A_%a.txt
#SBATCH --error         slurm_Utility_duplexfilter_%A_%a.txt

module purge
module load SAMtools/1.19-GCC-12.3.0
module load SeqKit/2.4.0
module load pigz/2.7

trueSarray=($(echo $Sarray | tr '-' " " ))
input=${trueSarray[$(( ${SLURM_ARRAY_TASK_ID} - 1 ))]} 

samtoolsoutput=$(echo $input | sed 's/\.bam/_gt30qs.fastq/g')
seqkitoutput=$(echo $input | sed 's/\.bam/_gt30qs.15kb.fastq.gz/g')

## Filter for Q>30
if [[ ! -s ${samtoolsoutput} ]] && [[ ! -s ${seqkitoutput} ]]
then
    samtools view -e '[qs] > 30' \
        ${input} \
        | samtools fastq > ${samtoolsoutput}
fi

## Filter for over 15kb
if [[ ! -s ${seqkitoutput} ]]
then
    seqkit seq \
        -m 15000 \
        ${samtoolsoutput} \
        | pigz > ${seqkitoutput}
fi
    
rm ${samtoolsoutput}

exit 0

id=2199
Sarray=($(find "/nesi/nobackup/ga03513/Genome_Assemblies/${id}/Nanopore/Duplex/" -maxdepth 5 -name '*_duplex.bam' -exec echo -n {} + | tr ' ' "-"  2>/dev/null))
Sarraynum=$(find "/nesi/nobackup/ga03513/Genome_Assemblies/${id}/Nanopore/Duplex/" -maxdepth 5 -name '*_duplex.bam' | wc -l)

sbatch --account ga03513 --job-name=Utility-duplexfilter --export Sarray=${Sarray[@]} --array=1-${Sarraynum}%24 Utility-duplexfilter.sh
