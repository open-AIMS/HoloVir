#!/bin/bash
#
#SBATCH --cpus-per-task=2
#SBATCH --mem=6000
#SBATCH --nice=5000

# #SBATCH --output=log/blastp-%j.out
# #SBATCH --error=log/blastp-%j.err
# #SBATCH --job-name=H_blastp
# #SBATCH --mail-type=ALL
# #SBATCH --mail-user=othername@otherdomain.at

#echo "SLURM_JOBID="$SLURM_JOBID
#echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
#echo "SLURM_NNODES"=$SLURM_NNODES
#echo "SLURMTMPDIR="$TMPDIR
#echo "working directory = "$SLURM_SUBMIT_DIR

CHUNKSDIR=$1
BLASTDB=$2
BLASTTMPDIR=$3
LOCKDIR=$4

mkdir -p -m 2775 $BLASTTMPDIR $LOCKDIR

FILES2TRANSFER=$(rsync -a -n -v $BLASTDB* $BLASTTMPDIR/ | grep "^$(basename $BLASTDB)" | wc -l)
if [ $FILES2TRANSFER -gt 0 ] ; then
 ERROR=0
 #find $LOCKDIR -mmin +120 -name $LOCKDIR/rsync.lock -exec rm -f {} \;
 lockfile -$(shuf -i 5-33 -n 1) $LOCKDIR/rsync.lock
 rsync -a --delete $BLASTDB* $BLASTTMPDIR/ || ERROR=1
 rm -f $LOCKDIR/rsync.lock
 if [ $ERROR -eq 1 ] ; then
    echo "Error in syncing blast database - aborting."
    exit 1
 fi
fi

blastp -task blastp -num_threads 2 -db $BLASTTMPDIR/$(basename $BLASTDB) -query $CHUNKSDIR/chunk.${SLURM_ARRAY_TASK_ID} -evalue 1e-10 -outfmt 6 -max_target_seqs 1 | gzip > $CHUNKSDIR/chunk.${SLURM_ARRAY_TASK_ID}.blast.gz
#-outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen salltitles'

