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
    echo -e "No assembler set! Choose either 'verkko' or 'hifiasm', cleaning all..."
else
    if [[ $ass == "verkko" ]]
    then
        echo -e "Cleaning Verkko tests..."
    fi
    if [[ $ass == "hifiasm" ]]
    then 
        echo -e "Cleaning hifiasm tests..."
    fi
fi

if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]]
then
    echo -e "No phasing mode set! Choose either 'hic' or 'kmer', cleaning all..."
else
    if [[ $mode == "hic" ]]
    then
        echo -e "Cleaning HiC phasing tests..."
        tag=hic
    fi
    if [[ $mode == "kmer" ]]
    then 
        echo -e "Cleaning parental k-mer phasing tests..."
        tag=dip
    fi
fi

echo -e "\tCleaning beginning..."


if [[ -z $mode || (( $mode != "hic" && $mode != "kmer" )) ]] && [[ -z $ass || (( $ass != "verkko" && $ass != "hifiasm" )) ]]
then
	rm -r -f ${script_dir}/testdata/Assemblies/
	rm -r -f ${script_dir}/testdata/Meryl/
	rm -r -f ${script_dir}/testdata/Yak/
else
	rm -r -f ${script_dir}/testdata/Assemblies/${ass}-${mode}/
	if [[ $mode == "kmer" ]] 
	then
	    if [[ $ass == "verkko" ]]
    	then
        	rm -r -f ${script_dir}/testdata/Meryl/
    	fi
    	if [[ $ass == "hifiasm" ]]
    	then 
        	rm -r -f ${script_dir}/testdata/Yak/
    	fi
	fi
fi

exit 0