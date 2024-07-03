[^Front Page](..)

[<Assembly QC](QC.md)

# Annotation

The following are some basic steps for assembly annotation. These are by no means comprehensive, as your assembly annotation needs will differ depending on the downstream uses of the given assembly. As with assembly QC, all steps are run using `Annotation_script.sh [Sample] [Assembler] [Mode]`.

## Repeat Annotation

[RepeatMasker](https://www.repeatmasker.org/) run as part of [TETools](https://github.com/Dfam-consortium/TETools) can be used to annotate repeatitive seqeunce in your genoem assembly. Note that human repeat elements are assumed (`--species human`), and the script will need to be tweak if annotating a non-human genome.

`Annotation_RepeatMasker.sh [Sample] [Assembler] [Mode]`

## Transcript Annotation

[LiftOff](https://github.com/agshumate/Liftoff) can be used to lift over GFF information from a reference sequence to your genome assembly (assuming the same or a closely related species). 

`Annotation_LiftOff.sh [Sample] [Assembler] [Mode]`

## Reference Sequence Annotation and Misjoin Check

[Minimap2](https://github.com/lh3/minimap2) can be used to create a `.paf` aligment file from a given reference sequence to your genome assembly. In addition, this script checks for misjoins based on the produced `.paf` file. Note that this script is currently mislabelled as 'CHM13' it should work on any reference sequence given.

`Annotation_CHM13Alignment.sh [Sample] [Assembler] [Mode]`
