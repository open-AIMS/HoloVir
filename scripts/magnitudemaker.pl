#!/usr/local/bin/perl
use Bio::SeqIO;
my $inputfasta=$ARGV[0];
my $inputclusters=$ARGV[1];
my @prefix=split('.fa',$inputfasta);
my $outputfasta=">".$prefix[0].".magnitudes.fasta";
my %clusters;
my $clustername;
my $counter;
my $repseq;
open (MAGFILE,$inputclusters);
while (<MAGFILE>){
	chomp;
	if ($_ =~ ">Cluster*"){
		$clustername=$_;
	#	$counter=0;
	}
	else {
#		print "the current magnitude for cluster $clustername is $_\n";
		@seqlinevalues=split('\s+',$_);
#		print"and the corresponding cluster number is  $seqlinevalues[0]\n";
		if($seqlinevalues[0] eq "0"){
#			print " the current magnitude sequence is $_ and i will be using $seqlinevalues[2] for my identification\n";
			$rawrepseq=$seqlinevalues[2];
			@format1=split('>',$rawrepseq);
#			print "the removed name of sequence is $format1[1]\n";
			@format2=split('\.',$format1[1]);
#			print "and the trailing dots should be gone from $format2[0]\n";
			$repseq=$format2[0];
#			print "\t its established sequencename is $repseq\n";
		}
		$counter=$seqlinevalues[0]+1;
		$clusters{$repseq}=$counter;
#		print "the current value for repseq is $repseq the counter value is $counter and the current seq count is $clusters{'$repseq'}\n";
	}
}
foreach $key (keys %clusters){
	$value = $clusters{$key};
#	print " $key costs $value\n";
}
close(MAGFILE);
open(FASTAOUT, ">$inputfasta.magnitude.fasta");

my $infileFasta = Bio::SeqIO->new(-file =>$inputfasta, -format => 'fasta') or die "ERROR: Couldnt open $inputfasta: $!\n";
#my $outputFasta = Bio::SeqIO->new(-file =>$outputfasta, -format => 'fasta') or die "ERROR: Couldnt open $prefix[0].magnitudes.fasta: $!\n";
while(my $seq = $infileFasta->next_seq()){
	$currentseq = $seq->id();
	$clustercount = keys %clusters;
#	print "the magnitude of seq $currentseq is $clusters{$currentseq} which is in clusters with $clustercount elements\n";
	$newseqid= $currentseq." magnitude=$clusters{$currentseq}";
#	print "the new identifyer for $currentseq is $newseqid\n";
#	$seq->id()=$newseqid;
#	$outputFasta->write_seq($seq);
	$seq2print=$seq->seq;
	$id2print=">".$newseqid;

	print FASTAOUT "$id2print\n$seq2print\n";
}	
close FASTAOUT;
