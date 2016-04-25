#!/bin/bash
#
#SBATCH --cpus-per-task=1
#SBATCH --mem=5000
#SBATCH --nice=5000

# #SBATCH --partition=mcore
# #SBATCH --output=log/checkconcat-%j.out
# #SBATCH --error=log/checkconcat-%j.err
# #SBATCH --job-name=concat
# #SBATCH --mail-type=ALL
# #SBATCH --mail-user=othername@otherdomain.at

CHUNKSDIR=$1
LOGDIR=$2
RESULTDIR=$3
SCRIPTS=$4
NOG_MEMBERS=$5
FUNCCATEGORIES=$6
FASTAFILE=$7

WARNING="Could not calculate ungapped Karlin-Altschul parameters"
#WARNING2="slurm_receive_msg: Socket timed out on send/recv operation"
NLOGLINES=$(cat $LOGDIR/blast* | grep -v "$WARNING" | grep -v "$WARNING2" | grep -v "^$" | wc -l)
if [ $NLOGLINES -gt 0 ] ; then
  MSG="problems in log files:"
  echo $MSG
  cat $LOGDIR/blast* | grep -v "$MSG" | grep -v "$WARNING"
  exit 1
fi

mkdir -p $RESULTDIR
MISSING=$(diff <(ls -v $CHUNKSDIR/*[0-9]) <(ls -v $CHUNKSDIR/*blast.gz | sed 's/.blast.gz//'))
[[ -n "$MISSING" ]] && { echo "some blast results missing: $MISSING"; exit 1; }

OUTFILE=$(basename ${CHUNKSDIR%.gz}).blast.gz
echo "concatenating $OUTFILE"
cat $(ls -v $CHUNKSDIR/*.blast.gz) > $RESULTDIR/$OUTFILE
[ ! -s $RESULTDIR/$OUTFILE ] && { echo "Blast file empty. Stop."; exit 1; }

# clean up
rm -r $CHUNKSDIR
rmdir $(dirname $CHUNKSDIR) 2>/dev/null && rm -f $(dirname $RESULTDIR)/chunks
rmdir $(readlink -f $(dirname $RESULTDIR)/locks) 2>/dev/null && rm -f $(dirname $RESULTDIR)/locks

# count function labels
$SCRIPTS/count_functionlabels_magnitude.py $RESULTDIR/$OUTFILE $NOG_MEMBERS $FUNCCATEGORIES $FASTAFILE > $RESULTDIR/${OUTFILE}.funclabelcount.txt

