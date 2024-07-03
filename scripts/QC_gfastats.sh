#!/bin/bash -e
#SBATCH --job-name      qc_gfastats
#SBATCH --cpus-per-task 4
#SBATCH --time          00:10:00
#SBATCH --mem           24G
#SBATCH --output        slurm_QC_gfastats_%A.txt
#SBATCH --error         slurm_QC_gfastats_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1
module load gfastats/1.3.6

###  Inputs   ###
id=$1
ass=$2
mode=$3

if [ -n "${SLURM_JOB_ID:-}" ]
then
	script_path=$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}')
else
	script_path=$(realpath "$0")
fi
script_dir=$(dirname "${script_path}")
parent_dir=$(dirname "${script_dir}")

source ${parent_dir}/parameters.config 

if [[ -z $wkdir ]]
then
	echo "Working directory (wkdir) is not set, add your desired working directory to ${parent_dir}/parameters.config. Exiting..." 
	exit 1
fi
if [[ -z $rsdir ]]
then
	echo "Resource directory (rsdir) is not set, add your desired resource directory to ${parent_dir}/parameters.config. Exiting..." 
	exit 1
fi
if [[ -z $refdna ]]
then
	echo "Reference FASTA (refdna) is not set, add your desired Reference FASTA to ${parent_dir}/parameters.config. Exiting..." 
	exit 1
fi

if [ -z "$id" ]; then
    echo -e "Sample ID is not set. This is the individual you would like to run gfastats on. Exiting..."
    exit 1
fi

if [[ -z $ass || (( $ass != "verkko" && $ass != "hifiasm" )) ]]
then
    echo -e "No assembler set! Choose either 'verkko' or 'hifiasm', exiting..."
    exit 1
else
    if [[ $ass == "verkko" ]]
    then
        echo -e "Running gfastats QC on Verkko assembly..."
    fi
    if [[ $ass == "hifiasm" ]]
    then 
        echo -e "Running gfastats QC on hifiasm assembly..."
    fi
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "No phasing mode set! Choose either 'hic' or 'kmer', exiting..."
    exit 1
else
    if [[ $mode == "hic" ]]
    then
        echo -e "Running gfastats on HiC-assembly mode..."
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "Running gfastats on Kmer-assembly mode..."
        tag=dip
    fi
fi

stepdir=${wkdir}/${id}/Assemblies/${ass}-${mode}

###  Code   ###
mkdir -p ${stepdir}/Contiguity/GFAStats/

for i in {1..2}
do
	if [[ $ass == "verkko" ]]
    then
        hap=${stepdir}/assembly.haplotype${i}.fasta
    fi
    if [[ $ass == "hifiasm" ]]
    then 
    	hap=${stepdir}/${id}_${ass}-${mode}.asm.${tag}.hap${i}.p_ctg.fa
    fi
    hapout=$( echo $hap | sed 's/\.f[a-zA-Z]*a$//g' | sed 's/.*\///g' )
    
    if [[ -f ${hap} ]] 
    then
        echo -e "Running gfastats on the following assembly haplotypes:\n\t${hap}"
    else
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "Exiting..."
        exit 1
    fi
    if [[ ! -s ${stepdir}/Contiguity/GFAStats/${hapout}.gfastats.out ]]
    then
        cmd="gfastats ${hap} > ${stepdir}/Contiguity/GFAStats/${hapout}.gfastats.out"
        echo -e "Running gfastats for ${hap}..."
        echo -e "   $cmd"
        eval $cmd
    fi
done

exit 0
