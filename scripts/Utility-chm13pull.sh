#!/bin/bash -e
#SBATCH --job-name      Utility-chm13pull
#SBATCH --cpus-per-task 1
#SBATCH --time          10:00:00
#SBATCH --mem           10G
#SBATCH --output        slurm_Utility_chm13pull_%A.txt
#SBATCH --error         slurm_Utility_chm13pull_%A.txt

# modify .fna by tag filtering awk '/^>/ {P=index($0,"unlocalized")==0} {if(P) print} '

###  Modules  ###
module purge >/dev/null 2>&1
module load samtools/1.19.2
module load pigz/2.6

### Inputs ###
if [ -n "${SLURM_JOB_ID:-}" ]
then
	script_dir=$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}')
else
	script_dir=$(realpath "$0")
fi
parent_dir=$(dirname "$(dirname "${script_dir}")")

source ${parent_dir}/parameters.config 

if [[ -z $rsdir ]]
then
	echo "Resource directory (rsdir) is not set, add your desired resource directory to ${parent_dir}/parameters.config. Exiting..." 
	exit 1
fi

### Code ###
mkdir -p ${rsdir}/CHM13_v2.0

if [[ ! -s ${rsdir}/CHM13_v2.0/CHM13_v2.0.gff.gz ]]
then
	curl "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/914/755/GCF_009914755.1_T2T-CHM13v2.0/GCF_009914755.1_T2T-CHM13v2.0_genomic.gff.gz" -o "${rsdir}/CHM13_v2.0/CHM13_v2.0.gff.gz"
fi

if [[ ! -s ${rsdir}/CHM13_v2.0/CHM13_v2.0.cds.fasta.gz ]]
then
	curl "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/914/755/GCF_009914755.1_T2T-CHM13v2.0/GCF_009914755.1_T2T-CHM13v2.0_cds_from_genomic.fna.gz" -o "${rsdir}/CHM13_v2.0/CHM13_v2.0.cds.fasta.gz"
fi

if [[ ! -s ${rsdir}/CHM13_v2.0/CHM13_v2.0.fna ]]
then
	curl "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/914/755/GCF_009914755.1_T2T-CHM13v2.0/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna.gz" -o "${rsdir}/CHM13_v2.0/CHM13_v2.0.fna.gz"
	pigz -d "${rsdir}/CHM13_v2.0/CHM13_v2.0.fna.gz"
fi 

if [[ ! -s ${rsdir}/CHM13_v2.0/CHM13_v2.0.fna.fai ]]
then
	samtools faidx "${rsdir}/CHM13_v2.0/CHM13_v2.0.fna"
fi

exit 0