#!/usr/bin/perl
use strict;
use POSIX;

my %hash;
my $last_time = 0;
my $last_date;
my %stock_hash;
@ARGV = glob "@ARGV";
foreach my $file (@ARGV) {
	#print "$file\n";
    open (FILE, "$file") or die $!;
    my $i = 0;
    my $stock_code;
    my $stock_name;
	my $pre_close = 1000000;
    while (<FILE>) {
        chomp;
        my @line = split;
        if ($i == 0) {
            $stock_code = $line[0];
            $stock_name = $line[1];
            if ($stock_code =~ /^029/) {
                last;
            }
            $stock_hash{$stock_code} = {};
        }
        my $date;
        if ($line[0] =~ /^\d{4}\/\d{2}\/\d{2}$/) {
            $date = $line[0];
            my ($year, $month, $day) = split("/", $date);
            my $time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
            if ($time > $last_time) {
                $last_time = $time;
            }
            if (exists $hash{$date}) {
                $hash{$date}->{$stock_code} = {
                    "name"  =>$stock_name, 
                    "open"  =>$line[1] + 0,
                    "high"  =>$line[2] + 0,
                    "low"   =>$line[3] + 0,
                    "close" =>$line[4] + 0,
                    "vol"   =>$line[5] + 0,
                    "amount"=>$line[6] + 0,
					"preclose"=>$pre_close,
                };
            }
            else {
                $hash{$date} = {
                    $stock_code=>{
                        "name"  =>$stock_name, 
                        "open"  =>$line[1] + 0,
                        "high"  =>$line[2] + 0,
                        "low"   =>$line[3] + 0,
                        "close" =>$line[4] + 0,
                        "vol"   =>$line[5] + 0,
                        "amount"=>$line[6] + 0,
						"preclose"=>$pre_close,
                    }
                };
            }
            $stock_hash{$stock_code}->{$date} = {
                "open"  =>$line[1] + 0,
                "high"  =>$line[2] + 0,
                "low"   =>$line[3] + 0,
                "close" =>$line[4] + 0,
                "vol"   =>$line[5] + 0,
                "amount"=>$line[6] + 0,
				"preclose"=>$pre_close,
            };
			$pre_close = $line[4] + 0;
        }
        $i++;
    }
    close FILE;
}
my ($sec,$min,$hour,$mday,$mon,$year_off,$wday,$yday,$isdat) = localtime($last_time); 
$last_date = sprintf("%04d/%02d/%02d", $year_off + 1900, $mon + 1, $mday);

sub GetNextStockTradingDay {
    my $now = shift;
    my $stock = shift;
    while (1) {
        my ($year, $month, $day) = split("/", $now);
        my $time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
        $time += 24 * 60 * 60;
        my($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime $time;
        $year += 1900;
        $mon += 1;
        my $date = sprintf("%04d/%02d/%02d", $year, $mon, $day);
        if (exists $stock_hash{$stock}->{$now}) {
            return($date, $time);
        }
        if ($time > $last_time) {
            return($date, $time);
        }
        $now = $date;
    }
}
print "date\tcode\topen\thigh\tlow\tclose\tvol\tamount\tincrease\tpreclose\n";
#my %chosen_stock;
foreach my $date (sort keys %hash) {
    if ($date eq $last_date) {
        next;
    }
    my $today = $hash{$date};
    my %today_chosen_stock;
    my $cnt = 0;
    foreach my $stock (keys %$today) {
		#阳线实体大于10%
        if ($today->{$stock}->{"open"} * 1.10 > $today->{$stock}->{"close"}) {
            next;
        }
		#日涨幅15%以上
		if ($today->{$stock}->{"preclose"} * 1.15 > $today->{$stock}->{"close"}) {
			next;
		}
		#日最低价不能小于1毛
		#if ($today->{$stock}->{"low"} < 0.1) {
		#	next;
		#}
		#成交额大于1000万港币
        if ($today->{$stock}->{"amount"} < 10000000) {
            next;
        }
		#不要股权
        if ($today->{$stock}->{"name"} =~ /股权$/) {
            next;
        }
        my ($next_date, $next_time) = &GetNextStockTradingDay($date, $stock);
        if ($next_time > $last_time) {
            next;
        }
        if ($stock_hash{$stock}->{$next_date}->{"open"} >= $today->{$stock}->{"close"} * 2) {
            next;
        }
        $today_chosen_stock{$stock} = $today->{$stock};
        $cnt++;
    }
    if ($cnt == 0) {
        #$chosen_stock{$date} = {"code"=>0, "beat"=>0};
        print "$date\tnull\tnull\tnull\tnull\tnull\tnull\tnull\tnull\n";
        next;
    }
    my @st = sort {($today_chosen_stock{$b}->{"close"} - $today_chosen_stock{$b}->{"open"}) / $today_chosen_stock{$b}->{"open"} <=> ($today_chosen_stock{$a}->{"close"} - $today_chosen_stock{$a}->{"open"}) / $today_chosen_stock{$a}->{"open"}} keys %today_chosen_stock;
    foreach my $stock (@st) {
        my $increase = ($today->{$stock}->{"close"} / $today->{$stock}->{"open"}) - 1;
        #print $today->{$stock}->{"open"}, ",", $today->{$stock}->{"close"}, ",", $increase, "\n";
        print "$date\t$stock\t", $today->{$stock}->{"open"}, "\t", $today->{$stock}->{"high"}, "\t", $today->{$stock}->{"low"}, "\t", $today->{$stock}->{"close"}, "\t", $today->{$stock}->{"vol"}, "\t", $today->{$stock}->{"amount"}, "\t", $increase, "\t", $today->{$stock}->{"preclose"}, "\n";
    }
    #$chosen_stock{$date} = {"code"=>$st[0], "beat"=>0};
}