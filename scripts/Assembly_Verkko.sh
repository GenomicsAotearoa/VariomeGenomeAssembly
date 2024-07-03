#!/bin/bash -e
#SBATCH --job-name      assembly_verkko
#SBATCH --cpus-per-task 32
#SBATCH --time          168:00:00
#SBATCH --mem           92G
#SBATCH --output        slurm_Assembly_Verkko_%A.txt
#SBATCH --error         slurm_Assembly_Verkko_%A.txt

###  Modules  ###
module purge
module load verkko/2.1

###  Inputs   ###
id=$1
mode=$2
patid=$3
matid=$4

if [ -z "$id" ]; then
    echo -e "Sample ID is not set. This is the individual you would like to run verkko on. Exiting..."
    exit 1
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "\nNo phasing mode set! Choose either 'hic' or 'kmer', exiting..."
    exit 1
else
    if [[ $mode == "hic" ]]
    then
        echo -e "\nUsing HiC for phasing.."
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "\nUsing parental Meryl kmers for phasing..."
        if [[ -z ${patid+x} ]] || [[ -z ${matid+x} ]]
        then
            echo -e "\nOne or more parental IDs are unset, exiting..."
            exit 1
        fi
    fi
fi

# Mem in Gb
if [ -n "${SLURM_MEM_PER_NODE:-}" ]
then
	mem=$(echo "scale=0; $SLURM_MEM_PER_NODE / 1024" | bc)
else
	mem=32
fi

if [ -n "${SLURM_CPUS_PER_TASK:-}" ]
then
	cpus=${SLURM_CPUS_PER_TASK}
else
	cpus=16
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

hifi=$(find "${wkdir}/${id}/PacBio/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + 2>/dev/null)
duplex=$(find "${wkdir}/${id}/Nanopore/Duplex/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + 2>/dev/null)
ul=$(find "${wkdir}/${id}/Nanopore/UltraLong/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + 2>/dev/null)
hic1=$(find "${wkdir}/${id}/HiC/" -maxdepth 5 -name '*R1*.fastq.gz' -exec echo -n {} + 2>/dev/null)
hic2=$(find "${wkdir}/${id}/HiC/" -maxdepth 5 -name '*R2*.fastq.gz' -exec echo -n {} + 2>/dev/null)
meryl1=${wkdir}/${id}/Meryl/${patid}_compress.k30.meryl
meryl2=${wkdir}/${id}/Meryl/${matid}_compress.k30.meryl

###  Code  ###
mkdir -p ${wkdir}/${id}/Assemblies/verkko-${mode}

if [[ ! -z ${duplex} ]] || [[ ! -z ${hifi} ]]
then
    echo -e "\nThe following Nanopore Duplex input files were found:"
    if [[ ! -z ${duplex} ]]
    then
        find "${wkdir}/${id}/Nanopore/Duplex/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + | sed 's/ /\n/g' | sed 's/^/\t/g'
    fi
    echo -e "\nThe following HiFi input files were found:"
    if [[ ! -z ${hifi} ]]
    then
        find "${wkdir}/${id}/PacBio/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + | sed 's/ /\n/g' | sed 's/^/\t/g'
    fi
else
    echo -e "\nNo Nanopore Duplex or HiFi input files found. Exiting..."
    exit 1
fi

if [[ ! -z ${ul} ]]
then
    echo -e "\nThe following Nanopore UltraLong input files were found:"
    find "${wkdir}/${id}/Nanopore/UltraLong/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + | sed 's/ /\n/g' | sed 's/^/\t/g'
else
    echo -e "\nNo Nanopore UltraLong input files found. Exiting..."
    exit 1
fi

## Verkko with HiC
if [[ $mode == "hic" ]]
then
    if [[ ! -z ${hic1} ]] && [[ ! -z ${hic2} ]]
    then
        echo -e "\nThe following HiC input files were found:"
        find "${wkdir}/${id}/HiC/" -maxdepth 5 -name '*R1*.fastq.gz' -exec echo -n {} + | sed 's/$/\n/g' | sed 's/ /\n/g' | sed 's/^/\t/g'
        find "${wkdir}/${id}/HiC/" -maxdepth 5 -name '*R2*.fastq.gz' -exec echo -n {} + | sed 's/$/\n/g' | sed 's/ /\n/g' | sed 's/^/\t/g'
    else
        echo "\nNo HiC input files found. Exiting..."
        exit 1
    fi
    cmd="verkko --screen human -d ${wkdir}/${id}/Assemblies/verkko-${mode} --hifi ${hifi} ${duplex} --nano ${ul} --hic1 ${hic1} --hic2 ${hic2}"
    echo -e "\nRunning Verkko..."
    echo -e "\n   $cmd"
    eval $cmd
fi

## Verkko with meryl
if [[ $mode == "kmer" ]]
then
    if [[ -d ${meryl1} ]] && [[ -d ${meryl2} ]]
    then
        cmd="verkko --local-memory $mem --local-cpus $cpus --screen human -d ${wkdir}/${id}/Assemblies/verkko-${mode} --hifi ${hifi} ${duplex} --nano ${ul} --hap-kmers ${meryl1} ${meryl2} trio"
        echo -e "\nRunning Verkko..."
        echo -e "\n   $cmd"
        eval $cmd
    else
        echo -e "\nOne or both of the following parental kmer databases could not be found: ${meryl1} ${meryl2}"
        echo -e "\nExiting..."
        exit 1
    fi
fi

for i in {1..2}
do
    hap=${wkdir}/${id}/Assemblies/verkko-${mode}/assembly.haplotype${i}.fasta
    if [[ ! -s ${hap} ]]
    then    
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "\nExiting..."
        exit 1
 	else
        if [[ ! -s ${hap}.fai ]]
    	then
			${script_dir}/Utility-faidx.sh ${hap}
    	fi
    fi   
done

exit 0