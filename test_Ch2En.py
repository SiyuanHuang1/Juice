import sys
import os
import random
import re

#创建5个基本字典
Words_wordyisi={}
Words_querytimes={}
Words_testtimes={}
Words_testright={}
Words_testright_ratio={}

#读取文件，如果有中文需要加上encoding='utf-8'
file_path=sys.argv[1]
with open(file_path,encoding='utf-8') as file:
    lines = file.readlines()

#给字典赋值
for line in lines:
    line_list=line.split("\t")
    Words_wordyisi[line_list[0]]=line_list[1]
    Words_querytimes[line_list[0]]=int(line_list[2])
    Words_testtimes[line_list[0]]=int(line_list[3])
    Words_testright[line_list[0]]=int(line_list[4])
    Words_testright_ratio[line_list[0]]=float(line_list[5])

num=int(sys.argv[2]) #测试单词数量
test_right=0 #测试正确的单词数量
key_list=list(Words_wordyisi.keys()) #创建单词列表
error_list=[] #用来存储测试出错的单词

for i in range(0,num):
    print("-----------------------------------------------------------------------------------")
    one_key=random.choice(key_list)
    
    #出题
    re_pattern=r"\([a-zA-Z]{4,}"
    wordyisi_masked=re.sub(re_pattern,"(...",Words_wordyisi[one_key])
    print("The meaning of the word is: \n\n"+wordyisi_masked+"\n")
    #答题
    answer = input("What is your answer?\nInput: ")
    if answer == one_key:
        print("Your answer is RIGHT!")
        test_right+=1
        Words_testright[one_key]+=1
    else:
        print("Your answer is WRONG!")
        error_list.append(one_key)
    
    #对最上面的几个字典进行适当修改
    Words_testtimes[one_key]+=1
    Words_testright_ratio[one_key]=Words_testright[one_key]/Words_testtimes[one_key]
    print("-----------------------------------------------------------------------------------")

#更新file_path文件，需要将原文件删除，再生成同名文件
os.system("rm -f file_path")
with open(file_path, "w", encoding='utf-8') as outfile:
    key_list.sort()
    for one_word in key_list:
        outline=one_word+"\t"+Words_wordyisi[one_word]+"\t"+str(Words_querytimes[one_word])+"\t"+str(Words_testtimes[one_word])
        outline=outline+"\t"+str(Words_testright[one_word])+"\t"+str(Words_testright_ratio[one_word])+"\n"
        outfile.write(outline)

test_right_ratio=test_right/num*100
print("\n\n")
print("This time you test %d words"%(num))
print("The right ratio is %.2f%%"%(test_right_ratio))
print("\n\n")
print("Here are some words that you made a mistake on: \n")

if error_list:
    for one_error in error_list:
        error_line=one_error+"\t"+Words_wordyisi[one_error]
        print(error_line+"\n")
