#! /usr/bin/perl
use warnings;
use strict;

if ($#ARGV != 1) {
	print "usage: perl this.pl Words_file Dictionary_file\n";
	print "author: hsy\n";
	print "date: 2019.9.19";
	exit;
}

#这个函数的目的是将中文字符转换为英文字符
sub Ch2En{
	my $str = $_[0];
	my $str_nospace = $str =~ s/\s+//gr;
	my $str_nospace_noch1 = $str_nospace =~ s/，/,/gr;
	my $str_nospace_noch2 = $str_nospace_noch1 =~ s/；/;/gr;
	my $str_nospace_noch3 = $str_nospace_noch2 =~ s/（/\(/gr;
	my $str_nospace_noch4 = $str_nospace_noch3 =~ s/）/\)/gr;
	my $str_En = $str_nospace_noch4;
	return $str_En;
}

my $Words_file = $ARGV[0];
my $Words_yisi = $ARGV[1];
my @Words = ();
my %Words = ();

#读取文件中所有的单词并去冗余
open my $fh1, "<", "$Words_file";
while (<$fh1>) {
	chomp;
	s/[\s]+/ /g;
	s/^ //;
	s/ $//;
	$_=lc($_);
	if (exists $Words{$_}) {
	} else {
		$Words{$_} = 1;
		push @Words,$_;
	}
}
close $fh1;

#后面会更新此文件，所以删掉最好
`rm -f $Words_file`;

#依次查询每一个单词，并输出意思
open my $fh_out, ">>", "$Words_yisi";
foreach my $one_word (sort @Words) {
	
	#单词字母小于3个没有查询的必要
	if (length($one_word) <= 3) {
		next;
	}
			
	system("ydict $one_word > tmp");
	my $i = 0; #$i用来记录第几行
	my $j = 0; #$j是为了记录单词意思的终止行数
	
	#为了得到$j
	open my $fh_tmp, "<", "tmp";
	while (<$fh_tmp>) {
		chomp $_;
		$i=$i+1; #tmp文件的行数
		if ($_ =~ /^(\s)*1\./) {
			$j=$i; #例句的起始行数
			last;
		}
	}
	close $fh_tmp;
			
	$j=$j-3; #单词意思的终止行数；已知如果单词可以被查询到，其意思的起始行数是4
	$i = 0; #重置$i
	
	my $query_right = 1; #为了判断单词是否能被查到
	my $line_4 = ""; #为了保存第四行

	open my $fh_tmp3, "<", "tmp";
	while (<$fh_tmp3>) {
		chomp $_;
		$i=$i+1;
		if ($i == 2) {
			if ($_ =~ /not found/) {
				$query_right = 0;
			}
		}
		if ($i == 4) {
			s/[\s]+/ /g;
			s/^ //;
			s/ $//;
			$line_4 = $_;
		}
	}
	close $fh_tmp3;
	
	$i = 0; #重置$i
		
	if ($j == -3) {
		#满足$j == -3的情况有多种：
		#1. 这个单词可以被查询到，但没有例句
		#2. 这个单词查询不到，又可以分为几种情况：
			#a. 原词找不到，对应的形容词找得到，biotinylate > biotinylated
			#b. 复数找不到，单数找得到，fibrosarcomas > fibrosarcoma
			#c. 完全查不到

		if ($query_right == 1) {
			$line_4 = Ch2En($line_4);
			print $fh_out "$one_word\t$line_4\n";
		} 
		if ($query_right == 0) {
			my $line_4_len = length($line_4);
			my $small_str_len = $line_4_len - 2;
			if (substr($one_word,0,$small_str_len) eq substr($line_4,0,$small_str_len)) {
				#此时我们想查询的单词可以换一个形式被查询到，意思也应该是接近的，将这个近似单词导出，以便于下一轮查询
				my $Words_file_2 = $Words_file.".2";
				system("echo $line_4 >> $Words_file_2");
			} else {
				#实在查询不到的单词就保留在原文件中，再来人工查询
				system("echo $one_word >> $Words_file");
			}
		}
		`rm -f tmp`;
	} else {
		#else表示这个单词可以被查询到，并且有例句
		
		my @word_yisi = (); #存储一个单词的所有意思
		open my $fh_tmp2, "<", "tmp";
		while (<$fh_tmp2>) {
			chomp $_;
			$i=$i+1;
			if ($i>=4 && $i<=$j) {
				s/[\s]+/ /g;
				s/^ //;
				s/ $//;
				push @word_yisi,$_;
			}
		}
		close $fh_tmp2;
		
		my $word_yisi = ""; #存储一个单词的所有意思
		foreach my $str (@word_yisi) {
			$word_yisi .= $str."|";
		}
		
		$word_yisi = Ch2En($word_yisi);
		print $fh_out "$one_word\t$word_yisi\n";
		`rm -f tmp`;
	}
}
close $fh_out;