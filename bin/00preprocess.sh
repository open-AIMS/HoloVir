
. configfile.txt

PP_DIR=$(readlink -f $PP_DIR)
SCRIPTS=$(readlink -f $SCRIPTS)

RESULTDIR=$PP_DIR/results
LOGDIR=$PP_DIR/log

#mkdir -p $RESULTDIR $LOGDIR
for F1 in data/*R1*; do

  F2=${F1/R1/R2}

  if [ ! -s $F1 -o ! -s $F2 -o $F1 == $F2 ]; then
    echo "missing file $F1 or $F2 or something wrong with filenames !"
    exit 1
  fi

  # get BASE from filename
  #BASE=$(basename ${F1%%.fastq.gz})
  #BASE=${BASE/_R1/}

  # get BASE from longest common prefix
  BASE=$(printf "%s\n%s\n" $F1 $F2 | sed -e 'N;s/^\(.*\).*\n\1.*$/\1/')
  BASE=${BASE%R}; BASE=${BASE%_}; BASE=${BASE%-}; BASE=${BASE%.};
  BASE=$(basename $BASE)

  mkdir -p $LOGDIR/$BASE $RESULTDIR/$BASE

  sbatch -J Holovir_preprocess -o $LOGDIR/$BASE/preprocess-%j.out -e $LOGDIR/$BASE/preprocess-%j.err scripts/preprocess.sh $F1 $F2 $BASE $RESULTDIR $SCRIPTS

done

