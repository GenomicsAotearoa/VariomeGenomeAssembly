#!/bin/bash -e
#SBATCH --job-name      qc_yak
#SBATCH --cpus-per-task 16
#SBATCH --time          04:00:00
#SBATCH --mem           48G
#SBATCH --output        slurm_QC_Yak_%A.txt
#SBATCH --error         slurm_QC_Yak_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1
module load yak/0.1

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
    echo -e "Sample ID is not set. This is the individual you would like to run Yak QC on. Exiting..."
    exit 1
fi

if [[ -z $ass || (( $ass != "verkko" && $ass != "hifiasm" )) ]]
then
    echo -e "No assembler set! Choose either 'verkko' or 'hifiasm', exiting..."
    exit 1
else
    if [[ $ass == "verkko" ]]
    then
        echo -e "Running Yak QC on Verkko assembly..."
    fi
    if [[ $ass == "hifiasm" ]]
    then 
        echo -e "Running Yak QC on hifiasm assembly..."
    fi
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "No phasing mode set! Choose either 'hic' or 'kmer', exiting..."
    exit 1
else
    if [[ $mode == "hic" ]]
    then
        echo -e "Running Yak QC on HiC-assembly mode..."
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "Running Yak QC on Kmer-assembly mode..."
        tag=dip
    fi
fi

indir=${wkdir}/${id}/Illumina
outdir=${wkdir}/${id}

ill=$(find "${indir}/${id}/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} +  2>/dev/null)

if [[ ! -z ${ill} ]]
then
    echo -e "The following Illumina short-read  input files were found:"
    find "${indir}/${id}/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + | sed 's/ /\n/g' | sed 's/^/\t/g'
else
    echo -e "No Illumina short-read input files found. Exiting..."
    exit 1
fi

###  Code    ###
mkdir -p ${outdir}/Assemblies/${ass}-${mode}/Correctness/Yak
mkdir -p ${outdir}/Yak

if [[ ! -f ${outdir}/Yak/${id}_subset.yak ]]
then
    cmd="yak count -t ${cpus} -b37 -k31 -o ${outdir}/Yak/${id}_subset.yak <(zcat ${ill}) <(zcat ${ill})"
    echo -e "Running Yak creating 31-mer database..."
    echo -e "   $cmd"
    eval $cmd
else
    echo -e "\nOutput file ${outdir}/Yak/${id}_subset.yak already exists, continuing..."
fi

for i in {1..2}
do
	if [[ $ass == "verkko" ]]
    then
        hap=${outdir}/Assemblies/verkko-${mode}/assembly.haplotype${i}.fasta
    fi
    if [[ $ass == "hifiasm" ]]
    then 
    	hap=${outdir}/Assemblies/${ass}-${mode}/${id}_${ass}-${mode}.asm.${tag}.hap${i}.p_ctg.fa
    fi

    if [[ -f ${hap} ]] 
    then
        echo -e "Running Yak on the following assembly haplotypes:\n\t${hap}"
    else
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "Exiting..."
        exit 1
    fi
    hapout=$( echo $hap | sed 's/\.f[a-zA-Z]*a$//g' | sed 's/.*\///g' )

    if [[ ! -s ${outdir}/Assemblies/${ass}-${mode}/Correctness/Yak/${hapout}.Yak.qv.txt ]]
    then
        cmd="yak qv -t ${cpus} -p -K20g -l 100k ${outdir}/Yak/${id}_subset.yak ${hap} > ${outdir}/Assemblies/${ass}-${mode}/Correctness/Yak/${hapout}.Yak.qv.txt"
        echo -e "Running Yak QC for ${hap}..."
        echo -e "   $cmd"
        eval $cmd
    fi
done

exit 0
