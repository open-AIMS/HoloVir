#!/usr/bin/python

import sys

seen = set()
for line in sys.stdin:
  if line.startswith('>'):
    seqid = line.split()[0]
    if seqid in seen:
      write = False
    else:
      write = True
      seen.add(seqid)
  if write:
    sys.stdout.write(line)

