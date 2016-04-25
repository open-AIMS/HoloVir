#!/bin/bash
#
#SBATCH --job-name=trinity
#SBATCH --cpus-per-task=2
#SBATCH --output=../log/trinity-%j.out
#SBATCH --error=../log/trinity-%j.err
#SBATCH --mem=2000
#SBATCH --partition=mcore
echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST="$SLURM_JOB_NODELIST
echo "SLURM_NNODES="$SLURM_NNODES
echo "working directory = "$SLURM_SUBMIT_DIR

module load trinityrnaseq bowtie2
PREFIX=$1
DIRECTORY=$2
echo "prefix is $PREFIX and directory is $DIRECTORY"
echo "left file is ${DIRECTORY}/data/${PREFIX}.R1.fastq"
ls -l ${DIRECTORY}/data/${PREFIX}.R1.fastq
echo "right file is ${DIRECTORY}/data/${PREFIX}.R2.fastq"
ls -l ${DIRECTORY}/data/${PREFIX}.R2.fastq  
#Trinity --seqType fq --left ${DIRECTORY}/data/${PREFIX}.R1.fastq --right ${DIRECTORY}/data/${PREFIX}.R2.fastq --output $TMPDIR/trinity --min_contig_length 1000 --CPU 2 --max_memory 100G --no_bowtie
echo "left is"
ls -la /proj/aims/pipelinepaper/github/holovir/testdata_20160413/03assembly/data/c12-2.R1.fastq
echo "right is"
ls -la /proj/aims/pipelinepaper/github/holovir/testdata_20160413/03assembly/data/c12-2.R2.fastq
Trinity --seqType fq --max_memory 100G --left /proj/aims/pipelinepaper/github/holovir/testdata_20160413/03assembly/data/c12-2.R1.fastq --right /proj/aims/pipelinepaper/github/holovir/testdata_20160413/03assembly/data/c12-2.R2.fastq  
#Trinity --seqType fq --left /proj/aims/pipelinepaper/github/holovir/testdata_20160413/03assembly/data/c12-2.R1.fastq --right /proj/aims/pipelinepaper/github/holovir/testdata_20160413/03assembly/data/c12-2.R2.fastq --output /proj/aims/pipelinepaper/github/holovir/testdata_20160413/03assembly/results/trinity --full_cleanup --min_contig_length 1000 --CPU 2 --max_memory 100G --no_bowtie

#cp $TMPDIR/trinity.Trinity.fasta ${DIRECTORY}/results/$PREFIX.trinity.contigs.fasta
#rm -rf $TMPDIR/*
