#!/bin/bash -e
#SBATCH --job-name      assembly_hifiasm
#SBATCH --cpus-per-task 32
#SBATCH --time          64:00:00 
#SBATCH --mem           92G
#SBATCH --output        slurm_Assembly_hifiasm_%A.txt
#SBATCH --error         slurm_Assembly_hifiasm_%A.txt

# Test Data in 46665479 and 46665480 - 1:00:00  24G 4 cores

###  Modules  ###
module purge >/dev/null 2>&1
module load hifiasm/0.19.9

###  Inputs   ###
id=$1
mode=$2
patid=$3
matid=$4

if [ -z "$id" ]; then
    echo -e "Sample ID is not set. This is the individual you would like to run hifiasm on. Exiting..."
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
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "\nUsing parental Yak kmers for phasing..."
        tag=dip
        if [[ -z ${patid+x} ]] || [[ -z ${matid+x} ]]
        then
            echo -e "\nOne or more parental IDs are unset, exiting..."
            exit 1
        fi
    fi
fi

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

hifi=$(find "${wkdir}/${id}/PacBio/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + 2>/dev/null)
duplex=$(find "${wkdir}/${id}/Nanopore/Duplex/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + 2>/dev/null)
ul=$(find "${wkdir}/${id}/Nanopore/UltraLong/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + | tr ' ' ','  2>/dev/null)
hic1=$(find "${wkdir}/${id}/HiC/" -maxdepth 5 -name '*R1*.fastq.gz' -exec echo -n {} + | tr ' ' ','  2>/dev/null)
hic2=$(find "${wkdir}/${id}/HiC/" -maxdepth 5 -name '*R2*.fastq.gz' -exec echo -n {} + | tr ' ' ','  2>/dev/null)
yak1=${wkdir}/${id}/Yak/${patid}_subset.yak
yak2=${wkdir}/${id}/Yak/${matid}_subset.yak

###  Code  ###
mkdir -p ${wkdir}/${id}/Assemblies/hifiasm-${mode}

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

## hifiasm with HiC
if [[ $mode == "hic" ]]
then
    if [[ ! -z ${hic1} ]] && [[ ! -z ${hic2} ]]
    then
        echo -e "\nThe following HiC input files were found:"
        find "${wkdir}/${id}/HiC/" -maxdepth 5 -name '*R1*.fastq.gz' -exec echo -n {} + | sed 's/$/\n/g' | sed 's/ /\n/g' | sed 's/^/\t/g'
        find "${wkdir}/${id}/HiC/" -maxdepth 5 -name '*R2*.fastq.gz' -exec echo -n {} + | sed 's/$/\n/g' | sed 's/ /\n/g' | sed 's/^/\t/g'
    else
        echo -e "\nNo HiC input files found. Exiting..."
        exit 1
    fi
    if [[ ! -f ${wkdir}/${id}/Assemblies/hifiasm-${mode}/${id}_hifiasm-hic.asm.hic.p_ctg.gfa ]]
    then
        cmd="hifiasm --ul-cut 50000 -o ${wkdir}/${id}/Assemblies/hifiasm-${mode}/${id}_hifiasm-hic.asm -t ${cpus} --h1 ${hic1} --h2 ${hic2} --ul ${ul} ${hifi} ${duplex} 2> ${wkdir}/${id}/Assemblies/hifiasm-${mode}/${id}_hifiasm-hic.log"
        echo -e "\nRunning hifiasm..."
        echo -e "\n   $cmd"
        eval $cmd
    fi
fi

## hifiasm with Yak
if [[ $mode == "kmer" ]]
then
    if [[ -f ${yak1} ]] && [[ -f ${yak2} ]]
    then
        if [[ ! -f ${wkdir}/${id}/Assemblies/hifiasm-${mode}/${id}_hifiasm-kmer.asm.hic.p_ctg.gfa ]]
        then
            cmd="hifiasm --ul-cut 50000 -o ${wkdir}/${id}/Assemblies/hifiasm-${mode}/${id}_hifiasm-kmer.asm -t ${cpus} -1 ${yak1} -2 ${yak2} --ul ${ul} ${hifi} ${duplex} 2> ${wkdir}/${id}/Assemblies/hifiasm-${mode}/${id}_hifiasm-kmer.log"
            echo -e "\nRunning hifiasm..."
            echo -e "\n   $cmd"
            eval $cmd
        fi
    else
        echo -e "\nOne or both of the following parental kmer databases could not be found: ${yak1} ${yak2}"
        echo -e "\nExiting..."
        exit 1
    fi
fi

for i in {1..2}
do
    hap=${wkdir}/${id}/Assemblies/hifiasm-${mode}/${id}_hifiasm-${mode}.asm.${tag}.hap${i}.p_ctg.gfa
    if [[ -f ${hap} ]] 
    then
        echo -e "Running gfa-to-fa the following assembly haplotypes:\n\t${hap}"
    else
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "Exiting..."
        exit 1
    fi
    hapout=$(echo $hap | sed 's/\.gfa//g' | sed 's/\.fa//g' )

    if [[ ! -s ${hapout} ]]
    then
		${script_dir}/Utility-gfa2fa.sh ${hap}
    fi
    if [[ ! -s ${hapout}.fai ]]
    then
		${script_dir}/Utility-faidx.sh ${hapout}.fa
    fi   
done

exit 0
