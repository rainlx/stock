#!/usr/bin/perl
use strict;
use POSIX;

#my %gainers;
my $YEAR = shift;
my $gainers_file = shift;
my $min1_path = shift;
open (FILE, "$gainers_file") or die $!;
my @gainers = <FILE>;
close FILE;
#print @gainers;
my $i = 0;
foreach my $line (@gainers) {
	chomp $line;
	if ($i == 0) {
		$i++;
		next;
	}
	$i++;
	my @line = split /\t/, $line;
	my $date = $line[0];
	my $stock = $line[1];
	if ($stock eq "null") {
		next;
	}
	my ($year, $month, $day) = split("/", $date);
	if ($year ne $YEAR) {
		next;
	}
	my $min1file = "$min1_path/$YEAR/31#$stock.txt";
	if ($stock =~ /^08/) {
		$min1file = "$min1_path/$YEAR/48#$stock.txt";
	}
	print STDERR "$date\t$stock\n";
	open (MIN1FILE, "$min1file") or die $!;
	while (<MIN1FILE>) {
		chomp;
		my @line = split;
		my $curr_date;
		if ($line[0] =~ /^\d{4}\/\d{2}\/\d{2}$/) {
			$curr_date = $line[0];
			my $timestr  = $line[1];
			my $open = $line[2];
			my $high = $line[3];
			my $low = $line[4];
			my $close = $line[5];
			my $vol = $line[6];
			my $amount = $line[7];
			my $time = $timestr;
			my ($hour, $minute) = $time =~ /^(\d{2})(\d{2})$/;
			$time = $hour * 60 + $minute;
			if ($time <= 15 * 60 + 30) {
				next;
			}
			if ($curr_date eq $date) {
				print "$stock\t$curr_date\t$timestr\t$open\t$high\t$low\t$close\t$vol\t$amount\n";
			}
		}
	}
	close MIN1FILE;
	#$gainers{$date} = {
	#	$stock => {
	#		"open"	=> $line[2] + 0,
	#		"high"	=> $line[3] + 0,
	#		"low"	=> $line[4] + 0,
	#		"close"	=> $line[5] + 0,
	#		"vol"	=> $line[6] + 0,
	#		"amount"=> $line[7] + 0,
	#		"increase"=> $line[8] + 0,
	#	}
	#}
}
#while (<FILE>) {

#}
#close FILE;
#print "CLOSE FILE\n";