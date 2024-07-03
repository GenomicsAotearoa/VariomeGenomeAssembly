[^Front Page](..)

[<Assembly](Assembly.md)

# QC

Assembly QC is broken down into three segments based on the 3 C's of assembly quality, assessing the Completeness, Contiguity, and Correctness of the assembly. Each script is run identically using `QC_script.sh [Sample] [Assembler] [Mode]` where the sample name is the same used for assembly and mode is either hic or kmer. QC outputs are present in the assembly directory ([Working_Directory]/[Sample]/Assemblies/[Assemblier]-[Mode]) under the corresponding 3 C's directory.

Most QC steps require the haplotypes outputed from the assembly step to be in `.fa` format. Use `Utility-gfa2fa.sh [gfa]` to convert them if you haven't already done so. 

## Completeness

[asmgene](https://github.com/lh3/minimap2) calculates the completeness of a genome by assesing the presence of coding sequences from a reference in a given assembly. asmgene is run using the default settings as specified in the [documentation](https://lh3.github.io/2020/12/25/evaluating-assembly-quality-with-asmgene)

`QC_asmgene.sh [Sample] [Assembler] [Mode]`

## Contiguity

[MashMap](https://github.com/marbl/MashMap) is used to assess assembly contiguity by comparing the assembly to a reference. [Dotplots](https://github.com/marbl/MashMap?tab=readme-ov-file#visualize) are used to visualise how the assembly compares to the reference, with the ideal situation being a single assemblied contig per reference chromosome. Multiple contigs per reference chromosome suggest gaps in the assembly that could not be scaffolded across.

`QC_MashMap.sh [Sample] [Assembler] [Mode]`

[gfastats](https://github.com/vgl-hub/gfastats) can be used to generate basic statistics about an assembly, including contiguity statistics N50, L50, etc. 

`QC_gfastats.sh [Sample] [Assembler] [Mode]`

Contiguity can also be visualised using N50 plots, and can be used to compare contiguity across multiple haplotypes, assembliers, and individuals (note that the cross-individual comparisons are not currently support using the wrapper script but can be produced using the underlying python script). Note that this script uses `.fai` files produced from each of the assembly haplotypes to calculate N50, and can be produced using `Utility-faidx.sh [fa]`. The underlying python script for the N50 plots was written by Julian Lucas.

`QC_N50Plot.sh [Sample.hap1.fai] [Sample.hap2.fai]`

## Correctness

Assembly correctness can be calculated using the same k-mer tools as used for parental k-mer database creation, [Yak](https://github.com/lh3/yak) and [Meryl](https://github.com/marbl/meryl)/[Merqury](https://github.com/marbl/merqury). Both tools output a QV value, a log-scaled probability of error for the consensus base calls. QV above 50 (99.999% accuracy) is a 'good' quality to aim for. 

Merqury correctness uses Meryl to produce a uncompressed 30 k-mer database for QV calculation. 

`QC_Merqury.sh [Sample] [Assembler] [Mode]`

Yak correctness uses the same k-mer database creation as for assembly, so the can be created prior using the assembly script (`Assembly_Yak.sh [Sample] [Sample]`). If not created previous, the k-mer database will be created along with QV calculation using the below.

`QC_Yak.sh [Sample] [Assembler] [Mode]`

[Assembly Annotation>](Annotation.md)
