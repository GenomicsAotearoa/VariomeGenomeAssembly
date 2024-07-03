#!/usr/bin/env python3

## Script written by Julian Lucas
## Script modified poorly by Ben Halliday

import argparse
from glob import glob
import sys
import numpy as np
import matplotlib.pyplot as plt
import math
import pandas as pd
import os
import collections

## Call with
#     python3 plot_n50.py \
#         --faiFilesCSV fai_file_info.csv \
#         --figName output_n50_plot.png

## fai_file_info.csv file should be formatted as such:
# faiFile,label,color,isReference
# HG002.hap1_filt.fa.fai,HG002,red,FALSE
# HG01099.hap1_filt.fa.fai,HG01099,grey,FALSE
# HG02004.hap1_filt.fa.fai,HG02004,blue,FALSE
# HG02071.hap1_filt.fa.fai,HG02071,red,FALSE
# chm13v1.1.fa.fai,chm13,black,TRUE

## Note that the actual inputs to the script are fai files from `samtools faidx` 

## As a reference you should include CHM13
## wget https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/chm13.draft_v1.1.fasta.gz
## You can use CHM13v2.0 but that will have both chrX and chrY -- which no other assembly should.

parser = argparse.ArgumentParser()

parser.add_argument('--faiFilesCSV', '-f', type=str, action='store', help='file of file names')
parser.add_argument('--figName', '-n', type=str, action='store', help='name to write figure to')

args = parser.parse_args()

faiFilesCSV = args.faiFilesCSV
figure_name = args.figName

faiFiles = pd.read_csv(faiFilesCSV)


###############################################################################
##                                   Inputs                                  ##
###############################################################################

reference_fai  = 'chm13v1.1.fa.fai'
reference_name = "chm13v1.1"

genome_size = 3100000000

REF_LINEWIDTH=2
LINEWIDTH=1
REF_ALPHA=1.0
ALPHA=.63


###############################################################################
##                            Define Functions                               ##
###############################################################################

def log(msg):
    print(msg, file=sys.stderr)
    
def get_length_mod(max_length):
    if max_length < 1000:
        return 1.0, "bp"
    if max_length < 1000000:
        return 1000.0, "kb"
    if max_length < 1000000000:
        return 1000000, "Mb"
    return 1000000000.0, "Gb"

def get_color(filename):
    return faiFiles.loc[faiFiles['faiFile'] ==filename]['color'].values[0]

def get_label(filename):
    return faiFiles.loc[faiFiles['faiFile'] ==filename]['label'].values[0]

def is_reference(filename):
    return faiFiles.loc[faiFiles['faiFile'] ==filename]['isReference'].values[0]

###############################################################################
##                       Build List Of Contig Lengths                        ##
###############################################################################

# for tracking all lengths
all_file_lengths = list()    ## becomes list of lists (each list is a files lengths)
max_contig_length = 0        
index_to_filename = dict()   ## key is index, value is file name. Used in get_color()

# get all contig lengths
for i, row in faiFiles.iterrows():
    file = row['faiFile']

    file_lengths = list()
    all_file_lengths.append(file_lengths)
    index_to_filename[i] = file
    
    with open(file) as file_in:
        for line in file_in:
            parts = line.split()
            length = int(parts[1])
            file_lengths.append(length)
            if length > max_contig_length:
                max_contig_length = length

###############################################################################
##                               Create N50 Plot                             ##
###############################################################################

# setup
fig, ((ax1)) = plt.subplots(nrows=1,ncols=1)
n50_size = genome_size / 2
n50s = list()
read_length_mod, read_length_mod_id = get_length_mod(max_contig_length)        ## Mb
cumulative_length_mod, cumulative_length_mod_id = get_length_mod(genome_size)  ## Gb

log("\nPlotting Contig Lengths")

for i, file_lengths in enumerate(all_file_lengths):
    is_reference_file = is_reference(index_to_filename[i])
    file_lengths.sort(reverse=True)
    total = 0
    n50 = None
    prev_length = None
    for length in file_lengths:

        # plot
        new_total = total+length
        if prev_length is not None and prev_length != length:
            ax1.vlines(total / cumulative_length_mod, prev_length / read_length_mod, length / read_length_mod,
                       alpha=REF_ALPHA if is_reference_file else ALPHA, color=get_color(index_to_filename[i]), label=get_label(index_to_filename[i]), linewidth=REF_LINEWIDTH if is_reference_file else LINEWIDTH)
        ax1.hlines(length / read_length_mod, total / cumulative_length_mod, new_total / cumulative_length_mod,
                   alpha=REF_ALPHA if is_reference_file else ALPHA, color=get_color(index_to_filename[i]), label=get_label(index_to_filename[i]), linewidth=REF_LINEWIDTH if is_reference_file else LINEWIDTH)

        # iterate
        prev_length = length
        total = new_total
        if n50 is None and total >= n50_size:
            n50 = length
            if not is_reference_file:
                n50s.append(n50)
                log("\tFile {} got NG50 of {}".format(index_to_filename[i], n50))

    # finish
    if prev_length is not None:
        ax1.vlines(total / cumulative_length_mod, prev_length / read_length_mod, 0,
                   alpha=REF_ALPHA if is_reference_file else ALPHA, color=get_color(index_to_filename[i]),
                   linewidth=REF_LINEWIDTH if is_reference_file else LINEWIDTH)
    if total >= genome_size:
        log("\tFile {} has total length {} >= genome size {}".format(index_to_filename[i], total, genome_size))

    #n50 edge case
    if n50 is None and not is_reference_file:
        n50s.append(0)
        log("\tFile {} got N50 of {}".format(index_to_filename[i], 0))
    # if is_reference_file and len(reference_name) > i:
    #    ax1.annotate(list(reversed(reference_name))[i], (0, file_lengths[0] / read_length_mod + 1), fontfamily='monospace', fontsize=12,weight="bold")

log("")
avg_n50 = np.mean(n50s)
log("Average N50: {}".format(avg_n50))
log("Genome Size: {}".format(genome_size))


ax1.ticklabel_format(axis='both', style='plain')

ax1.set_xlim(0,3.2)
ax1.set_ylim(0,(max_contig_length/10**6) + 10)

ax1.set_ylabel("Contig Length ({})".format(read_length_mod_id))
ax1.set_xlabel("Cumulative Coverage ({})".format(cumulative_length_mod_id))

fig.tight_layout()
fig.set_size_inches(12, 12)

handles, labels = plt.gca().get_legend_handles_labels()
by_label = dict(zip(labels, handles))
plt.legend(by_label.values(), by_label.keys(),loc='upper right')

plt.savefig(figure_name, format='png', dpi=200) 

###############################################################################
##                                    Done                                   ##
###############################################################################
