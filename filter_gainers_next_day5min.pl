#!/usr/bin/perl
use strict;
use POSIX;

#my %gainers;
my $start_date = shift;
my $end_date = shift;
my $gainers_file = shift;
my $min5_path = shift;
my ($year, $month, $day) = split("/", $start_date);
my $start_time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
($year, $month, $day) = split("/", $end_date);
my $end_time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
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
    my $time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
	if ($time < $start_time || $time > $end_time) {
		next;
	}
	my $min5file = "$min5_path/31#$stock.txt";
	if ($stock =~ /^08/) {
		$min5file = "$min5_path/48#$stock.txt";
	}
	print STDERR "$date\t$stock\n";
	open (MIN5FILE, "$min5file") or die $!;
	my $kick = 0;
	my $cur_date = "null";
	while (<MIN5FILE>) {
		chomp;
		my @line = split;
		my $next_date;
		if ($line[0] =~ /^\d{4}\/\d{2}\/\d{2}$/) {
			$next_date = $line[0];
			my $timestr  = $line[1];
			my $open = $line[2];
			my $high = $line[3];
			my $low = $line[4];
			my $close = $line[5];
			my $vol = $line[6];
			my $amount = $line[7];
			my $time = $timestr;
			$time = $time + 0;
			if ($time > 1000) {
				next;
			}
			if ($next_date eq $date) {
				$kick = 1;
			}
			if ($next_date ne $date && $kick == 1) {
				if ($cur_date eq "null") {
					$cur_date = $next_date;
				}
				if ($cur_date ne $next_date) {
					last;
				}
				print "$stock\t$next_date\t$timestr\t$open\t$high\t$low\t$close\t$vol\t$amount\n";
			}
		}
	}
	close MIN5FILE;
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