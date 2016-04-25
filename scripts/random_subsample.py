#!/usr/bin/env python

import sys, os, argparse, random, gzip
from Bio.SeqIO.QualityIO import FastqGeneralIterator
from Bio import SeqIO

parser = argparse.ArgumentParser(description=\
          'This program outputs a user-defined amount of random reads from given fasta or fastq file(s). The amount can be given as number of reads, number of nucleotides/amino acids or percentage. Output is written to stdout. In case of two input files (paired-end data), the output is interleaved.')
parser.add_argument('-i', required=True, nargs='+', metavar='INFILE',
    help="input file(s) in fasta or fastq format (put both input files separated by a space for paired-end data)")
parser.add_argument('-nr', action="store", type=int, metavar='INT',
          help="target number of reads")
parser.add_argument('-nn', action="store", type=int, metavar='INT',
          help="target number of nucleotides/amino acids")
parser.add_argument('-p', action="store", type=float, metavar='0..1',
              help="percentage for downsampling")
#parser.add_argument('-o',action="store",nargs='*',required=False,\
#          default=['/dev/stdout'],help="specifies output files (default for single end is stdout)")

args = parser.parse_args()

# some argument checking
if not (args.nr or args.nn or args.p) or (args.nr and args.nn) or (args.nr and args.p) or (args.nn and args.p):
  print >> sys.stderr, '-nr or -nn or -p must be specified.'
  sys.exit(1)
if args.p:
  assert 0 < args.p < 1, 'if "-p" is given, it must be 0 < p < 1.'
assert 0 < len(args.i) < 3, 'No more than two input files (paired-end data) must be provided.'
pe_mode = False
if len(args.i) == 2: pe_mode = True

def open_file(infile):
  ''' open text or gzipped file for reading '''
  try:
    fin = gzip.open(infile)
    firstline = fin.readline()
  except IOError:
    fin = open(infile)
    firstline = fin.readline()
  fin.seek(0)
  return firstline, fin

def get_iterator(infile):
  ''' return Biopython iterator for fasta or fastq file '''
  firstline, fin = open_file(infile)
  if firstline[0] == '>':
    return "fasta", SeqIO.parse(fin, "fasta")
  elif firstline[0] == '@':
    return "fastq", FastqGeneralIterator(fin)
  else:
    print >> sys.stderr, "Input is not in fasta or fastq format."
    sys.exit(1)

def get_next_entry(ft, myiterator):
  ''' get next entry from Biopython iterator '''
  entry = myiterator.next()
  if ft == "fasta":
    return entry.id, str(entry.seq), ">%s\n%s" % (entry.id, str(entry.seq))
  elif ft == "fastq":
    return entry[0], entry[1], "@%s\n%s\n+\n%s" % (entry[0], entry[1], entry[2])

# set some variables
seq2seqlength = {}
infile = args.i[0]
if pe_mode: infile2 = args.i[1]
# go through file and remember sequence lengths
ft, myiterator = get_iterator(infile)
if pe_mode:
  ft2, myiterator2 = get_iterator(infile2)
  assert ft == ft2, 'Check input files.'
while True:
  try:
    id, seq, entry = get_next_entry(ft, myiterator)
    if pe_mode:
      try:
        id2, seq2, entry2 = get_next_entry(ft2, myiterator2)
        seq = seq + seq2
      except StopIteration: # this means that the second iterator is shorter than the first one
        raise Exception('The second input file contains fewer sequences than the first.')
    assert id not in seq2seqlength, "Some sequence IDs (e.g. %s) appear multiple times. That's not good for fasta/fastq files." % id
    seq2seqlength[id] = len(seq)
  except StopIteration:
    if pe_mode: # both iterators should be at their end. what's the best way to test this?
      try:
        myiterator2.next()
        print >> sys.stderr, 'The first input file contains fewer sequences than the second.'; sys.exit(1)
      except StopIteration:
        pass
    break
      
# get the random subset based on percentage, read number or nucleotide/amino acid number.
if args.p:
  args.nn = args.p * sum(seq2seqlength.values())

if args.nr:
  if pe_mode: args.nr = args.nr / 2 # only even read number in case of paired-end data.
  assert args.nr <= len(seq2seqlength), "Target number of reads is larger than number of reads in input file."
  selectedreadnames = set(random.sample(seq2seqlength.keys(), args.nr))
  #import pdb; pdb.set_trace()
elif args.nn:
  assert args.nn <= sum(seq2seqlength.values()), "Target number of nucleotides/amino acids is larger than number of nucleotides/amino acids in input file."
  selectedreadnames = set()
  mysum = 0
  keys = list(seq2seqlength.keys())
  random.shuffle(keys)
  for key in keys:
    if args.nn - mysum > abs(args.nn - (mysum + seq2seqlength[key])):
      selectedreadnames.add(key)
      mysum += seq2seqlength[key]
    else:
      break # it's important to break here to prevent any bias (e.g. for length) during read selection.
  assert selectedreadnames, "Target number of nucleotides/amino acids seems to be too small. Try a larger number."

# open the original file(s) again for reading and output the selected sequences
ft, myiterator = get_iterator(infile)
if pe_mode: ft2, myiterator2 = get_iterator(infile2)
while True:
  try:
    id, seq, entry = get_next_entry(ft, myiterator)
    if pe_mode:
      id2, seq2, entry2 = get_next_entry(ft2, myiterator2)
    if id in selectedreadnames:
      print >> sys.stdout, entry
      if pe_mode:
        print >> sys.stdout, entry2
  except StopIteration:
    break


