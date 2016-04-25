#!/bin/bash
#
#SBATCH --cpus-per-task=1
#SBATCH --mem=5000
#SBATCH --nice=1000
# #SBATCH --partition=mcore

# #SBATCH --output=log/preprocess-%j.out
# #SBATCH --error=log/preprocess-%j.err
# #SBATCH --job-name=H_preprocess
# #SBATCH --mail-type=ALL
# #SBATCH --mail-user=othername@otherdomain.at

#echo "SLURM_JOBID="$SLURM_JOBID
#echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
#echo "SLURM_NNODES"=$SLURM_NNODES
#echo "SLURMTMPDIR="$TMPDIR
#echo "working directory = "$SLURM_SUBMIT_DIR

F1=$(readlink -f $1)
F2=$(readlink -f $2)
BASE=$3
OUTDIR=$(readlink -f $4)
SCRIPTDIR=$(readlink -f $5)
#LOCKDIR=
#ADAPTERS0=$BBTOOLS/resources/adapters.fa
#ADAPTERS1=$TRIMMOMATIC/adapters/NexteraPE-PE.fa
#ADAPTERS2=$BBTOOLS/resources/nextera.fa.gz

# copy files to local storage?
#lockfile -$(echo "print 10+int(rand(10));" | perl) rsync.lock
##rsync -a --delete --copy-links $F1 $F2 $TMPDIR/ || ERROR=1
#cp $F1 $F2 $TMPDIR
#rm -f rsync.lock
#F1=$(basename $F1)
#F2=$(basename $F2)

pushd $TMPDIR

mkdir ${BASE}_fastqc
fastqc -o ${BASE}_fastqc $F1 $F2

# look for adapters
#bbmerge.sh in1=$F1 in2=$F2 outadapter=adapters.fa  # in case we have no clue at all

# remove adapters (not needed for pear)
#$BBTOOLS/bbduk.sh in=$F1 in2=$F2 out=$BASE.R1.trimmed.fq out2=$BASE.R2.trimmed.fq ref=$ADAPTERS3 ktrim=r k=23 mink=11 hdist=1 tbo tpe 2>$BASE.bbduk.log

# merge overlapping reads
pear -f $F1 -r $F2 -o $BASE
gzip ${BASE}.discarded.fastq
mv ${BASE}.assembled.fastq ${BASE}.merged.fastq
mv ${BASE}.unassembled.forward.fastq ${BASE}.unmerged.forward.fastq
mv ${BASE}.unassembled.reverse.fastq ${BASE}.unmerged.reverse.fastq
#bbmerge.sh in1=$F1 in2=$F2 out=merged.fq outu1=unmerged1.fq outu2=unmerged2.fq

# size distribution
readlength.sh in=${BASE}.merged.fastq out=${BASE}.merged.fastq.hist.txt

# connect unmerged reads
# note: pear outputs reverse complement for reverse reads, however fuse.sh also reverse-complements the reads.
reformat.sh in=${BASE}.unmerged.reverse.fastq out=${BASE}.unmerged.reverse.fastq.rc rcomp=t
fuse.sh in1=${BASE}.unmerged.forward.fastq in2=${BASE}.unmerged.reverse.fastq.rc out=${BASE}.fused.fastq pad=10 fusepairs=t
$SCRIPTDIR/fastq2fasta.py <${BASE}.fused.fastq >${BASE}.fused.fasta

# dereplicate
cat ${BASE}.merged.fastq | $SCRIPTDIR/fastq2fasta.py > ${BASE}.merged.fasta
cd-hit-est -i ${BASE}.merged.fasta -o ${BASE}.merged.nr99.fasta -c 0.99 -M 0 -d 0 -s 0.9

# add magnitudes to fasta
perl $SCRIPTDIR/magnitudemaker.pl ${BASE}.merged.nr99.fasta ${BASE}.merged.nr99.fasta.clstr && mv ${BASE}.merged.nr99.fasta.magnitude.fasta ${BASE}.merged.nr99.fasta
perl $SCRIPTDIR/singlemagnitudes.pl ${BASE}.fused.fasta && mv ${BASE}.fused.fasta.magnitude.fasta ${BASE}.fused.fasta

# combine merged and fused reads
cat ${BASE}.merged.nr99.fasta ${BASE}.fused.fasta > ${BASE}.fasta

# return results
mkdir -p $OUTDIR/$BASE
gzip ${BASE}.merged.fastq ${BASE}.merged.nr99.fasta ${BASE}.merged.nr99.fasta.clstr ${BASE}.fused.fasta ${BASE}.fasta
cp -r ${BASE}_fastqc ${BASE}.discarded.fastq.gz ${BASE}.merged.fastq.gz ${BASE}.merged.fastq.hist.txt ${BASE}.fasta.gz $OUTDIR/$BASE

# some info
# bbduk: http://seqanswers.com/forums/archive/index.php/t-47104.html
# miseq data processing: http://seqanswers.com/forums/archive/index.php/t-63740.html
# bbmerge: http://seqanswers.com/forums/showthread.php?t=43906
# bbtools: http://seqanswers.com/forums/archive/index.php/t-58221.html
