#!/bin/bash

ass=$1
mode=$2

if [ -n "${SLURM_JOB_ID:-}" ]
then
	script_path=$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}')
else
	script_path=$(realpath "$0")
fi
script_dir=$(dirname "${script_path}")
parent_dir=$(dirname "${script_dir}")

if [[ -z $ass || (( $ass != "verkko" && $ass != "hifiasm" )) ]]
then
    echo -e "No assembler set! Choose either 'verkko' or 'hifiasm', exiting..."
    exit 1
else
    if [[ $ass == "verkko" ]]
    then
        echo -e "Running tests using Verkko..."
    fi
    if [[ $ass == "hifiasm" ]]
    then 
        echo -e "Running tests using hifiasm..."
    fi
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "No phasing mode set! Choose either 'hic' or 'kmer', exiting..."
else
    if [[ $mode == "hic" ]]
    then
        echo -e "Running tests using HiC phasing..."
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "Running tests using parental k-mer phasing..."
        tag=dip
    fi
fi

echo -e "\tTest run beginning..."

srun --output=/dev/null -c 2 --mem 8G --time 01:00:00 ${parent_dir}/scripts/Utility-hg38pull.sh; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tUtility-hg38pull completed successfully."; else echo -e "\tUtility-hg38pull failed with exit status $EXIT_STATUS."; fi 

if [[ $mode == "hic" ]]
then
    if [[ $ass == "verkko" ]]
    then
    	srun --output=/dev/null -c 8 --mem 48G --time 01:00:00 ${parent_dir}/scripts/Assembly_Verkko.sh testdata hic; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAssembly_Verkko with HiC completed successfully."; else echo -e "\tAssembly_Verkko with HiC failed with exit status $EXIT_STATUS."; fi 
    fi

    if [[ $ass == "hifiasm" ]]
    then
    	srun --output=/dev/null -c 8 --mem 48G --time 01:00:00 ${parent_dir}/scripts/Assembly_hifiasm.sh testdata hic; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAssembly_hifiasm with HiC completed successfully."; else echo -e "\tAssembly_hifiasm with HiC failed with exit status $EXIT_STATUS."; fi 
    fi
fi

if [[ $mode == "kmer" ]]
then
    if [[ $ass == "verkko" ]]
    then
		srun --output=/dev/null -c 2 --mem 8G --time 01:00:00 ${parent_dir}/scripts/Assembly_Meryl.sh testdata testdataP; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAssembly_Meryl for the paternal sample completed successfully."; else echo -e "\tAssembly_Meryl for the paternal sample failed with exit status $EXIT_STATUS."; fi 
		srun --output=/dev/null -c 2 --mem 8G --time 01:00:00 ${parent_dir}/scripts/Assembly_Meryl.sh testdata testdataM; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAssembly_Meryl for the maternal sample completed successfully."; else echo -e "\tAssembly_Meryl for the maternal sample failed with exit status $EXIT_STATUS."; fi 
		srun --output=/dev/null -c 8 --mem 48G --time 01:00:00 ${parent_dir}/scripts/Assembly_Verkko.sh testdata kmer testdataP testdataM; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAssembly_Verkko with parental phasing completed successfully."; else echo -e "\tAssembly_Verkko with parental phasing failed with exit status $EXIT_STATUS."; fi 
    fi

    if [[ $ass == "hifiasm" ]]
    then
		srun --output=/dev/null -c 4 --mem 24G --time 01:00:00 ${parent_dir}/scripts/Assembly_Yak.sh testdata testdataP; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAssembly_Yak for the paternal sample completed successfully."; else echo -e "\tAssembly_Yak for the paternal sample failed with exit status $EXIT_STATUS."; fi 
		srun --output=/dev/null -c 4 --mem 24G --time 01:00:00 ${parent_dir}/scripts/Assembly_Yak.sh testdata testdataM; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAssembly_Yak for the maternal sample completed successfully."; else echo -e "\tAssembly_Yak for the maternal sample failed with exit status $EXIT_STATUS."; fi 
		srun --output=/dev/null -c 8 --mem 48G --time 01:00:00 ${parent_dir}/scripts/Assembly_hifiasm.sh testdata kmer testdataP testdataM; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAssembly_hifiasm with parental phasing completed successfully."; else echo -e "\tAssembly_hifiasm with parental phasing failed with exit status $EXIT_STATUS."; fi 
   fi
fi

srun --output=/dev/null -c 4 --mem 24G --time 01:00:00 ${parent_dir}/scripts/QC_Yak.sh testdata ${ass} ${mode}; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tQC_Yak completed successfully."; else echo -e "\tQC_Yak failed with exit status $EXIT_STATUS."; fi 
srun --output=/dev/null -c 2 --mem 8G --time 01:00:00 ${parent_dir}/scripts/QC_Merqury.sh testdata ${ass} ${mode}; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tQC_Merqury completed successfully."; else echo -e "\tQC_Merqury failed with exit status $EXIT_STATUS."; fi 
srun --output=/dev/null -c 2 --mem 8G --time 01:00:00 ${parent_dir}/scripts/QC_MashMap.sh testdata ${ass} ${mode}; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tQC_MashMap completed successfully."; else echo -e "\tQC_MashMap failed with exit status $EXIT_STATUS."; fi 
srun --output=/dev/null -c 2 --mem 8G --time 01:00:00 ${parent_dir}/scripts/QC_gfastats.sh testdata ${ass} ${mode}; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tQC_gfastats completed successfully."; else echo -e "\tQC_gfastats failed with exit status $EXIT_STATUS."; fi 
srun --output=/dev/null -c 4 --mem 36G --time 01:00:00 ${parent_dir}/scripts/QC_asmgene.sh testdata ${ass} ${mode}; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tQC_asmgene completed successfully."; else echo -e "\tQC_asmgene failed with exit status $EXIT_STATUS."; fi 

srun --output=/dev/null -c 12 --mem 92G --time 01:00:00 ${parent_dir}/scripts/Annotation_RepeatMasker.sh testdata ${ass} ${mode}; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAnnotation_RepeatMasker completed successfully."; else echo -e "\tAnnotation_RepeatMasker failed with exit status $EXIT_STATUS."; fi 
srun --output=/dev/null -c 4 --mem 24G --time 01:00:00 ${parent_dir}/scripts/Annotation_ReferenceAlignment.sh testdata ${ass} ${mode}; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAnnotation_ReferenceAlignment completed successfully."; else echo -e "\tAnnotation_ReferenceAlignment failed with exit status $EXIT_STATUS."; fi 
srun --output=/dev/null -c 12 --mem 64G --time 02:00:00 ${parent_dir}/scripts/Annotation_LiftOff.sh testdata ${ass} ${mode}; EXIT_STATUS=$?; if [ $EXIT_STATUS -eq 0 ]; then echo -e "\tAnnotation_LiftOff completed successfully."; else echo -e "\tAnnotation_LiftOff failed with exit status $EXIT_STATUS."; fi 

exit 0