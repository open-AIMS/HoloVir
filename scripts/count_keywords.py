#!/usr/bin/env python

from Bio import SeqIO
import sys, gzip,re
from operator import itemgetter
from collections import Counter

bxfilename = sys.argv[1]
kwfilename = sys.argv[2]
outprefix = sys.argv[3]
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


# get magnitudes from query fasta file
if use_magnitudes:
  magnitude_by_name={}
  # We currently assume a FASTA formatted sequence file with magnitudes in header such as for MEGAN
  magnitudepattern=re.compile(r".*magnitude=(\d+).*")
  if file_type(magnitudefilename) == "gz": fin = gzip.open(magnitudefilename)
  elif file_type(magnitudefilename) == "text": fin = open(magnitudefilename)
  #else: 1/0
  for entry in SeqIO.parse(fin, "fasta"):
    assert entry.id not in magnitude_by_name
    magnitudematch = magnitudepattern.match(entry.description)    if not magnitudematch:
      magnitude_by_name[entry.id] = 1
      sys.stderr.write("Could not extract magnitude for protein %s from header %s, assuming magnitude=1.\n" % (entry.id, entry.description))
    else:
      magnitude_by_name[entry.id] = int(magnitudematch.group(1))


# count protein-specific keywords from swissprot protein database
scount = 0
scount_by_kw = Counter()
keywords_by_swissprotid = {}
if file_type(kwfilename) == "gz": fin = gzip.open(kwfilename)
elif file_type(kwfilename) == "text": fin = open(kwfilename)
#else: 1/0
for line in fin:
  parts = line.strip().split("\t")
  (name, description) = parts[:2]
  keywords = parts[2:]
  keywords_by_swissprotid[name] = keywords
  for kw in keywords:
    scount += 1
    scount_by_kw[kw] += 1
fin.close()


# count keywords of blast hits of query fasta to swissprot database
tcount = 0
tcount_by_kw = Counter()
annotated_or_not = { "annotated": [], "not_annotated": [] }
if file_type(bxfilename) == "gz": fin = gzip.open(bxfilename)
elif file_type(bxfilename) == "text": fin = open(bxfilename)
#else: 1/0
for ind, line in enumerate(fin):
  parts = line.strip().split("\t")
  if len(parts) > 2:
    spname = parts[1].split("|")[01]
    assert spname
    if keywords_by_swissprotid.has_key(spname):
      annotated_or_not["annotated"].append(spname)
      keywords = keywords_by_swissprotid[spname]
      for kw in keywords:
        magnitude = 1
        if use_magnitudes:
          qname = parts[0]
          try:
            magnitude = magnitude_by_name[qname]
          except KeyError:
            sys.stderr.write("Protein %s present in BLAST file but not in magnitude file (should NEVER happen), assuming magnitude=1.\n" % qname)
        tcount += magnitude
        tcount_by_kw[kw] += magnitude
    else:
      annotated_or_not["not_annotated"].append(spname)
sys.stderr.write("%s hits with %s annotated and %s not annotated proteins as hits.\n" % (ind+1, len(set(annotated_or_not["annotated"])), len(set(annotated_or_not["not_annotated"]))))
fin.close()

# look for enriched/underrepresented keywords
keywords = []
seenkeywords = set()
for kw in scount_by_kw.keys():
  srelfreq = float(scount_by_kw[kw]) / scount
  if tcount_by_kw.has_key(kw):
    seenkeywords.add(kw)
    trelfreq = float(tcount_by_kw[kw]) / tcount
    enrichment = trelfreq/srelfreq
    if enrichment > 2 or enrichment < 0.5:
      keywords.append((kw, enrichment, srelfreq, trelfreq))

keywords = sorted(keywords, key=itemgetter(1), reverse=True)

with open(outprefix + '.enriched_depleted.txt', 'w') as fout:
  for keyword in keywords:
    print >> fout, "%s\t%1.1f\t%1.1e\t%1.1e" % keyword

# what about absent keywords?
#print >> sys.stdout, "*** absent from dataset ***"
unseenkeywords = set(scount_by_kw.keys()) - seenkeywords
tmpdict = { kw: scount_by_kw[kw] for kw in unseenkeywords }
with open(outprefix + '.absent.txt', 'w') as fout:
  for k, v in sorted(tmpdict.iteritems(), key=lambda (k,v): (v,k), reverse=True):
    srelfreq = float(v) / scount
    print >> fout, "%s\t%1.1e" % (k, srelfreq)


sys.stderr.write("%s enriched/depleted keywords out of %s seen keywords out of %s possible keywords.\n" % (len(keywords), len(seenkeywords), len(scount_by_kw)))


