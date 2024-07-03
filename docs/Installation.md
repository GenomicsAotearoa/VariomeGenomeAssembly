[^Front Page](..)

## Installation

Build all the containers inside the `build_containers` directory:

    cd build
    ./buildall

When that finishes, it will give you a command you should add to your `.bashrc` which will allow the shell to find the newly built modules.

If you rerun the `buildall` script it won't delete the previous singularity containers but will overwrite the run scripts allowing you to build the containers on a system you have the rights to build containers on, and rsync the results to a system where you don't and rerunning `buildall` to handle the changes to the location. If you do want to get rid of the containers, run the `cleanall` script.

While the versions are all defined in the buildall file, there's a `version_check` script which will check for updates. Run it like this:

    ./version_check -av

Updates can be built using the specific tool's `build` command followed by the new version although you should check that there's a conda version available if it fails. The modulefile won't be written in the event of such a failure though.

## Preparation

Before running the workflow make sure you have modified `parameters.config` to set your Working_Directory and Resource_Directory. 

Key resources include reference information, including a `.fna`, `.cds.fasta.gz`, and `.gff.gz` for your reference. For human assemblies chm13 and hg38 reference information can be downloaded and formatted using `Utility-chm13pull.sh` and `Utility-hg38pull.sh`, respectively. Your genome of interest may be available to similarly download in the correct format from the [NCBI FTP site](https://ftp.ncbi.nlm.nih.gov/genomes/all/). Similarly more updated transcript information in `.gff3.gz` format is avaiable from the [Ensembl FTP site](http://ftp.ensembl.org/pub/) and human infromation can be downloaded using `Utility-ensemblpull.sh`, note that these files may need modification before using in the workflow.

[Test Run>](TestRun.md)

[Assembly>](Assembly.md)
