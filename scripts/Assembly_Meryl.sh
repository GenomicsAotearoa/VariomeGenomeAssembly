#!/bin/bash -e 
#SBATCH --job-name      assembly_meryl
#SBATCH --cpus-per-task 16 
#SBATCH --time          04:00:00
#SBATCH --mem           48G 
#SBATCH --output        slurm_Assembly_Meryl_%A.txt
#SBATCH --error         slurm_Assembly_Meryl_%A.txt

###  Modules  ###
module purge >/dev/null 2>&1
module load merqury/1.3

###  Inputs  ###
famid=$1
id=$2

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

if [ -z "$famid" ]; then
    echo -e "Family ID is not set. This is the individual's genome you would like to assemble. Exiting..."
    exit 1
fi

if [ -z "$id" ]; then
    echo -e "Sample ID is not set. This is the individual you would like to run Meryl on, either the sample you would like to assemble or their parents. Exiting..."
    exit 1
fi

indir=${wkdir}/${famid}/Illumina
outdir=${wkdir}/${famid}/Meryl

ill=$(find "${indir}/${id}/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} +  2>/dev/null)

if [[ ! -z ${ill} ]]
then
    echo -e "The following input files were found:"
    find "${indir}/${id}/" -maxdepth 5 -name '*.fastq.gz' -exec echo -n {} + | sed 's/ /\n/g' | sed 's/^/\t/g'
else
    echo -e "No input files found. Exiting..."
    exit 1
fi

###  Code  ###
mkdir -p ${outdir}

for i in ${ill}; do
	compress="${compress} compress $i"
done

if [[ ! -s ${outdir}/${id}_compress.k30.meryl/merylIndex ]]
then
    echo -e "Running meryl..."
    cmd="$(which meryl) count k=30 threads=${cpus} memory=${mem} ${compress} output ${outdir}/${id}_compress.k30.meryl"
    echo -e "   $cmd"
    eval "$cmd" || exit $?
else
    echo -e "\nOutput file ${outdir}/${id}_compress.k30.meryl already exists, finishing..."
    exit 0
fi

exit 0
