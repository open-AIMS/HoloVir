#!/usr/bin/python

import sys, os, argparse, random, gzip, itertools
from Bio.SeqIO.QualityIO import FastqGeneralIterator
from Bio import SeqIO
import Bio

fin = Bio.File.UndoHandle(sys.stdin)
firstline = fin.peekline()
if firstline.startswith('>'): ft, myiterator = "fasta", SeqIO.parse(fin, "fasta")
elif firstline.startswith('@'): ft, myiterator = "fastq", SeqIO.parse(fin, "fastq") 
else: sys.exit(1)

outfileprefix = sys.argv[1]
size = int(sys.argv[2])
seqs, newfileidx = [], -1
for ind, seq in enumerate(myiterator):
  if ind % size == 0:
      if seqs: SeqIO.write(seqs, "%s.%i" % (outfileprefix, newfileidx), ft)
      newfileidx += 1
      seqs = []
  seqs.append(seq)      
if seqs: SeqIO.write(seqs, "%s.%i" % (outfileprefix, newfileidx), ft)









