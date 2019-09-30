import random
import sys

Words_wordyisi={}

#读取文件，如果有中文需要加上encoding='utf-8'
file_path=sys.argv[1]
with open(file_path,encoding='utf-8') as file:
    lines = file.readlines()

#给字典赋值
for line in lines:
    line_list=line.split("\t")
    Words_wordyisi[line_list[0]]=line_list[1]

num=int(sys.argv[2]) #记忆单词数量
key_list=list(Words_wordyisi.keys()) #创建单词列表

for i in range(0,num):
    one_key=random.choice(key_list)
    print("----------------------------------------------------------------------")
    print("\n"+one_key+"\n")
    input()
    print(Words_wordyisi[one_key]+"\n")
    print("----------------------------------------------------------------------")
    if i <= num-2:
        command="something"
        while command != "":
            command=input("Enter nothing for the next\n")
    else:
        print("\nThis time is over.\n")
