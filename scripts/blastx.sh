#!/bin/bash
#
#SBATCH --cpus-per-task=1
#SBATCH --mem=3000
#SBATCH --nice=5000
# #SBATCH --partition=mcore

# #SBATCH --output=log/blastx-%j.out
# #SBATCH --error=log/blastx-%j.err
# #SBATCH --job-name=H_blastx
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

blastx -task blastx -db $BLASTTMPDIR/$(basename $BLASTDB) -query $CHUNKSDIR/chunk.${SLURM_ARRAY_TASK_ID} -evalue 1e-4 -outfmt 6 | gzip > $CHUNKSDIR/chunk.${SLURM_ARRAY_TASK_ID}.blast.gz

