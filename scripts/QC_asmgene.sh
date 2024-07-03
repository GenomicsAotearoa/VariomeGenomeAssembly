#!/bin/bash -e
#SBATCH --job-name      qc_asmgene
#SBATCH --cpus-per-task 8
#SBATCH --time          00:30:00
#SBATCH --mem           36G
#SBATCH --output        slurm_QC_asmgene_%A.txt
#SBATCH --error         slurm_QC_asmgene_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1
module load minimap2/2.28 # version needed for paftools/k8

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
if [[ -z $refcds ]]
then
	echo "Reference coding sequencing FASTA (refcds) is not set, add your desired Reference coding sequencing FASTA to ${parent_dir}/parameters.config. Exiting..." 
	exit 1
fi

if [ -z "$id" ]; then
    echo -e "Sample ID is not set. This is the individual you would like to run asmgene on. Exiting..."
    exit 1
fi

if [[ -z $ass || (( $ass != "verkko" && $ass != "hifiasm" )) ]]
then
    echo -e "No assembler set! Choose either 'verkko' or 'hifiasm', exiting..."
    exit 1
else
    if [[ $ass == "verkko" ]]
    then
        echo -e "Running asmgene QC on Verkko assembly..."
    fi
    if [[ $ass == "hifiasm" ]]
    then 
        echo -e "Running asmgene QC on hifiasm assembly..."
    fi
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "No phasing mode set! Choose either 'hic' or 'kmer', exiting..."
else
    if [[ $mode == "hic" ]]
    then
        echo -e "Running asmgene on HiC-assembly mode..."
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "Running asmgene on Kmer-assembly mode..."
        tag=dip
    fi
fi

stepdir=${wkdir}/${id}/Assemblies/${ass}-${mode}

###  Code   ###
mkdir -p ${stepdir}/Completeness/ASMGene/

### run minimap2 on ref, hap1, and hap2
if [[ ! -s ${stepdir}/Completeness/ASMGene/ref.cdna.paf ]]
then

    cmd="minimap2 -cxsplice:hq -t ${cpus} ${refdna} ${refcds} > ${stepdir}/Completeness/ASMGene/ref.cdna.paf"
    echo -e "Preparing reference sequence for asmgene..."
    echo -e "   $cmd"
    eval $cmd
fi

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
        echo -e "Running asmgene on the following assembly haplotypes:\n\t${hap}"
    else
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "Exiting..."
        exit 1
    fi

	if [[ ! -s ${stepdir}/Completeness/ASMGene/${hapout}.cdna.paf ]]
	then  
    	cmd="minimap2 -cxsplice:hq -t ${cpus} ${hap} ${refcds} > ${stepdir}/Completeness/ASMGene/${hapout}.cdna.paf"
    	echo -e "Preparing haplotype ${i} for asmgene..."
    	echo -e "   $cmd"
    	eval $cmd
	fi

	### run asmgene
	if [[ ! -s ${stepdir}/Completeness/ASMGene/${hapout}.asmgene.tsv ]]
	then
    	cmd="paftools.js asmgene -a ${stepdir}/Completeness/ASMGene/ref.cdna.paf ${stepdir}/Completeness/ASMGene/${hapout}.cdna.paf > ${stepdir}/Completeness/ASMGene/${hapout}.asmgene.tsv"
    	echo -e "Running asmgene for haplotype ${i}..."
    	echo -e "   $cmd"
    	eval $cmd
	fi
done

exit 0
