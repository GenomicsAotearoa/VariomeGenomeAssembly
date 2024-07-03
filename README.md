# He Kākano Variome Project Genome Assembly 

The [He Kākano project](https://www.genomics-aotearoa.org.nz/our-work/health-projects/aotearoa-nz-genomic-variome) is a [Genomics Aotearoa](https://www.genomics-aotearoa.org.nz/) funded project led by members of the University of Otago, University of Auckland, and Massey University in collaboration with the [Human Pangenome Reference Consortium](https://humanpangenome.org/) and [Silent Genomes Project](https://www.bcchr.ca/silent-genomes-project). 

This repo contains all relevant scripts and containerized tools for the genome assembly arm of the He Kākano project. The aim of this part of the project is to assemble six (currently) genomes of individuals with Māori ancestory to support analyses of the main arm of the He Kākano project by providing a more appropriate reference dataset. Note that no primary data is contained within this repo, only the workflow for the analyses. Test data is available from HG002 21q22.11.

Main contributors: Ben Halliday, Shane Sturrock, and David Markie

Acknowledgements: Julian Lucas and Ivo Violich

Publications: TBD. 

## Assumptions

1. Requires [Apptainer](https://apptainer.org/) (tested on version 1.3.1-1.el7).
2. Requires the following data types:
   - Nanopore Ultralong reads
   - High-quality long read data - ONT Duplex and/or PacBio HiFi
   - Phasing data - HiC and/or parental short read data
3. The workflow has been built under the assumption that the genome being assembled is Human. All stages should be transferable to other species, but have not been tested and specific parameters may need to be tailored to your target genome.
   
## Quick Links 

[Installation and Preparation](docs/Installation.md)

[Test Run](docs/TestRun.md)

[Assembly](docs/Assembly.md)

[Assembly QC](docs/QC.md)

[Assembly Annotation](docs/Annotation.md)
