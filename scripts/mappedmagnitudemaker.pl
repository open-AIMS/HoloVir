#!/usr/local/bin/perl
use Bio::SeqIO;
my $inputfasta=$ARGV[0];
my $sequencedepth=$ARGV[2];
my $sequencelength=$ARGV[1];
my $sequencegenes=$ARGV[3];
my @prefix=split('.fa',$inputfasta);
my $outputfasta=">".$prefix[0].".magnitudes.fasta";
my %clusters;
my $clustername;
my $counter;
my $repseq;
my @seqlineparts;
my $seqname;
my $seqlength;
my %lengths;
my $previouscontig;
my @coveragelineparts;
my $coveragecontig, $coveragecontigbase, $coveragevalue;
my %coverages;

open (MAGFILE,$sequencelength);
while (<MAGFILE>){
	chomp;
        @seqlineparts=split('\t',$_);
	$seqname =$seqlineparts[0];
	$seqlength=$seqlineparts[1];
	$lengths{$seqname}=$seqlength;
}

print"finished reading contiglength file $sequencelength\n";
close(MAGFILE);
my $contigcounter=keys(%lengths);
#print "there are a total of $contigcounter contigs in the input sequence length file $sequencelength\n"; 
foreach $lengthkey (keys %lengths){
	$value = $clusters{$lengthkey};
	print "$lengthkey is $value bp long\n";
}
open (COVERAGEFILE,$sequencedepth);
my $previouscontig="none";
my $coveragecounter;
while (<COVERAGEFILE>){
	chomp;
	@coveragelineparts=split('\t',$_);
	$coveragecontig=$coveragelineparts[0];
	$coveragecontigbase=$coveragelineparts[1];
	$coveragevalue=$coveragelineparts[2];
 	if ($coveragecontig eq $previouscontig){
		$coveragecounter=$coveragecounter+$coveragevalue;
	}
	else {
		$coveragecounter=0;
		$previouscontig=$coveragecontig;
	}
	$coverages{$coveragecontig}=$coveragecounter;
#	print "hash $coveragecontig has the value $coverages{$coveragecontig}\n";
}
#foreach $key (keys %coverages){
#		$value = $coverages{$key};
#		print "$key has $value bases covered\n"
#	}
print "finished reading read coverage file $sequencedepth\n";
close(COVERAGEFILE);
my $value;
my $contiglength;
my $avecoverage;
my $rounded;
my %magnitudes;
my $coveragecounter= keys(%coverages);
#print "there is $coveragecounter contigs in the coveragedepthfile $coveragedepth\n";
foreach $key (keys(%coverages)){
	$value = $coverages{$key};
	$contiglengths=$lengths{$key};
	$avecoverage=$value/$contiglengths;
	$rounded=sprintf("%.0f",$avecoverage);
print "$key has $value bases covered and the contig is $contiglengths bases long and the average coverage is $avecoverage which is rounded to $rounded\n";
	$magnitudes{$key}=$rounded;	
}


open(FASTAOUT, ">$inputfasta.magnitude.fasta");

my $infileFasta = Bio::SeqIO->new(-file =>$inputfasta, -format => 'fasta') or die "ERROR: Couldnt open $inputfasta: $!\n";
#my $outputFasta = Bio::SeqIO->new(-file =>$outputfasta, -format => 'fasta') or die "ERROR: Couldnt open $prefix[0].magnitudes.fasta: $!\n";
while(my $seq = $infileFasta->next_seq()){
	$currentseqname = $seq->id();
	$currentseqseq = $seq->seq();
	print FASTAOUT ">$currentseqname magnitude=$magnitudes{$currentseqname}\n$currentseqseq\n";
}	
print "have read in input contig file and amended sequence names for $inputfasta\n";
close FASTAOUT;
my $geneseqname;
my $geneseqseq;
my $genescontig;
my @genecontigparts;
open(FASTAOUT, ">$sequencegenes.magnitude.fasta");
my $infilegenesfasta= Bio::SeqIO->new(-file =>$sequencegenes, -format => 'fasta') or die "ERROR: Couldnt open $sequencegenes: $!\n";
while(my $seq =$infilegenesfasta->next_seq()){
	$geneseqname=$seq->id();
	$geneseqseq=$seq->seq();
	@genecontigparts=split('_gene',$geneseqname);
	$genescontig=$genecontigparts[0];
	print FASTAOUT ">$geneseqname magnitude=$magnitudes{$genescontig}\n$geneseqseq\n";
}
print "and have read in input gene file and amended sequence names for $sequencegenes\n";
close (FASTAOUT);
