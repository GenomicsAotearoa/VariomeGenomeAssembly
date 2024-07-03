#!/bin/bash -e
#SBATCH --job-name      Utility-faidx
#SBATCH --cpus-per-task 1
#SBATCH --time          2:00:00
#SBATCH --mem           10G
#SBATCH --output        slurm_Utility_faidx_%A.txt
#SBATCH --error         slurm_Utility_faidx_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1
module load samtools/1.19.2

### Inputs ###
fa=$1
fai=$(echo ${fa} | sed 's/$/\.fai/g')

### Code ###
if [[ ! -s ${fai} ]]
then
    samtools faidx ${fa}
else
    echo "${fai} already exists, skipping..."
fi

exit 0
