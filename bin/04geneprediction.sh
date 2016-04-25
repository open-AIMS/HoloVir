#!/bin/bash
. configfile.txt
GP_DATADIR=$(readlink -e $GP_DATADIR || { echo "data not found. Stop": exit 1;})
PP_DATADIR=$(readlink -e $PP_DATADIR || { echo "read directory not found. Stop"; exit 1;})
SCRIPTS=$(readlink -e $SCRIPTS || { echo "Scripts directory not found. Stop"; exit 1; })
echo "scripts is $SCRIPTS"
echo "data directory is $GP_DATADIR"
GP_DIR=$(readlink -e $GP_DIR)
rmdir -p $GP_DIR
mkdir -p $GP_DIR/data $GP_DIR/results
echo "revised data directory is $GP_DIR/data"
echo "revised data directory is $GP_DIR/results"
#for AS_DATASET in $GP_DATADIR/*; do
#  gunzip $AS_DATASET  
#done
gunzip $GP_DATADIR/*
ls -la $GP_DATADIR/
cp $GP_DATADIR/* $GP_DIR/data/.
gzip $GP_DATADIR/*
#gzip $GP_DIR/*
#ln -s $PWD/$CURRENTDIR/03assembly/results/$DATASET*contigs.fasta $PWD/$CURRENTDIR/04geneprediction/data/.
for DATASET in $GP_DIR/data/*; do
  echo "current dataset is $DATASET"
  BASE=$(basename $DATASET | cut -f 1 -d .)
  echo "base is $BASE"
  cat $DATASET | sed 's/>/>contig_/g' >$GP_DIR/data/$BASE.contigs.formatted.fa

  mga_linux_ia64 -m $GP_DIR/data/$BASE.contigs.formatted.fa >$GP_DIR/results/$BASE.contigs.mga.output
  perl $SCRIPTS/mgaoutputconverter.pl $GP_DIR/results/$BASE.contigs.mga.output $GP_DIR/data/$BASE.contigs.formatted.fa $GP_DIR/results/$BASE.contigs.mga2.fa
  cat $GP_DIR/results/$BASE.contigs.mga2.fa | sed 's/>contig_/>/g' >$GP_DIR/results/$BASE.contigs.mga.fa
  cat $GP_DIR/results/$BASE.contigs.mga2.faa | sed 's/>contig_/>/g' >$GP_DIR/results/$BASE.contigs.mga.faa
  rm $GP_DIR/results/$BASE.contigs.mga2.fa
  rm $GP_DIR/results/$BASE.contigs.mga2.faa
  gunzip -c $PP_DATADIR/$BASE*R1*f*q.gz >$GP_DIR/data/$BASE.R1.fastq 
  gunzip -c $PP_DATADIR/$BASE*R2*f*q.gz >$GP_DIR/data/$BASE.R2.fastq
#ln -s $PWD/data/$DATASET.R1.fastq $PWD/$CURRENTDIR/04geneprediction/data/$BASE.R1.fastq
#ln -s $PWD/data/$DATASET.R2.fastq $PWD/data/$BASE.R2.fastq
sbatch $SCRIPTS/coveragemapping.sh $GP_DIR/data/$BASE.*.contigs.fasta $GP_DIR/data/$BASE.R1.fastq $GP_DIR/data/$BASE.R2.fastq $BASE $GP_DIR $GP_DIR/results/$BASE.contigs.mga.fa
done
