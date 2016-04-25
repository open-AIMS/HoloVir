#!/bin/bash

. configfile.txt

PP_DATADIR=$(readlink -e $PP_DATADIR || { echo "data not found. Stop"; exit 1; })
SCRIPTS=$(readlink -e $SCRIPTS || { echo "Scripts directory not found. Stop"; exit 1; })
echo "scripts is $SCRIPTS"
echo "data dorectory is $PP_DATADIR"
echo "as dir is $AS_DIR"
AS_DIR=$(readlink -e $AS_DIR)
mkdir -p $AS_DIR
# prepare directory structure
DATADIR=$AS_DIR/data
echo "original data directory is $PP_DATADIR"
echo "new DATADIR is $DATADIR"
RESULTDIR=$AS_DIR/results
echo "DATADIR is $RESULTDIR"
mkdir -p $DATADIR $RESULTDIR
echo "the output dorectory will be $AS_DIR"

for DATASETF1 in $PP_DATADIR/*R1*; do
  DATASETF2=${DATASETF1/R1/R2}
  echo "datasetf1 is $DATASETF2"
  echo "datasetf2 is $DATASETF2"
  if [ ! -s $DATASETF1 -o ! -s $DATASETF2 -o $DATASETF1 == $DATASETF2 ]; then
    echo "missing file $DATASETF1 or $DATASETF2 or something wrong with the filenames !"
    exit 1
  fi

  BASE=$(printf "%s\n%s\n" $DATASETF1 $DATASETF2 | sed -e 'N;s/^\(.*\).*\n\1.*$/\1/')
  BASE=${BASE%R}; BASE=${BASE%_}; BASE=${BASE%-};
  BASE=$(basename $BASE | cut -f 1 -d .) 
  echo "base is $BASE"


   gunzip -c $DATASETF1 >$DATADIR/$BASE.R1.fastq 
   gunzip -c $DATASETF2 >$DATADIR/$BASE.R2.fastq
   #ho "pwd is $PWD"

  sbatch $SCRIPTS/ray.sh $BASE $AS_DIR
  #sbatch $SCRIPTS/trinity.sh $BASE $AS_DIR
done

