#!/bin/bash
set -e

. configfile.txt

MG_DATADIR=$(readlink -e $MG_DATADIR) || { echo "Data directory not found. Stop."; exit 1; }
SCRIPTS=$(readlink -e $SCRIPTS) || { echo "Scripts directory not found. Stop."; exit 1; }
MG_DIR=$(readlink -f $MG_DIR) || { echo "Folder structure not correct. Stop."; exit 1; }
MARKERDB=$(readlink -f $MARKERDB) || { echo "Database folder missing. Stop."; exit 1; }
MG_TMPDIR=$(readlink -m $MG_TMPDIR)

CHUNKSDIR=$MG_TMPDIR/chunks
LOGDIR=$MG_TMPDIR/log
LOCKDIR=$MG_TMPDIR/locks
DATADIR=$MG_DIR/data
RESULTDIR=$MG_DIR/results

# prepare directory structure
[ "$(ls -A $MG_DIR 2>/dev/null)" ] && { echo "$MG_DIR not empty. Stop."; exit 1; }
[ -n "$MG_TMPDIR" ] && rm -rf $MG_TMPDIR || { echo "MG_TMPDIR not set. Stop."; exit 1; }
mkdir -p $DATADIR $RESULTDIR $LOCKDIR
pushd $MG_DIR > /dev/null
[[ $MG_DIR != $MG_TMPDIR ]] && { ln -sf $CHUNKSDIR; ln -sf $LOGDIR; ln -sf $LOCKDIR; }

# prepare data
pushd $DATADIR > /dev/null
for SAMPLE in $(ls $MG_DATADIR/*.faa.gz); do
  echo "sample $(basename $SAMPLE)"
  ln -s $SAMPLE
done
popd > /dev/null
[ "$(ls -A $DATADIR)" ] || { echo "No data files found. Stop."; exit 1; } 

# check database
[[ ! -e $MARKERDB && ! -e ${MARKERDB}.gz ]] && { echo 'Marker db missing. Stop.'; exit 1; }
[[ ! -e ${MARKERDB}.phr ]] && { gunzip ${MARKERDB}.gz;
  makeblastdb -dbtype prot -in $MARKERDB -parse_seqids -hash_index -title $(basename $MARKERDB);
  gzip $MARKERDB; }


# split data files and submit jobs
for FILE in $DATADIR/* ; do
  echo "splitting $FILE..."
  BASE=$(basename $FILE)
  mkdir -p $CHUNKSDIR/$BASE $LOGDIR/$BASE
  zcat $FILE | $SCRIPTS/split_seqfile.py $CHUNKSDIR/$BASE/chunk $MG_CHUNKSIZE
  MAX=$(ls -v $CHUNKSDIR/$BASE/chunk.* | tail -1 | grep -o "[0-9]*$")
  jobID=$(sbatch -a 0-$MAX -J Holovir_MG_blast -o $LOGDIR/$BASE/blastp-%j.out -e $LOGDIR/$BASE/blastp-%j.err $SCRIPTS/blastp.sh $CHUNKSDIR/$BASE $MARKERDB $BLASTDBTMPDIR $LOCKDIR | grep -o "[0-9]*$")
  sbatch --dependency=afterok:$jobID -J Holovir_MG_concat -o $LOGDIR/$BASE/checkconcat-%j.out -e $LOGDIR/$BASE/checkconcat-%j.err $SCRIPTS/checkconcat.sh $CHUNKSDIR/$BASE $LOGDIR/$BASE $RESULTDIR
done

popd > /dev/null

