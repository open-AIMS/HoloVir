#!/usr/bin/env python
from Bio import SeqIO
import sys, gzip, re
from operator import itemgetter
from collections import Counter

bxfilename = sys.argv[1]
ogfilename = sys.argv[2]
flfilename = sys.argv[3]
try:
  magnitudefilename = sys.argv[4]
  use_magnitudes = 1
except KeyError:
  use_magnitudes = 0

magic_dict = {
  "\x1f\x8b\x08" : "gz",
  "\x42\x5a\x68": "bz2",
  "\x50\x4b\x03\x04": "zip" }

max_lenF = max(len(x) for x in magic_dict)
def file_type(filename):
  with open(filename) as fin:
    file_start = fin.read(max_lenF)
  for magic, filetype in magic_dict.items():
    if file_start.startswith(magic):
      return filetype
  return "text"


# get magnitude values from query fasta file
if use_magnitudes:
  magnitude_by_name={}
  #we currently assume a FASTA formatted sequence file with magnitudes in header such as for MEGAN
  if file_type(magnitudefilename) == "gz": fin = gzip.open(magnitudefilename)
  elif file_type(magnitudefilename) == "text": fin = open(magnitudefilename)
  #else: 1/0
  magnitudepattern=re.compile(r".*magnitude=(\d+).*")
  for entry in SeqIO.parse(fin, "fasta"):
    magnitudematch = magnitudepattern.match(entry.description)
    if not magnitudematch:
      magnitude_by_name[entry.id]=1
      sys.stderr.write("could not extract magnitude for protein %s from header %s, assuming magnitude=1.\n" % (entry.id, entry.description))
    else:
      magnitude_by_name[entry.id]=int(magnitudematch.group(1))


# get NOG functions from NOG members file
scount = 0
functions_by_name = {}
if file_type(ogfilename) == "gz": fin = gzip.open(ogfilename)
elif file_type(ogfilename) == "text": fin = open(ogfilename)
#else: 1/0
for line in fin:
  parts = line.strip().split("\t")
  functions = set(parts[4])
#  functions = set(parts[1])
  for name in parts[5].split(","):
#  for name in parts[2].split(","):
    functions_by_name.setdefault(name, set()).update(functions)
fin.close()


# count keywords in blast results
tcount=0
count_by_f1 = Counter()
if file_type(bxfilename) == "gz": fin = gzip.open(bxfilename)
elif file_type(bxfilename) == "text": fin = open(bxfilename)
#else: 1/0
for line in fin:
  parts = line.strip().split("\t")
  if len(parts) > 2:
    name = parts[1]
    if functions_by_name.has_key(name):
      keywords = functions_by_name[name]
      for kw in keywords:   
        magnitude = 1
        if use_magnitudes:
          qname = parts[0]
          try:
            magnitude = magnitude_by_name[qname]
          except KeyError:
            sys.stderr.write("Protein %s present in BLAST file but not in magnitude file, assuming magnitude=1.\n" % qname)
        tcount += magnitude
        count_by_f1[kw] += magnitude
#      for fl in functions_by_name[name]:  #          if not count_by_fl.has_key(fl):  #            count_by_fl[fl]=0 #          count_by_fl[fl]=count_by_fl[fl]+1
fin.close()


# output results
if file_type(flfilename) == "gz": fin = gzip.open(flfilename)
elif file_type(flfilename) == "text": fin = open(flfilename)
#else: 1/0
for line in fin:
  if line.startswith(" ["):
    fl = line[2]
    fd = line[5:].strip()
    count = 0
    if fl in count_by_f1:
      count = count_by_f1[fl]
    sys.stdout.write("%s\t%i\t%s\n" % (fl,count,fd))

