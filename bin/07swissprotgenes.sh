#!/bin/bash
set -e

. configfile.txt

SG_DATADIR=$(readlink -e $SG_DATADIR) || { echo "Data directory not found. Stop."; exit 1; }
SCRIPTS=$(readlink -e $SCRIPTS) || { echo "Scripts directory not found. Stop."; exit 1; }
SG_DIR=$(readlink -f $SG_DIR) || { echo "Folder structure not as expected. Stop."; exit 1; }
BLASTDB=$(readlink -f $SPROTDB) || { echo "Database folder missing. Stop."; exit 1; }
SPROTKW=$(readlink -f $SPROTKW) || { echo "Folder structure not as expected. Stop."; exit 1; }
SG_TMPDIR=$(readlink -m $SG_TMPDIR)

CHUNKSDIR=$SG_TMPDIR/chunks
LOGDIR=$SG_TMPDIR/log
LOCKDIR=$SG_TMPDIR/locks
DATADIR=$SG_DIR/data
RESULTDIR=$SG_DIR/results
CHUNKSIZE=$SG_CHUNKSIZE
JOBNAMEBASE=Holovir_SG

# prepare directory structure
[ "$(ls -A $SG_DIR 2>/dev/null)" ] && { echo "$SG_DIR not empty. Stop."; exit 1; }
[ -n "$SG_TMPDIR" ] && rm -rf $SG_TMPDIR || { echo "SG_TMPDIR not set. Stop."; exit 1; }
mkdir -p $DATADIR $RESULTDIR $LOCKDIR
pushd $SG_DIR > /dev/null
[[ $SG_DIR != $SG_TMPDIR ]] && { ln -sf $CHUNKSDIR; ln -sf $LOGDIR; ln -sf $LOCKDIR; }

# prepare data
pushd $DATADIR > /dev/null
for SAMPLE in $(ls $SG_DATADIR/*faa.gz); do
  echo "sample $(basename $SAMPLE)"
  ln -s $SAMPLE
done
popd > /dev/null
[ "$(ls -A $DATADIR)" ] || { echo "No data files found. Stop."; exit 1; }

# prepare database and keywords
if [ ! -e ${BLASTDB}.phr ]; then
 if [ ! -e ${BLASTDB} ]; then
  if [ ! -e ${BLASTDB}.gz ]; then
   echo 'Getting Uniprot/Swissprot...'
   #UNIPROT_SPROT_FASTA=ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz
   (cd $(dirname $BLASTDB) && wget -r --no-parent -nH --cut-dirs=10 $UNIPROT_SPROT_FASTA)
  fi
  gunzip ${BLASTDB}.gz
 fi
 makeblastdb -dbtype prot -in $BLASTDB -parse_seqids -hash_index -title $(basename $BLASTDB) && rm $BLASTDB
fi
if [ ! -e $SPROTKW ]; then
 if [ ! -e $(dirname $SPROTKW)/uniprot_sprot.xml.gz ]; then
  #UNIPROT_SPROT_XML=ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.xml.gz
  (cd $(dirname $SPROTKW) && wget -r --no-parent -nH --cut-dirs=10 $UNIPROT_SPROT_XML)
 fi
 echo "Preparing keyword file from Uniprot/Swissprot..."
 $SCRIPTS/uniprotXML2keywords.py $(dirname $SPROTKW)/uniprot_sprot.xml.gz $SPROTKW && rm $(dirname $SPROTKW)/uniprot_sprot.xml.gz
fi

# split data files and submit jobs
for FILE in $DATADIR/* ; do
  echo "splitting $FILE..."
  BASE=$(basename $FILE)
  mkdir -p $CHUNKSDIR/$BASE $LOGDIR/$BASE
  zcat $FILE | $SCRIPTS/split_seqfile.py $CHUNKSDIR/$BASE/chunk $CHUNKSIZE
  MAX=$(ls -v $CHUNKSDIR/$BASE/chunk.* | tail -1 | grep -o "[0-9]*$")
  jobID=$(sbatch -a 0-$MAX -J ${JOBNAMEBASE}_blast -o $LOGDIR/$BASE/blastp-%j.out -e $LOGDIR/$BASE/blastp-%j.err $SCRIPTS/blastp_swissprot.sh $CHUNKSDIR/$BASE $BLASTDB $BLASTDBTMPDIR $LOCKDIR | grep -o "[0-9]*$")
  sbatch --dependency=afterok:$jobID -J ${JOBNAMEBASE}_concat -o $LOGDIR/$BASE/checkconcat-%j.out -e $LOGDIR/$BASE/checkconcat-%j.err $SCRIPTS/checkconcat_swissprot.sh $CHUNKSDIR/$BASE $LOGDIR/$BASE $RESULTDIR $SCRIPTS $SPROTKW $FILE 
done

popd > /dev/null

