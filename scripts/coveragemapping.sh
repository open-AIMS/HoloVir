#!/bin/bash
#
#SBATCH --job-name=contigmapping
#SBATCH --cpus-per-task=2
#SBATCH --output=../log/contigmapping-%j.out
#SBATCH --error=../log/contigmapping-%j.err
#SBATCH --mem=2000
. configfile.txt
SCRIPTS=$(readlink -e $SCRIPTS || { echo "scripts directory not found. Stop"; exit 1;})
CONTIGS=$1
READ1=$2
READ2=$3
OUTPUTPREFIX=$4
OUTPUTDIR=$5
GENES=$6

echo " the input contigs are $CONTIGS"
echo " the read files are $READ1 and $READ2"
echo " the output prefix is $OUTPUTPREFIX"
echo " the outputdir is $OUTPUTDIR"
echo " the genes is $GENES"
module load samtools bwa
mkdir -p $TMPDIR/mapping
bwa index $CONTIGS
echo "INDEXING DONE"
bwa mem -t 4 $CONTIGS $READ1 $READ2 >$TMPDIR/mapping/$OUTPUTPREFIX.grid.mappingmem.sam
echo "BWA MEM DONE"
samtools view -b -T $CONTIGS -S $TMPDIR/mapping/$OUTPUTPREFIX.grid.mappingmem.sam >$TMPDIR/mapping/$OUTPUTPREFIX.grid.mappingmem.bam
echo "samtools view done"
samtools sort -o $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.bam $TMPDIR/mapping/$OUTPUTPREFIX.grid.mappingmem.bam
echo "SAMTOOLS SORT DONE"
samtools index $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.bam
echo "SAMTOOLS INDEX DONE"
samtools idxstats $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.bam >$TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.stats
echo "SAMTOOLS IDXSTATS DONE"
samtools depth $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.bam >$TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.depth
echo "SAMTOOLS DEPTH DONE"
perl $SCRIPTS/fasta2genome.pl $CONTIGS >$TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.contiglengths
echo "fasta2genome done"
head $SCRIPTS/mappedmagnitudemaker.pl
ls -la $CONTIGS
ls -la $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.contiglengths
ls -la $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.depth
ls -la $GENES
perl $SCRIPTS/mappedmagnitudemaker.pl $CONTIGS $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.contiglengths $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.depth $GENES
perl $SCRIPTS/mappedmagnitudemaker.pl $CONTIGS $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.contiglengths $TMPDIR/mapping/$OUTPUTPREFIX.grid.sorted.mappingmem.depth ${GENES}a

echo "mappedmagnitudemaker"
mv $GENES.magnitude.fasta $GENES
mv ${GENES}a.magnitude.fasta ${GENES}a
rm $OUTPUTDIR/results/$OUTPUTPREFIX.contigs.mga.output
rm $OUTPUTDIR/data/$OUTPUTPREFIX.*.contigs.fasta.*
rm $OUTPUTDIR/data/$OUTPUTPREFIX.contigs.formatted.fa
rm $OUTPUTDIR/data/$OUTPUTPREFIX.*.contigs.fasta.magnitude.fasta
rm -rf $TMPDIR/*
gzip $GENES
gzip ${GENES}a
gzip $OUTPUTDIR/data/$OUTPUTPREFIX.*.fastq
gzip $OUTPUTDIR/data/$OUTPUTPREFIX.*.contigs.fasta


