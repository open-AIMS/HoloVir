#!/bin/bash
set -e

. configfile.txt

EG_DATADIR=$(readlink -e $EG_DATADIR) || { echo "Data directory not found. Stop."; exit 1; }
EG_DIR=$(readlink -f $EG_DIR) || { echo "Folder structure not as expected. Stop."; exit 1; }
EG_TMPDIR=$(readlink -m $EG_TMPDIR)
BLASTDB=$(readlink -f $EGGNOGDB) || { echo "Database folder missing. Stop."; exit 1; }
NOG_MEMBERS=$(readlink -f $NOG_MEMBERS) || { echo "Folder structure not as expected. Stop."; exit 1; }
FUNCCATEGORIES=$(readlink -f $FUNCCATEGORIES) || { echo "Folder structure not as expected. Stop."; exit 1; }
SCRIPTS=$(readlink -e $SCRIPTS) || { echo "Scripts directory not found. Stop."; exit 1; }

CHUNKSDIR=$EG_TMPDIR/chunks
LOGDIR=$EG_TMPDIR/log
LOCKDIR=$EG_TMPDIR/locks
DATADIR=$EG_DIR/data
RESULTDIR=$EG_DIR/results
CHUNKSIZE=$EG_CHUNKSIZE
JOBNAMEBASE=Holovir_EG

# prepare directory structure
[ "$(ls -A $EG_DIR 2>/dev/null)" ] && { echo "$EG_DIR not empty. Stop."; exit 1; }
[ -n "$EG_TMPDIR" ] && rm -rf $EG_TMPDIR || { echo "EG_TMPDIR not set. Stop."; exit 1; }
mkdir -p $DATADIR $RESULTDIR $LOCKDIR
pushd $EG_DIR > /dev/null
[[ $EG_DIR != $EG_TMPDIR ]] && { ln -sf $CHUNKSDIR; ln -sf $LOGDIR; ln -sf $LOCKDIR; }

# prepare data
pushd $DATADIR > /dev/null
for SAMPLE in $(ls $EG_DATADIR/*faa.gz); do
  echo "sample $(basename $SAMPLE)"
  ln -s $SAMPLE
done
popd > /dev/null
[ "$(ls -A $DATADIR)" ] || { echo "No data files found. Stop."; exit 1; }

# prepare database and keywords
if [ ! -e ${BLASTDB}.phr -a ! -e ${BLASTDB}.00.phr ]; then
 if [ ! -e ${BLASTDB} ]; then
  if [ ! -e ${BLASTDB}.gz ]; then
   echo 'Getting eggNOG Fasta...'
   (cd $(dirname $BLASTDB) && wget -r --no-parent -nH --cut-dirs=10 $EGGNOGDB_ONLINE)
  fi
  # eggnog 4.1 all.proteins.fasta has a duplicated sequence. is this a problem?
  zcat ${BLASTDB}.gz | $SCRIPTS/remove_duplicates.py > ${BLASTDB} && rm ${BLASTDB}.gz
 fi
 # something weird happens here: if -hash_index is used, makeblastdb says that duplicate sequences are found
 makeblastdb -dbtype prot -in $BLASTDB -title $(basename $BLASTDB) && rm $BLASTDB
fi
if [ ! -e $NOG_MEMBERS ]; then
 (cd $(dirname $BLASTDB) && wget -r --no-parent -nH --cut-dirs=10 $NOG_MEMBERS_ONLINE)
fi
if [ ! -e $FUNCCATEGORIES ]; then
 (cd $(dirname $BLASTDB) && wget -r --no-parent -nH --cut-dirs=10 $FUNCCATEGORIES_ONLINE)
fi

# split data files and submit jobs
for FILE in $DATADIR/* ; do
  echo "splitting $FILE..."
  BASE=$(basename $FILE)
  mkdir -p $CHUNKSDIR/$BASE $LOGDIR/$BASE
  zcat $FILE | $SCRIPTS/split_seqfile.py $CHUNKSDIR/$BASE/chunk $CHUNKSIZE
  MAX=$(ls -v $CHUNKSDIR/$BASE/chunk.* | tail -1 | grep -o "[0-9]*$")
  jobID=$(sbatch -a 0-$MAX -J ${JOBNAMEBASE}_blast -o $LOGDIR/$BASE/blastp-%j.out -e $LOGDIR/$BASE/blastp-%j.err $SCRIPTS/blastp_eggnog.sh $CHUNKSDIR/$BASE $BLASTDB $BLASTDBTMPDIR $LOCKDIR | grep -o "[0-9]*$")
  sbatch --dependency=afterok:$jobID -J ${JOBNAMEBASE}_concat -o $LOGDIR/$BASE/checkconcat-%j.out -e $LOGDIR/$BASE/checkconcat-%j.err $SCRIPTS/checkconcat_eggnog.sh $CHUNKSDIR/$BASE $LOGDIR/$BASE $RESULTDIR $SCRIPTS $NOG_MEMBERS $FUNCCATEGORIES $FILE
done

popd > /dev/null

