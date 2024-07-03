#!/bin/bash -e
#SBATCH --job-name      Utility-hg38pull
#SBATCH --cpus-per-task 1
#SBATCH --time          10:00:00
#SBATCH --mem           10G
#SBATCH --output        slurm_Utility_hg38pull_%A.txt
#SBATCH --error         slurm_Utility_hg38pull_%A.txt

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
mkdir -p ${rsdir}/hg38

if [[ ! -s ${rsdir}/hg38/hg38.gff ]]
then
	curl "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.39_GRCh38.p13/GCF_000001405.39_GRCh38.p13_genomic.gff.gz" -o "${rsdir}/hg38/hg38.gff.gz"
	pigz -d "${rsdir}/hg38/hg38.gff.gz"
fi

if [[ ! -s ${rsdir}/hg38/hg38.cds.fasta.gz ]]
then
	curl "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.39_GRCh38.p13/GCF_000001405.39_GRCh38.p13_cds_from_genomic.fna.gz" -o "${rsdir}/hg38/hg38.cds.fasta.gz"
fi

if [[ ! -s ${rsdir}/hg38/hg38.fna ]]
then
	curl "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.39_GRCh38.p13/GCF_000001405.39_GRCh38.p13_genomic.fna.gz" -o "${rsdir}/hg38/hg38.fna.gz"
	pigz -d "${rsdir}/hg38/hg38.fna.gz"
fi 

if [[ ! -s ${rsdir}/hg38/hg38.fna.fai ]]
then
	samtools faidx "${rsdir}/hg38/hg38.fna"
fi

exit 0