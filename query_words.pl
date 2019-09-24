#! /usr/bin/perl
use warnings;
use strict;

if (@ARGV != 2) {
	&Usage();
	exit;
}

#声明变量
my $Words_file = $ARGV[0];
my $Words_yisi = $ARGV[1];
my @Words = ();

#读取文件中所有的单词并去冗余
@Words = &Extract($Words_file);

#调用下文的查询函数，该函数的返回值并不重要
&Query($Words_file, $Words_yisi, \@Words);

#如果有$Words_file.".2"文件，需要多运行一次
my $Words_file_2 = $Words_file.".2";
if (-e $Words_file_2) {
	@Words = ();
	@Words = &Extract($Words_file_2);
	&Query($Words_file_2, $Words_yisi, \@Words);
}


#################################
#								#
#		some functions			#
#								#
#################################


#读取文件中所有的单词并去冗余
#使用：@Words = &Extract($Words_file);
sub Extract {
	my $argu = $_[0];
	my @array = ();
	my %array = ();
	open my $fh1, "<", "$argu";
	while (<$fh1>) {
		chomp;
		$_ = &Nospace($_);
		$_=lc($_);
		if (exists $array{$_}) {
		} else {
			$array{$_} = 1;
			push @array,$_;
		}
	}
	close $fh1;
	
	#后面会更新此文件，所以删掉最好
	`rm -f $argu`;
	
	return @array;
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

#将字符串两端的空格去掉
sub Nospace{
	my $str = $_[0];
	my $str_onespace = $str =~ s/[\s]+/ /gr;
	my $str_onespace_noheadspace = $str_onespace =~ s/^ //r;
	my $str_onespace_notailspace = $str_onespace_noheadspace =~ s/ $//r;
	my $str_Nospace = $str_onespace_notailspace;
	return $str_Nospace;
}


#############################################################
#															#
#最主要的是下面的查询函数									#
#依次查询@Words中的每一个单词，并输出意思					#
#输入的有：@Words, $Words_file								#
#输出的有：$Words_yisi										#
#函数使用：&Query($Words_file, $Words_yisi, \@Words);		#
#															#
#############################################################


sub Query{
	my $para1 = $_[0]; #参数文件1
	my $para2 = $_[1]; #参数文件2
	my $para3 = $_[2]; #上文收集的待查询的单词
	my %Words_wordyisi = ();
	my %Words_querytimes = ();
	my %Words_testtimes = ();
	my %Words_testright = ();
	my %Words_testright_ratio = ();
	
	#如果单词意思文件（第二个文件）已经存在
	#读取信息后删除，因为整个文件需要更新
	if (-e $para2) {
		open my $fh4, "<", "$para2";
		while (<$fh4>) {
			chomp $_;
			my @oneline = (split("\t", $_));
			$Words_wordyisi{$oneline[0]} = $oneline[1];
			$Words_querytimes{$oneline[0]} = $oneline[2];
			$Words_testtimes{$oneline[0]} = $oneline[3];
			$Words_testright{$oneline[0]} = $oneline[4];
			$Words_testright_ratio{$oneline[0]} = $oneline[5];
		}
		close $fh4;
		
		`rm -f $para2`;
	}
		
	foreach my $one_word (sort @$para3) {
		my $i = 0; #$i用来记录第几行
		my $j = 0; #$j是为了记录单词意思的终止行数
		my $query_right = 1; #为了判断单词是否能被查到，默认能被查到
		my $line_4 = ""; #为了保存第四行的内容
		
		#单词字母小于等于3个没有查询的必要
		if (length($one_word) <= 3) {
			next;
		}
				
		system("ydict $one_word > tmp");
		
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
				$_ = &Nospace($_);
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
				$line_4 = &Ch2En($line_4);
				if (exists $Words_querytimes{$one_word}) {
					$Words_querytimes{$one_word} += 1;
				} else {
					$Words_wordyisi{$one_word} = $line_4;
					$Words_querytimes{$one_word} = 1;
					$Words_testtimes{$one_word} = 0;
					$Words_testright{$one_word} = 0;
					$Words_testright_ratio{$one_word} = 0;
				}
			} 
			if ($query_right == 0) {
				my $line_4_len = length($line_4);
				my $small_str_len = $line_4_len - 2;
				if (substr($one_word,0,$small_str_len) eq substr($line_4,0,$small_str_len)) {
					#此时我们想查询的单词可以换一个形式被查询到，意思也应该是接近的，将这个近似单词导出，以便于下一轮查询
					my $para1_2 = $para1.".2";
					system("echo $line_4 >> $para1_2");
				} else {
					#实在查询不到的单词就保留在原文件中，再来人工查询
					system("echo $one_word >> $para1");
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
					$_ = &Nospace($_);
					push @word_yisi,$_;
				}
			}
			close $fh_tmp2;
			
			my $word_yisi = ""; #存储一个单词的所有意思
			foreach my $str (@word_yisi) {
				$word_yisi .= $str."|";
			}
			
			$word_yisi = &Ch2En($word_yisi);
			if (exists $Words_querytimes{$one_word}) {
				$Words_querytimes{$one_word} += 1;
			} else {
				$Words_wordyisi{$one_word} = $word_yisi;
				$Words_querytimes{$one_word} = 1;
				$Words_testtimes{$one_word} = 0;
				$Words_testright{$one_word} = 0;
				$Words_testright_ratio{$one_word} = 0;
			}
			`rm -f tmp`;
		}
	}
	
	#遍历哈希，逐行输出6列
	open my $fh_out, ">>", "$para2";
	foreach my $aword (sort keys %Words_wordyisi) {
		my $outstr = "$aword\t";
		$outstr = "$outstr"."$Words_wordyisi{$aword}\t";
		$outstr = "$outstr"."$Words_querytimes{$aword}\t";
		$outstr = "$outstr"."$Words_testtimes{$aword}\t";
		$outstr = "$outstr"."$Words_testright{$aword}\t";
		$outstr = "$outstr"."$Words_testright_ratio{$aword}\n";
		print $fh_out "$outstr";		
	}
	close $fh_out;
}

sub Usage {
	print "\n##################################################################\n";
	print "\n";
	print "\tusage: perl this.pl Words_file Dictionary_file\n";
	print "\tauthor: hsy\n";
	print "\tdate: 2019.9.19\n";
	print "\n";
	print "##################################################################\n\n";
}