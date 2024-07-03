#!/bin/bash -e
#SBATCH --job-name      Utility-gfa2fa
#SBATCH --cpus-per-task 1
#SBATCH --time          2:00:00
#SBATCH --mem           10G
#SBATCH --output        slurm_Utility_gfa2fa_%A.txt
#SBATCH --error         slurm_Utility_gfa2fa_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1

### Inputs ###
gfa=$1
fa=$(echo ${gfa} | sed 's/\.gfa/\.fa/g')

### Code ###
if [[ ! -s ${fa} ]]
then
	awk '/^S/{print ">"$2;print $3}' ${gfa} > ${fa}
else
    echo "${fa} already exists, skipping..."
fi

exit 0
