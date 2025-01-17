#!/bin/bash -e
#SBATCH --job-name      annotation_ReferenceAlignment
#SBATCH --cpus-per-task 8
#SBATCH --time          02:00:00
#SBATCH --mem           48G
#SBATCH --output        slurm_Annotation_ReferenceAlignment_%A.txt
#SBATCH --error         slurm_Annotation_ReferenceAlignment_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1
module load minimap2/2.28

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
    echo -e "Sample ID is not set. This is the individual you would like to run ReferenceAlignment on. Exiting..."
    exit 1
fi

if [[ -z $ass || (( $ass != "verkko" && $ass != "hifiasm" )) ]]
then
    echo -e "No assembler set! Choose either 'verkko' or 'hifiasm', exiting..."
    exit 1
else
    if [[ $ass == "verkko" ]]
    then
        echo -e "Running Reference Alignment on Verkko assembly..."
    fi
    if [[ $ass == "hifiasm" ]]
    then 
        echo -e "Running Reference Alignment on hifiasm assembly..."
    fi
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "No phasing mode set! Choose either 'hic' or 'kmer', exiting..."
else
    if [[ $mode == "hic" ]]
    then
        echo -e "Running ReferenceAlignment on HiC-assembly mode..."
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "Running ReferenceAlignment on Kmer-assembly mode..."
        tag=dip
    fi
fi

###  Code   ###
stepdir=${wkdir}/${id}/Assemblies/${ass}-${mode}

mkdir -p ${stepdir}/Annotation/ReferenceAlignment

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
    refout=$( echo $refdna | sed 's/\.f[a-zA-Z]*a$//g' | sed 's/.*\///g' )

    if [[ -f ${hap} ]] 
    then
        echo -e "Running ReferenceAlignment on the following assembly haplotypes:\n\t${hap}"
    else
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "Exiting..."
        exit 1
    fi
    if [[ ! -s ${stepdir}/Annotation/ReferenceAlignment/${hapout}-to-${refout}.paf ]]
    then
        cmd="minimap2 -cx asm5 ${refdna} ${hap} > ${stepdir}/Annotation/ReferenceAlignment/${hapout}-to-${refout}.paf"
        echo -e "Running minimap ReferenceAlignment for ${hap} against ${refdna}..."
        echo -e "   $cmd"
        eval $cmd
    fi
done

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
    refout=$( echo $refdna | sed 's/\.f[a-zA-Z]*a$//g' | sed 's/.*\///g' )

    if [[ -f ${hap} ]] 
    then
        echo -e "Running paftools misjoin check on the following assembly haplotypes:\n\t${hap}"
    else
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "Exiting..."
        exit 1
    fi
    if [[ ! -s ${stepdir}/Annotation/ReferenceAlignment/${hapout}-to-${refout}.misjoin.tsv ]]
    then
        cmd="paftools.js misjoin ${stepdir}/Annotation/ReferenceAlignment/${hapout}-to-${refout}.paf > ${stepdir}/Annotation/ReferenceAlignment/${hapout}-to-${refout}.misjoin.tsv"
        echo -e "Running paftools misjoin check for ${hap} against ${refdna}..."
        echo -e "   $cmd"
        eval $cmd
    fi
done

echo "Reference alignment complete for ${id} ${ass}-${mode}"

exit 0
