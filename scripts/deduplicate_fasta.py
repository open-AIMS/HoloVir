#!/usr/bin/python

import sys, argparse
from collections import Counter
from Bio import SeqIO

#parser = argparse.ArgumentParser(
#  description='Remove duplicated sequences (based on sequence identifier) from a fasta file. Read from stdin, write to stdout.')
#parser.add_argument('infile', nargs='?', type=argparse.FileType('r'), default=sys.stdin)
#parser.add_argument('outfile', nargs='?', type=argparse.FileType('w'), default=sys.stdout)

#output = parser.parse_args()

infile = sys.stdin
outfile = sys.stdout
known = Counter()

for seq in SeqIO.parse(infile, "fasta"):
    known[seq.id] += 1
    #if known[seq.id] > 1:
    tmpid = seq.id.split('/TAXON_ID')[0] + str(known[seq.id]) + '|'
    seq.id = '/TAXON_ID'.join([tmpid, seq.id.split('/TAXON_ID')[1]])
    seq.description = seq.description.split(None, 1)[1]
    #print repr(seq.seq)
    #print len(seq)
    SeqIO.write(seq,outfile,"fasta")

