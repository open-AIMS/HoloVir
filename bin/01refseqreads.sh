#!/bin/bash
set -e

. configfile.txt

RR_DATADIR=$(readlink -e $RR_DATADIR) || { echo "Data directory not found. Stop."; exit 1; }
SCRIPTS=$(readlink -e $SCRIPTS) || { echo "Scripts directory not found. Stop."; exit 1; }
RR_DIR=$(readlink -f $RR_DIR) || { echo "Folder structure not as expected. Stop."; exit 1; }
VIRREFSEQ=$(readlink -f $VIRREFSEQ) || { echo "Database folder missing. Stop."; exit 1; }
RR_TMPDIR=$(readlink -m $RR_TMPDIR)

# prepare directory structure
CHUNKSDIR=$RR_TMPDIR/chunks
LOGDIR=$RR_TMPDIR/log
LOCKDIR=$RR_TMPDIR/locks
DATADIR=$RR_DIR/data
RESULTDIR=$RR_DIR/results
[ "$(ls -A $RR_DIR 2>/dev/null)" ] && { echo "$RR_DIR not empty. Stop."; exit 1; }
[ -n "$RR_TMPDIR" ] && rm -rf $RR_TMPDIR || { echo "RR_TMPDIR not set. Stop."; exit 1; }
mkdir -p $DATADIR $RESULTDIR $LOCKDIR
pushd $RR_DIR >/dev/null
[[ $RR_DIR != $RR_TMPDIR ]] && { ln -sf $CHUNKSDIR; ln -sf $LOGDIR; ln -sf $LOCKDIR; }

# prepare data
pushd $DATADIR > /dev/null
for SAMPLEDIR in $(ls -d $RR_DATADIR/*); do
  SAMPLE=$(basename $SAMPLEDIR) && echo "sample $SAMPLE"
  ln -s $SAMPLEDIR/${SAMPLE}.fasta.gz
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
  zcat $FILE | $SCRIPTS/split_seqfile.py $CHUNKSDIR/$BASE/chunk $RR_CHUNKSIZE
  MAX=$(ls -v $CHUNKSDIR/$BASE/chunk.* | tail -1 | grep -o "[0-9]*$")
  jobID=$(sbatch -a 0-$MAX -J Holovir_RR_blast -o $LOGDIR/$BASE/blastx-%j.out -e $LOGDIR/$BASE/blastx-%j.err $SCRIPTS/blastx.sh $CHUNKSDIR/$BASE $VIRREFSEQ $BLASTDBTMPDIR $LOCKDIR | grep -o "[0-9]*$")
  sbatch --dependency=afterok:$jobID -J Holovir_RR_concat -o $LOGDIR/$BASE/checkconcat-%j.out -e $LOGDIR/$BASE/checkconcat-%j.err $SCRIPTS/checkconcat.sh $CHUNKSDIR/$BASE $LOGDIR/$BASE $RESULTDIR
done

popd >/dev/null
