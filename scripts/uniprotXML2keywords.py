#!/usr/bin/env python

import sys
import gzip
import os.path
from Bio import SeqIO

xmlfilename=sys.argv[1]
outfilename=sys.argv[2]

unspecific_terms=['Complete proteome','Reference proteome','Signal','Alternative splicing','Alternative initiation','Direct protein sequencing']

def getFromAnnotation(annotationKey, entry):
  if entry.annotations.has_key(annotationKey):
    annotationValue=entry.annotations[annotationKey]
    if isinstance(annotationValue, str):
      return [annotationValue]
    else:
      return annotationValue
  return []

outfile=gzip.open(outfilename, "w")
c=0
sys.stderr.write("Starting import of %s..." % xmlfilename)
with gzip.open(xmlfilename) as infile:
  for entry in SeqIO.parse(infile, "uniprot-xml"):
    description = entry.description
    keywords = getFromAnnotation("keywords", entry)
    outfile.write("%s\t%s" % (entry.id, description))
    for keyword in keywords:
      if keyword not in unspecific_terms:
        outfile.write("\t%s" % (keyword))
    outfile.write("\n")

    c+=1
    if c % 10000 == 0:
      sys.stderr.write(".")
      sys.stderr.flush()

sys.stderr.write("done (%i entries).\n" % c)
outfile.close()
