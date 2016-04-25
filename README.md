# HoloVir 1.0 
HoloVir is a robust and flexible data analysis pipeline that provides an optimised and validated workflow for taxonomic and functional characterisation of viral metagenomes

Dependencies
---
- [BBMAP 35](sourceforge.net/projects/bbmap/)  
- [BioPerl 1.6.923](http://bioperl.org)  
- [BioPython 1.66](http://biopython.org/)  
- [BLAST 2.2.29+](http://doi.org/10.1186/1471-2105-10-421)
- [BWA 0.7.12](http://doi.org/10.1093/bioinformatics/btp324)  
- [Cd-hit 4.6](http://doi.org/10.1093/bioinformatics/btl158)  
- [FastQC 0.11.5](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/)  
- [MetaGeneAnnotator](http://dx.doi.org/10.1093%2Fdnares%2Fdsn027)  
- [PEAR 0.9.8](http://doi.org/10.1093/bioinformatics/btt593)  
- [Perl 5](https://www.perl.org)  
- [Python 2.7](https://www.python.org)  
- [Ray 2.3.1](http://dx.doi.org/doi:10.1186/gb-2012-13-12-r122)  
- [Samtools 1.3](http://doi.org/10.1093/bioinformatics/btp352)  
- [Slurm Workload Manager](http://slurm.schedmd.com/)  
- [Trinity 2.2.0](http://doi.org/10.1038/nprot.2013.084)  

Given version are those tested; HoloVir might also work with other tool versions.

Usage
---
Create an empty project directory. Copy the configfile.txt (with all necessary paths and file names) into it. Copy or symlink the folders bin, scripts and db into it.
The bin folder contains scripts which should be run in succession:

00preprocessing -> 01refseqreads, 02markerreads, 03assembly -> 04geneprediction -> 05refseqgenes, 06markergenes, 07swissprotgenes, 08eggnoggenes.

Some scripts can be run simultaneously (separated by comma), while others need to be run after the previous step finished (separated by arrow).
The bin scripts are run without arguments from the created project directory.

The HoloVir manuscript reports the use of CLC Genomics Workbench for sequence preprocessing and assembly steps.
If users have access to this commercial software, the configfile can be adjusted to CLC genomics workbench preprocessing and assembly to the subsequent components of HoloVir. As an alternative, freely available tools have been included to complete sequence QC, preprocessing and assembly (FastQC, Pear and BBMAP for quality control and sequence preprocessing steps; Trinity and Ray for assembly).  

HoloVir has been written to submit batch jobs to Slurm workload manager.
If an alternative workload manager is required, scripts that make use of SLURM need to be modified accordingly. These are all scripts in the bin/ directory and a number of scripts in the scripts/ directory (they contain instructions like #SBATCH or sbatch).  
