#!/bin/bash -e
#SBATCH --job-name      annotation_repeatmasker
#SBATCH --cpus-per-task 36
#SBATCH --time          64:00:00
#SBATCH --mem           120G
#SBATCH --output        slurm_Annotation_RepeatMasker_%A.txt
#SBATCH --error         slurm_Annotation_RepeatMasker_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1
module load dfam-tetools/1.88.5

###  Inputs   ###
id=$1
ass=$2
mode=$3

if [ -n "${SLURM_CPUS_PER_TASK:-}" ]
then
	cpus=${SLURM_CPUS_PER_TASK}
else
	cpus=8
fi

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

if [ -z "$id" ]; then
    echo -e "Sample ID is not set. This is the individual you would like to run RepeatMasker on. Exiting..."
    exit 1
fi

if [[ -z $ass || (( $ass != "verkko" && $ass != "hifiasm" )) ]]
then
    echo -e "No assembler set! Choose either 'verkko' or 'hifiasm', exiting..."
    exit 1
else
    if [[ $ass == "verkko" ]]
    then
        echo -e "Running RepeatMasker on Verkko assembly..."
    fi
    if [[ $ass == "hifiasm" ]]
    then 
        echo -e "Running RepeatMasker on hifiasm assembly..."
    fi
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "No phasing mode set! Choose either 'hic' or 'kmer', exiting..."
else
    if [[ $mode == "hic" ]]
    then
        echo -e "Running RepeatMasker on HiC-assembly mode..."
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "Running RepeatMasker on Kmer-assembly mode..."
        tag=dip
    fi
fi

###  Code   ###
stepdir=${wkdir}/${id}/Assemblies/${ass}-${mode}
# Make sure that RepeatMasker is downloaidng its cache to somewhere other than default $HOME
export HOME=${stepdir}

mkdir -p ${stepdir}/Annotation/RepeatMasker

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

    cd ${stepdir}/Annotation/RepeatMasker/
    cp ${hap} ${stepdir}/Annotation/RepeatMasker/
    hapname=$(basename ${hap})

    if [[ -f ${hap} ]] 
    then
        echo -e "Running RepeatMasker on the following assembly haplotypes:\n\t${hap}"
    else
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "Exiting..."
        exit 1
    fi
    #if [[ ! -s ${stepdir}/RepeatMasker/ ]]
    #then
        cmd="RepeatMasker -species human -s -gff -pa ${cpus} -dir ${stepdir}/Annotation/RepeatMasker ${hapname}"
        echo -e "Running RepeatMasker for ${hap}..."
        echo -e "   $cmd"
        eval $cmd
    #fi
done

echo "RepeatMasker complete for ${id} hifiasm-${mode}"

exit 0
