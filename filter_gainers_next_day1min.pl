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
	my $date_time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
	my $min1file = "$min1_path/$YEAR/31#$stock.txt";
	if ($stock =~ /^08/) {
		$min1file = "$min1_path/$YEAR/48#$stock.txt";
	}
	print STDERR "$date\t$stock\n";
	open (MIN1FILE, "$min1file") or die $!;
	#my $kick = 0;
	#my $cur_date = "null";
	my $open_time = 0;
	while (<MIN1FILE>) {
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
			($year, $month, $day) = split("/", $next_date);
			my $next_date_time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
			if ($next_date_time <= $date_time) {
				next;
			}
			my $time = $timestr;
			my ($hour, $minute) = $time =~ /^(\d{2})(\d{2})$/;
			$time = $hour * 60 + $minute;
			if ($open_time == 0) {
				$open_time = $time - 1;
			}
			if ($time > ($open_time + 30)) {
				$open_time = 0;
				last;
			}
			print "$stock\t$next_date\t$timestr\t$open\t$high\t$low\t$close\t$vol\t$amount\n";
			
			
			
			#if ($next_date eq $date) {
			#	$kick = 1;
			#}
			#if ($next_date ne $date && $kick == 1) {
			#	if ($cur_date eq "null") {
			#		$cur_date = $next_date;
			#	}
			#	if ($cur_date ne $next_date) {
			#		last;
			#	}
			#	print "$stock\t$next_date\t$timestr\t$open\t$high\t$low\t$close\t$vol\t$amount\n";
			#}
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