#!/usr/bin/perl
use strict;
use POSIX;

my $win_rate = 0.05;
my $lose_rate = 0.05;
#my $sell_price = 0.05;
my $buy_trans_cost = 0.001;
my $sell_trans_cost = 0.001;
my %stra = {
	"strategy1"	=> \&strategy1,
	"strategy2"	=> \&strategy2,
};
my $start_date = shift;	#start_date��һ������
my $end_date = shift;	#end_date���һ������
my $strategy = shift;	#������
my $GAINERS = shift;	#�Ƿ����б��ļ�
my $GAINERS_NEXT = shift;	#�Ƿ����Ʊ�ڶ��쿪�̰�Сʱ��1��������
my @args = @ARGV;
print "�ز�����: $start_date ~ $end_date\n";
print "�����Ƿ�������\n";
open (FILE, "$GAINERS") or die $!;
my @GAINERS = <FILE>;
close FILE;
shift @GAINERS;

print "ִ��ѡ�ɲ���\n";
#print "$strategy, ", &{$stra{$strategy}}, "----\n";
#my $stocks = $stra{$strategy}->(@args);
my $stocks = &strategy1(@args);
#print "2015/01/08, ����", $stocks->{"2015/01/08"}->{"code"}, "\n";
print "����������\n";
&compute_income($stocks);
sub compute_income {
	my $stocks = shift;
	my ($year, $month, $day) = split("/", $start_date);
    my $start_time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
	($year, $month, $day) = split("/", $end_date);
    my $end_time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
	print "���صڶ���1��������\n";
	open (FILE1, "$GAINERS_NEXT") or die $!;
	my @gainers_next = <FILE1>;
	close FILE1;
	my %next_stocks;
	foreach my $line (@gainers_next) {
		chomp;
		my @cols = split /\t/, $line;
		my $code = $cols[0];
		my $date = $cols[1];
		my $time = $cols[2];
		my $minopen = $cols[3];
		my $high = $cols[4];
		my $low = $cols[5];
		my $minclose = $cols[6];
		if (exists $next_stocks{$code}) {
			if (exists $next_stocks{$code}->{$date}) {
				$next_stocks{$code}->{$date}->{$time} = {
					"high"	=> $high,
					"low"	=> $low,
					"open"	=> $minopen,
					"close"	=> $minclose,
				}
			}
			else {
				$next_stocks{$code}->{$date} = {
					$time	=> {
						"high" => $high,
						"low"  => $low,
						"open"	=> $minopen,
						"close"	=> $minclose,
					}
				}
			}
		}
		else {
			$next_stocks{$code} = {
				$date => {
					$time => {
						"high" => $high,
						"low"  => $low,
						"open"	=> $minopen,
						"close"	=> $minclose,
					}
				}
			}
		}
	}
	#print "2015/01/09, ����00918, ", $next_stocks{"00918"}->{"2015/01/09"}->{"0948"}->{"high"}, "\n";
	my $total_trade_days = 0;
	print "���������ʣ�\n";
	my $trade_days = 0;
	my $no_trade_days = 0;
	my $rate = 1;
	my $buy_date;
	my $sell_date = "null";
	foreach my $date (sort keys %$stocks) {
		($year, $month, $day) = split("/", $date);
		my $time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
		if ($time < $start_time || $time > $end_time) {
			next;
		}
		$total_trade_days++;
		if ($sell_date ne "null") {
			($year, $month, $day) = split("/", $sell_date);
			my $tmp_time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
			if ($time < $tmp_time) {
				next;
			}
			if ($sell_date ne $date) {
				print "sell_date($sell_date) not equal date($date), someting wrong\n";
				exit;
			}
		}
		my $op_code = $stocks->{$date}->{"code"};
		my $close = $stocks->{$date}->{"close"};
		$buy_date = $date;
		#print "buy_date: $buy_date\n";
		$sell_date = "null";
		if ($op_code eq "null") {
			print "$buy_date, �ղ�, rate=$rate\n";
			$no_trade_days++;
			next;
		}
		my $tmp_quote = $next_stocks{$op_code};
		foreach my $tmp_date (sort keys %$tmp_quote) {
			my ($year, $month, $day) = split("/", $tmp_date);
			my $tmp_time = mktime(0, 0, 0, $day, $month - 1, $year - 1900);
			if ($tmp_time > $time) {
				$sell_date = $tmp_date;
				#print "sell_date: $sell_date\n";
				last;
			}
		}
		if ($sell_date eq "null") {
			print "$buy_date, �����̼�����$op_code, no sell\n";
			last;
		}
		my $tmp_hash = $next_stocks{$op_code}->{$sell_date};
		my $open_time = 0;
		foreach my $tmp_time (sort keys %$tmp_hash) {
			my $low = $tmp_hash->{$tmp_time}->{"low"};
			my $high = $tmp_hash->{$tmp_time}->{"high"};
			my $minopen = $tmp_hash->{$tmp_time}->{"open"};
			my $minclose = $tmp_hash->{$tmp_time}->{"close"};
			my $tt = $tmp_time;
			my ($hour, $minute) = $tt =~ /^(\d{2})(\d{2})$/;
			$tt = $hour * 60 + $minute;
			#print "tt: $tt\n";
			if ($open_time == 0) {
				$open_time = $tt - 1;
			}
			#print "$sell_date, $op_code, $open_time, $tmp_time\n";
			if ($tt >= ($open_time + 15)) {
				if ($low <= $close * (1 - $lose_rate)) {
					$rate *= $low / $close;
					#$rate *= (1 - $lose_rate);
					$rate *= (1 - ($buy_trans_cost + $sell_trans_cost));
					print "$buy_date, �����̼�����$op_code, $sell_date, ��������", $lose_rate * 100, "%, ��", (1-$low/$close) * 100, "%ֹ��, rate=$rate\n";
					$trade_days++;
					last;
				}
			}
			if ($high >= $close * (1 + $win_rate)) {
				$rate *= (1 + $win_rate);
				$rate *= (1 - ($buy_trans_cost + $sell_trans_cost));
				print "$buy_date, �����̼�����$op_code, $sell_date, �Ƿ�����", $win_rate * 100, "%, ��", $win_rate * 100, "%ֹӯ, rate=$rate\n";
				$trade_days++;
				last;
			}
			if ($tt == ($open_time + 30)) {
				my $t = $minclose / $close;
				$rate *= $t;
				$rate *= (1 - ($buy_trans_cost + $sell_trans_cost));
				print "$buy_date, �����̼�����$op_code, $sell_date, ���̰�Сʱ��δ�ﵽֹӯ��/ֹ����, ��10:00���̼�����, ������", ($t - 1) * 100, "%, rate=$rate\n";
				$trade_days++;
				last;
			}
		}
		
	}
	print "�����ܽ�������: $total_trade_days\n";
	print "������������: $trade_days\n";
	print "���ڿղ�����: $no_trade_days\n";
	print "��������ͣ������: ", $total_trade_days - $trade_days - $no_trade_days, "\n";
}

#ѡ�ɲ���һ���Ƿ����һ
sub strategy1 {
	print "ѡ�ɲ��ԣ��Ƿ����Ƿ���һ\n";
	my %stocks;
	foreach my $line (@GAINERS) {
		chomp $line;
		my @cols = split /\t/, $line;
		my $date = $cols[0];
		my $code = $cols[1];
		my $open = $cols[2];
		my $high = $cols[3];
		my $low = $cols[4];
		my $close = $cols[5];
		my $vol = $cols[6];
		my $amount = $cols[7];
		my $increase = $cols[8];
		if ($code ne "null") {
			if (exists $stocks{$date}) {
				if ($stocks{$date}->{"code"} ne "null") {
					next;
				}
			}
		}
		$stocks{$date} = {
			"code" => "null",
		};
		if ($amount < 10000000) {
			next;
		}
		$stocks{$date} = {
			"code"		=> $code,
			"open"		=> $open,
			"high"		=> $high,
			"low"		=> $low,
			"close"		=> $close,
			"vol"		=> $vol,
			"amount"	=> $amount,
		};
	}
	return(\%stocks);
}

#ѡ�ɲ��Զ����Ƿ���ɽ����һ
sub strategy2 {
	print "ѡ�ɲ��ԣ��Ƿ���ɽ����һ\n";
	my %stocks;
	foreach my $line (@GAINERS) {
		chomp $line;
		my @cols = split /\t/, $line;
		my $date = $cols[0];
		my $code = $cols[1];
		my $open = $cols[2];
		my $high = $cols[3];
		my $low = $cols[4];
		my $close = $cols[5];
		my $vol = $cols[6];
		my $amount = $cols[7];
		my $increase = $cols[8];
		if ($code eq "null") {
			$stocks{$date} = {
				"code" => "null",
			};
			next;
		}
		if (exists $stocks{$date}) {
			my $amount1 = $stocks{$date}->{"amount"};
			my $amount2 = $amount;
			$amount1 += 0;
			$amount2 += 0;
			if ($amount2 > $amount1) {
				$stocks{$date}->{"code"} = $code;
				$stocks{$date}->{"open"} = $open;
				$stocks{$date}->{"high"} = $high;
				$stocks{$date}->{"low"} = $low;
				$stocks{$date}->{"close"} = $close;
				$stocks{$date}->{"vol"} = $vol;
				$stocks{$date}->{"amount"} = $amount;
				$stocks{$date}->{"increase"} = $increase;
			}
			next;
		}
		$stocks{$date} = {
			"code"		=> $code,
			"open"		=> $open,
			"high"		=> $high,
			"low"		=> $low,
			"close"		=> $close,
			"vol"		=> $vol,
			"amount"	=> $amount,
		};
	}
	return(\%stocks);
}

#ѡ�ɲ��������Ƿ����У��������10���ӣ�ÿ���Ӷ��гɽ����ҵ��ճɽ����1500��
sub strategy3 {
}