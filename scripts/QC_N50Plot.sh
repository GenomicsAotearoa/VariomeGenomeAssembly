#!/bin/bash
#SBATCH --job-name      qc_N50Plot
#SBATCH --cpus-per-task 1
#SBATCH --time          00:10:00
#SBATCH --mem           1G
#SBATCH --output        slurm_QC_N50Plot_%A.txt
#SBATCH --error         slurm_QC_N50Plot_%A.txt

## Call with
#     QC-N50Plot.sh "file1.fai file2.fai file3.fai ..."
## A max of 14 files is possible
## File names are infered from the files themselves (basename minus the extension)

###  Modules  ###
module purge >/dev/null 2>&1
module load python3/3.10

###  Inputs   ###
ARRAY=($@)

# Ideally this would figure out if its one individual or more by looking at the basenames (or just by the number of them)
mode=individual

if [ -n "${SLURM_JOB_ID:-}" ]
then
	script_path=$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}')
else
	script_path=$(realpath "$0")
fi
script_dir=$(dirname "${script_path}")
parent_dir=$(dirname "${script_dir}")

source ${parent_dir}/parameters.config 

script=${script_dir}/QC_N50Plot.py

if [[ -z $refdna ]]
then
	echo "Reference FASTA (refdna) is not set, add your desired Reference FASTA to ${parent_dir}/parameters.config. Exiting..." 
	exit 1
fi

reference=$refdna.fai
referencename=$( basename $reference | sed 's/\.f.*a\.fai//g' )

if [[ $mode == "individual" ]]
then
    id=$(echo ${ARRAY[@]} | tr ' ' '\n' | sed 's/.*\///g' | sed 's/_.*//g' | sort -u)

    pldir=${wkdir}/${id}/Assemblies/N50_Plots
    prefix=${id}
fi

COLOURARRAY=("red" "darkred" "limegreen" "darkgreen" "sandybrown" "saddlebrown" "aqua" "turquoise" "deepskyblue" "blue" "violet" "darkviolet" "pink" "deeppink")

mkdir -p ${pldir}

if [[ ${#ARRAY[@]} -eq 0 ]]
then
    echo "No files in array, exiting..."
    exit 1
fi

if [[ "${#ARRAY[@]}" -gt "${#COLOURARRAY[@]}" ]]
then
    echo "A maximum of 14 inputs is possible, exiting..."
    exit 1
fi

echo "Files inputted:"
for file in "${ARRAY[@]}"
do
    echo -e "\t"${file}
done

echo "faiFile,label,color,isReference" > ${pldir}/${prefix}_inputs.csv
for key in "${!ARRAY[@]}"
do
    label=$( echo ${ARRAY[$key]} | sed 's|.*/||' | sed 's|\.fa.*||' | sed 's|\.fasta.*||' )
    echo ${ARRAY[$key]}","${label}","${COLOURARRAY[${key}]}",FALSE" >> ${pldir}/${prefix}_inputs.csv
done
echo ${reference}","${referencename}",black,TRUE" >> ${pldir}/${prefix}_inputs.csv

python3 ${script} --faiFilesCSV ${pldir}/${prefix}_inputs.csv --figName ${pldir}/${prefix}_output_n50_plot.png

exit 0
