#!/bin/bash -e
#SBATCH --job-name      Utility-ensemblreleasepull
#SBATCH --cpus-per-task 1
#SBATCH --time          10:00:00
#SBATCH --mem           10G
#SBATCH --output        slurm_Utility_ensemblreleasepull_%A.txt
#SBATCH --error         slurm_Utility_ensemblreleasepull_%A.txt

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

release=111

### Directory Setup and Download GFF3 ###
function validate_url()
{
    wget --spider $1 >/dev/null 2>&1
    return $?
}

if validate_url http://ftp.ensembl.org/pub/release-${release}/gff3/homo_sapiens/Homo_sapiens.GRCh38.${release}.gff3.gz
then
    wkdir=${rsdir}/Ensembl_Release_${release}
    mkdir -p ${wkdir}
    GFF3=${wkdir}/Homo_sapiens.GRCh38.${release}.gff3

    if [[ ! -s ${GFF3}.gz ]]
    then
        echo "Ensembl Release ${release} GFF3 is downloading..."
        wget -P ${wkdir} http://ftp.ensembl.org/pub/release-${release}/gff3/homo_sapiens/Homo_sapiens.GRCh38.${release}.gff3.gz
    else
        echo "Ensembl Release ${release} GFF3 is already downloaded"
    fi
 
    if [[ ! -s ${GFF3} ]]
    then
        pigz -c -d ${GFF3}.gz > ${GFF3}
    fi
    
    FA=${wkdir}/Homo_sapiens.GRCh38.dna.primary_assembly.fa

    if [[ ! -s ${FA}.gz ]]
    then
        echo "Ensembl Release ${release} FA is downloading..."
        wget -P ${wkdir} http://ftp.ensembl.org/pub/release-${release}/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
    else
        echo "Ensembl Release ${release} FA is already downloaded"
    fi
    
    if [[ ! -s ${FA} ]]
    then
        pigz -c -d ${FA}.gz > ${FA}
    fi
    
else
   echo "Ensembl Release ${release} does not exist for hg38, exiting..."
   exit 1
fi

### GFF3 to BED ###
# Only includes protein coding genes with genenames. chr added as prefix. base-offset adjusted for BED ( GFF3 (1) -> BED (0) ). Final columns are chr,start,end,genename. HGNC ids might be better to match by or even ENSG, more stable???
BED=${wkdir}/Homo_sapiens.GRCh38.${release}.bed
if [[ ! -s ${BED} ]]
then
    if [[ -s ${GFF3} ]]
    then
        cat $GFF3 | awk  -F"\t" '$9 ~ /^ID=gene:.+/ && $9 ~ /biotype=protein_coding/ && $9 ~ /Name=/ {print}' | awk '{FS = "\t";OFS = "\t";  gsub(/;/,"\t", $9)} 1' | awk '{FS = "\t";OFS = "\t";  print "chr"$1,$4-1,$5-1,$10 }' | awk '{FS = "\t";OFS = "\t"; gsub(/Name=/,"", $4)} 1' > $BED
    else
        echo "$GFF doesn't exist, exiting..."
        exit 2
    fi
fi

echo "Ensembl Release ${release} download is complete!"

exit 0