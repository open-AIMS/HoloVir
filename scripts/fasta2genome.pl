#!/usr/bin/perl

use strict;
use Bio::SeqIO;

my $infile=$ARGV[0];

my $infileFasta=Bio::SeqIO->new(-file => $infile, -format => 'fasta') or die "ERROR: coultdnt open $infile\n";
while(my $seq =$infileFasta->next_seq()){
	my $currentid=$seq->id();
        my @fragments=split(" ", $currentid);
	my $contig=$fragments[0];
	my $contiglength=$seq->length();
	print "$contig\t$contiglength\n";
}
