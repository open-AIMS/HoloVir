#!/bin/bash
set -e

. configfile.txt

MR_DATADIR=$(readlink -e $MR_DATADIR) || { echo "Data directory not found. Stop."; exit 1; }
SCRIPTS=$(readlink -e $SCRIPTS) || { echo "Scripts directory not found. Stop."; exit 1; }
MR_DIR=$(readlink -f $MR_DIR) || { echo "Folder structure not as expected. Stop."; exit 1; }
MARKERDB=$(readlink -f $MARKERDB) || { echo "Database folder missing. Stop."; exit 1; }
MR_TMPDIR=$(readlink -m $MR_TMPDIR)

# prepare directory structure
CHUNKSDIR=$MR_TMPDIR/chunks
LOGDIR=$MR_TMPDIR/log
LOCKDIR=$MR_TMPDIR/locks
DATADIR=$MR_DIR/data
RESULTDIR=$MR_DIR/results
[ "$(ls -A $MR_DIR 2>/dev/null)" ] && { echo "$MR_DIR not empty. Stop."; exit 1; }
[ -n "$MR_TMPDIR" ] && rm -rf $MR_TMPDIR || { echo "MR_TMPDIR not set. Stop."; exit 1; }
mkdir -p $DATADIR $RESULTDIR $LOCKDIR
pushd $MR_DIR > /dev/null
[[ $MR_DIR != $MR_TMPDIR ]] && { ln -sf $CHUNKSDIR; ln -sf $LOGDIR; ln -sf $LOCKDIR; }

# prepare data
pushd $DATADIR > /dev/null
for SAMPLEDIR in $(ls -d $MR_DATADIR/*); do
  SAMPLE=$(basename $SAMPLEDIR) && echo "sample $SAMPLE"
  ln -s $SAMPLEDIR/${SAMPLE}.fasta.gz
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
  zcat $FILE | $SCRIPTS/split_seqfile.py $CHUNKSDIR/$BASE/chunk $MR_CHUNKSIZE
  MAX=$(ls -v $CHUNKSDIR/$BASE/chunk.* | tail -1 | grep -o "[0-9]*$")
  jobID=$(sbatch -a 0-$MAX -J Holovir_MR_blast -o $LOGDIR/$BASE/blastx-%j.out -e $LOGDIR/$BASE/blastx-%j.err $SCRIPTS/blastx.sh $CHUNKSDIR/$BASE $MARKERDB $BLASTDBTMPDIR $LOCKDIR | grep -o "[0-9]*$")
  sbatch --dependency=afterok:$jobID -J Holovir_MR_concat -o $LOGDIR/$BASE/checkconcat-%j.out -e $LOGDIR/$BASE/checkconcat-%j.err $SCRIPTS/checkconcat.sh $CHUNKSDIR/$BASE $LOGDIR/$BASE $RESULTDIR
done

popd > /dev/null

