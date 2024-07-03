#!/bin/bash -e
#SBATCH --job-name      qc_merqury
#SBATCH --cpus-per-task 16
#SBATCH --time          04:00:00
#SBATCH --mem           48G
#SBATCH --output        slurm_QC_Merqury_%A.txt
#SBATCH --error         slurm_QC_Merqury_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1
module load merqury/1.3

###  Inputs   ###
id=$1
ass=$2
mode=$3

# Mem in Gb
if [ -n "${SLURM_MEM_PER_NODE:-}" ]
then
	mem=$(echo "scale=0; $SLURM_MEM_PER_NODE / 1024" | bc)
else
	mem=8
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

if [ -z "$id" ]; then
    echo -e "Sample ID is not set. This is the individual you would like to run Merqury QC on. Exiting..."
    exit 1
fi

if [[ -z $ass || (( $ass != "verkko" && $ass != "hifiasm" )) ]]
then
    echo -e "No assembler set! Choose either 'verkko' or 'hifiasm', exiting..."
    exit 1
else
    if [[ $ass == "verkko" ]]
    then
        echo -e "Running Merqury QC on Verkko assembly..."
    fi
    if [[ $ass == "hifiasm" ]]
    then 
        echo -e "Running Merqury QC on hifiasm assembly..."
    fi
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "No phasing mode set! Choose either 'hic' or 'kmer', exiting..." 
    exit 1
else
    if [[ $mode == "hic" ]]
    then
        echo -e "Running Merqury QC on HiC-assembly mode..."
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "Running Merqury QC on Kmer-assembly mode..."
        tag=dip
    fi
fi

indir=${wkdir}/${id}/Illumina
outdir=${wkdir}/${id}

ill=$(find "${indir}/${id}/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} +  2>/dev/null)

if [[ ! -z ${ill} ]]
then
    echo -e "The following Illumina short-read  input files were found:"
    find "${indir}/${id}/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + | sed 's/$/$\n/g' | sed 's/ /\n/g' | sed 's/^/\t/g'
else
    echo -e "No Illumina short-read input files found. Exiting..."
    exit 1
fi

###  Code  ###
mkdir -p ${outdir}/Assemblies/${ass}-${mode}/Correctness/Merqury
mkdir -p ${outdir}/Meryl

## DB Creation ##
if [[ ! -s ${outdir}/Meryl/${id}.k30.meryl/merylIndex ]]
then
    cmd="$(which meryl) count k=30 threads=${cpus} memory=${mem} ${ill} output ${outdir}/Meryl/${id}.k30.meryl"
    echo -e "Running Meryl creating 30-mer uncompressed database..."
    echo -e "   $cmd"
    eval "$cmd" || exit $?
else
    echo -e "Output file ${outdir}/Meryl/${id}.k30.meryl already exists, continuing..."
fi

## Solo ##
for i in {1..2}
do
	if [[ $ass == "verkko" ]]
    then
        hap=${outdir}/Assemblies/${ass}-${mode}/assembly.haplotype${i}.fasta
    fi
    if [[ $ass == "hifiasm" ]]
    then 
    	hap=${outdir}/Assemblies/${ass}-${mode}/${id}_${ass}-${mode}.asm.${tag}.hap${i}.p_ctg.fa
    fi
    hapout=$( echo $hap | sed 's/\.f[a-zA-Z]*a$//g' | sed 's/.*\///g' )
    
    if [[ -f ${hap} ]] 
    then
        echo -e "Running Merqury on the following assembly haplotypes:\n\t${hap}"
    else
        echo -e "Could not find the following assembly haplotype:\n\t${hap}"
        echo -e "Exiting..."
        exit 1
    fi

    if [[ ! -s ${outdir}/Assemblies/${ass}-${mode}/Correctness/Merqury/${hapout}-Merqury.qv.txt ]]
    then
        cd ${outdir}/Assemblies/${ass}-${mode}/Correctness/Merqury
        
        cmd="merqury.sh ${outdir}/Meryl/${id}.k30.meryl ${hap} Merqury"
        echo -e "Running Merqury QC for ${hap}..."
        echo -e "   $cmd"
        eval $cmd
    fi
done

### Trio

    #ln -s ${wkdir}/${id}/assemblies/verkko/full/trio/assembly/assembly.*.fasta .
    #ln -s ${wkdir}/${id}/maternal.k21.meryl .
    #ln -s ${wkdir}/${id}/paternal.k21.meryl .
    #
    ### let's run the program in a results directory to make things a little neater
    #mkdir results
    #cd results
    #
    ### run merqury
    #merqury.sh \
    #    ../read-db.meryl \
    #    ../paternal.k21.meryl \
    #    ../maternal.k21.meryl \
    #    ../assembly.haplotype1.fasta \
    #    ../assembly.haplotype2.fasta \
    #    output
    #
    #cd -/lra

exit 0

