#!/bin/bash
#
#SBATCH --job-name=ray
#SBATCH --ntasks=16
#SBATCH --output=../log/ray-%j.out 
#SBATCH --error=../log/ray-%j.err
#SBATCH --mem=80000
#SBATCH --partition=mcore

module load ray
PREFIX=$1
DIRECTORY=$2
echo "prefix is $PREFIX"
echo "directory is $DIRECTORY"
#gunzip -c ${DIRECTORY}/03assembly/data/$PREFIX.R1.fastq.gz >$DIRECTORY/03assembly/data/$PREFIX.R1.fastq
F1=${DIRECTORY}/data/$PREFIX.R1.fastq
F2=${DIRECTORY}/data/$PREFIX.R2.fastq
echo "F1 is $F1 and F2 is $F2"
ls -la $F1
ls -la $F2
rmdir -p $DIRECTORY/results/$PREFIX.ray
#gunzip -c $DIRECTORY/03assembly/data/$PREFIX.R2.fastq.gz >$DIRECTORY/03assembly/data/$PREFIX.R2.fastq
#/usr/lib64/openmpi/bin/mpirun -n 16 Ray -k 31 -minimum-contig-length 1000 -use-minimum-seed-coverage 3 -p ${DIRECTORY}/03assembly/data/${PREFIX}.R1.fastq ${DIRECTORY}/03assembly/data/${PREFIX}.R2.fastq -o $TMPDIR/ray
#/usr/lib64/openmpi/bin/mpirun Ray -k 31 -minimum-contig-length 1000 -use-minimum-seed-coverage 3 -p $F1 $F2 -o $DIRECTORY/results/$PREFIX.ray
/usr/lib64/openmpi/bin/mpirun Ray -k 31 -minimum-contig-length 1000 -use-minimum-seed-coverage 3 -p $F1 $F2 -o $TMPDIR/ray
#/usr/lib64/openmpi/bin/mpirun Ray -k 31 -minimum-contig-length 1000 -use-minimum-seed-coverage 3 -p 03assembly/data/c12-2.R1.fastq 03assembly/data/c12-2.R2.fastq -o $DIRECTORY/results/$PREFIX.ray

#/usr/lib64/openmpi/bin/mpirun Ray -k 31 -minimum-contig-length 1000 -use-minimum-seed-coverage 3 -p 03assembly/data/c12-2.R1.fastq 03assembly/data/c12-2.R2.fastq -o 03assembly/results/c12-2.ray
#/usr/lib64/openmpi/bin/mpirun Ray -k 31 -minimum-contig-length 1000 -use-minimum-seed-coverage 3 -p $F1 $F2 -o /proj/aims/pipelinepaper/github/holovir/testdata_20160413/03assembly/results/ray
cp $TMPDIR/ray/Contigs.fasta $DIRECTORY/results/$PREFIX.ray.contigs.fasta
gzip $DIRECTORY/results/$PREFIX.ray.contigs.fasta

rm -rf $TMPDIR/*
