#!/usr/bin/perl

use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;

#needs to open the mga gff2 file and read everything line by line
#	if it finds # ass as the start of the file
#		chomp line, remove "# " save name as contigname
#	continue through loop until gene_ is found
#		save start and stop coordinates for gene save as genename
#			open contig input fasta file using SeqIO
#				if seq->id eq contigname
#				output result where seqout->id = "contigname_genename" and seq_obj->substr(start,end)
#			}
#			close input fasta file
#	}
#	find next instance of gene_ and repeat
#	when line contains "# ass"
#		resave contig name then continue through gene loop
#
#
my $mgaresultfile=$ARGV[0];
my $contigfile=$ARGV[1];
my $outputfile=$ARGV[2];
my $protoutputfile=$outputfile."a";

my $contigsubstring="# contig_";
my $genesubstring="gene_";
my $currentcontigseq;
my $currentcontigname;
my $genename;
my $genestart;
my $geneend;
my $genestrand;
my $geneseq;
my $geneframe;
unless(open MGAFILE, $mgaresultfile){
	die "Unable to open MGA output file $mgaresultfile";
}
my $outfile = Bio::SeqIO->new(-file =>">$outputfile", -format=>"fasta");
my $proteinoutfile = Bio::SeqIO->new(-file =>">$protoutputfile", -format=>"fasta");
while(my $line = <MGAFILE>){
	chomp $line;
	#print "\$line is $line\n";
	if(index($line,$contigsubstring) != -1){
	#	print "contig is $line\n";
		my @namebreakdown=split(' ',$line);
		$currentcontigname=$namebreakdown[1];
	#	print "contigname is $namebreakdown[1]\n";
		my $inputfasta=Bio::SeqIO->new(-file=>"$contigfile", -format=>"fasta");
		while(my $sequence=$inputfasta->next_seq){
			if($sequence->id eq $namebreakdown[1]){		
#				print "this seq is ".$sequence->id." which should equal $namebreakdown[1]\n";
#				print "this contigs sequence is \n".$sequence->seq()."\n";
				#my $currentcontigseq=$sequence->seq();					
				$currentcontigseq=Bio::Seq->new(-id=>$sequence->id,-seq=>$sequence->seq());
				
				#print "sequence for $namebreakdown[1] is \n".$currentcontigseq->seq()."\n"; 
			}
		}		
	}
	elsif(index($line,$genesubstring) != -1){
	#	print "geneline is $line\nand the current contig is $currentcontigname\n";
		my @genebreakdown=split('\t',$line);			
		$genename=$genebreakdown[0];
		$genestart=$genebreakdown[1];
		$geneend=$genebreakdown[2];
		$genestrand=$genebreakdown[3];
        $geneframe=$genebreakdown[4];
		$geneseq=$currentcontigseq->subseq($genestart,$geneend);
	#	print"the genesequence for ".$currentcontigname."_".$genename." is \n$geneseq\n";
		my $revisedname=$currentcontigname."_".$genename;
		my $geneprintout=Bio::Seq->new(-id=>$revisedname,-seq=>$geneseq);
		my $protprintout=Bio::Seq->new(-id=>$revisedname,-seq=>$geneseq);
		#print "the revisedname is $revisedname and the current frame is $genestrand $geneframe\n";
		if($genestrand eq '-'){
		
			my $revgeneseq= $geneprintout->revcom;
			my $revprotseq= $protprintout->revcom->translate(-frame=>$geneframe);
			#print "the initial sequence is $geneseq\n";
			#print "the reverse sequence is ".$revgeneseq->seq()."\n";
			#my $translaterevseq=$revgeneseq->translate(-frame=>$geneframe);	
  #          print "the translated sequence is ".$revprotseq->seq()."\n";
			$outfile->write_seq($revgeneseq);
            $proteinoutfile->write_seq($revprotseq);
			
		}
		else {
			$outfile->write_seq($geneprintout);
            my $translateseq=$protprintout->translate(-frame=>$geneframe);
            $proteinoutfile->write_seq($translateseq);
            #print "the correctorientation squences is $geneseq\n";
			#print "the translated sequence is ".$translateseq->seq()."\n";
			
		}	
		
		
	}	

		




}



#$inputfasta= Bio::SeqIO->new(-file =>"$contigfile", -format=>"fasta");

						
