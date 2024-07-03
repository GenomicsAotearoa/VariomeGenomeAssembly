[^Front Page](..)

[<Installation and Preparation](Installation.md)

[<Test Run](TestRun.md)

# Assembly

The assembly workflow has two different options for assembler - hifiasm and Verkko - and can be run with either HiC or parental k-mer data for phasing. Both assembly scripts autodetect input files based on a set Working_Directory structure outline below.

- [Working_Directory]
	- HiC
	- Illumina
		- [Sample]
		- [PaternalSample]
		- [MaternalSample]
	- Nanopore
		- Duplex
		- UltraLong
	- PacBio 

Input sequence files are assumed to be in the appropriate directories with the suffix '*.fastq.gz', and all files in all subdirectories up to 5 directories deep will be included. HiC data are assumed to be named '\*R1\*.fastq.gz' and '\*R2\*.fastq.gz' and Illumina data are assumed to be in split subdirectories based on the sample (i.e. sample, paternal sample, and maternal sample). Note that Nanopore UltraLong read data is required along with Nanopore Duplex and/or PacBio Hifi data, as well as HiC and/or parental short read data.

## hifiasm

[hifiasm](https://github.com/chhylp123/hifiasm) can be run using either HiC or parental k-mer phasing data. If you are using k-mer phasing, k-mer databases will first need to be created using [Yak](https://github.com/lh3/yak) using `yak count` with [default parameters](https://github.com/chhylp123/hifiasm?tab=readme-ov-file#trio) for hifiasm (27 Bloom filter size and 31 k-mer size), and needs to be run on both parental samples. hifiasm is run using default parameters with the addition of `--ul-cut 50000` to filter out short Nanopore UltraLong reads.

### hifiasm - Parental k-mer Phasing

`Assembly_Yak.sh [Sample] [PaternalSample]`

`Assembly_Yak.sh [Sample] [MaternalSample]`

`Assembly_hifiasm.sh [Sample] kmer [PaternalSample] [MaternalSample]`

### hifiasm - HiC Phasing

`Assembly_hifiasm.sh [Sample] hic`

## Verkko

[Verkko](https://github.com/marbl/verkko) can be run using either HiC or parental k-mer phasing data. If you are using k-mer phasing, k-mer databases will first need to be created using [Meryl](https://github.com/marbl/meryl) using `meryl count` with [default parameters](https://github.com/marbl/verkko?tab=readme-ov-file#getting-started) for Verkko (homopolymer compressed 30 k-mer size), and needs to be run on both parental samples. Verkko is run using default parameters with the addition of `--screen human` to filter out common human contaminants.

### Verkko - Parental k-mer Phasing

`Assembly_Meryl.sh [Sample] [PaternalSample]`

`Assembly_Meryl.sh [Sample] [MaternalSample]`

`Assembly_Verkko.sh [Sample] kmer [PaternalSample] [MaternalSample]`

### Verkko - HiC Phasing

`Assembly_Verkko.sh [Sample] hic`

[Assembly QC>](QC.md)
