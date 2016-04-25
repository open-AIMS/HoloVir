#!/bin/bash
set -e

. configfile.txt

RG_DATADIR=$(readlink -e $RG_DATADIR) || { echo "Data directory not found. Stop."; exit 1; }
SCRIPTS=$(readlink -e $SCRIPTS) || { echo "Scripts directory not found. Stop."; exit 1; }
RG_DIR=$(readlink -f $RG_DIR) || { echo "Folder structure not as expected. Stop."; exit 1; }
VIRREFSEQ=$(readlink -f $VIRREFSEQ) || { echo "Database folder missing. Stop."; exit 1; }
RG_TMPDIR=$(readlink -m $RG_TMPDIR)

CHUNKSDIR=$RG_TMPDIR/chunks
LOGDIR=$RG_TMPDIR/log
LOCKDIR=$RG_TMPDIR/locks
DATADIR=$RG_DIR/data
RESULTDIR=$RG_DIR/results

# prepare directory structure
[ "$(ls -A $RG_DIR 2>/dev/null)" ] && { echo "$RG_DIR not empty. Stop."; exit 1; }
[ -n "$RG_TMPDIR" ] && rm -rf $RG_TMPDIR || { echo "RG_TMPDIR not set. Stop."; exit 1; }
mkdir -p $DATADIR $RESULTDIR $LOCKDIR
pushd $RG_DIR > /dev/null
[[ $RG_DIR != $RG_TMPDIR ]] && { ln -sf $CHUNKSDIR; ln -sf $LOGDIR; ln -sf $LOCKDIR; }

# prepare data
pushd $DATADIR > /dev/null
for SAMPLE in $(ls $RG_DATADIR/*.faa.gz); do
  echo "sample $(basename $SAMPLE)"
  ln -s $SAMPLE
done
popd > /dev/null
[ "$(ls -A $DATADIR)" ] || { echo "No data files found. Stop."; exit 1; } 

# prepare database
if [ ! -e ${VIRREFSEQ}.phr -a ! -e ${VIRREFSEQ}.00.phr ]; then
 if [ ! -e ${VIRREFSEQ} ]; then
  wget -r --no-parent -nH --cut-dirs=10 -A "viral.[0-9]*.protein.faa.gz" ftp://ftp.ncbi.nlm.nih.gov/refseq/release/viral/
  zcat $(ls -v viral.*.protein.faa.gz) > $VIRREFSEQ && rm viral.*.protein.faa.gz
 fi
 makeblastdb -dbtype prot -in $VIRREFSEQ -parse_seqids -hash_index -title $(basename $VIRREFSEQ) && rm $VIRREFSEQ
fi


# split data files and submit jobs
for FILE in $DATADIR/* ; do
  echo "splitting $FILE..."
  BASE=$(basename $FILE)
  mkdir -p $CHUNKSDIR/$BASE $LOGDIR/$BASE
  zcat $FILE | $SCRIPTS/split_seqfile.py $CHUNKSDIR/$BASE/chunk $RG_CHUNKSIZE
  MAX=$(ls -v $CHUNKSDIR/$BASE/chunk.* | tail -1 | grep -o "[0-9]*$")
  jobID=$(sbatch -a 0-$MAX -J Holovir_RG_blast -o $LOGDIR/$BASE/blastp-%j.out -e $LOGDIR/$BASE/blastp-%j.err $SCRIPTS/blastp.sh $CHUNKSDIR/$BASE $VIRREFSEQ $BLASTDBTMPDIR $LOCKDIR | grep -o "[0-9]*$")
  sbatch --dependency=afterok:$jobID -J Holovir_RG_concat -o $LOGDIR/$BASE/checkconcat-%j.out -e $LOGDIR/$BASE/checkconcat-%j.err $SCRIPTS/checkconcat.sh $CHUNKSDIR/$BASE $LOGDIR/$BASE $RESULTDIR
done

popd > /dev/null

