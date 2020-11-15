---
title: "Awk 笔记"
date: 2020-11-15T21:21:28+08:00
draft: false
tags:
- linux
- 笔记
---

## 基本使用
- awk 也是按行进行行流式处理，awk 可以编程，相比 sed 更加灵活。
- sed 更侧重于正则处理，awk 侧重复杂逻辑的处理。
- 可以对每行进行切片处理。
- 默认使用空格对每一行进行切分。可以使用`-F`选项指定切分字符串。

### 命令格式
```shell
# 从脚本文件中读取处理指令
 awk [POSIX or GNU style options] -f progfile [--] file ...
# 从命令行中读取处理指令
 awk [POSIX or GNU style options] [--] 'program' file ...
```

## 内置参数
- `$0`：当前行。
- `$1、$2...` 当前行第一个个字段，第二个字段……。
- `NR`:当前行行号。
- `NF`:当前行字段数量。
- `FILENAME`:当前文件名。

## 逻辑判断式
- `~`,`!~`:匹配正则表达式。`$1~/正则/{cmd...}` 表示将正则表达式匹配的内容赋值给 $1 并在后面的命令中使用。`!~`表示取反。
- `==,!=,>,<` 等逻辑表达式。

## 扩展格式
`BEGIN{cmd...}pattern{cmd...}END{cmd...}`。BEGIN 后的命令内容以及 END 后面的内容分别表示在行处理开始前和行处理结束之后执行的命令，不会应用到行处理中。
## 案例
- 打印 passwd 文件的行号，每行字段数量，以及用户名：
```bash
awk -F ':' '{print "行号:"NR,"字段数量:"NF,"用户名:"$1}' passwd
```
逗号将被转换为空格。
- 打印 uid 大于10并小于30的用户id和用户名：
```bash
awk -F ':' '{if ($3>10 && $3<30) printf("用户UID：%2s \t 用户名：%2s\n",$3,$1)}' passwd
```
`%s`中 s 前面的数字表示间隔的空格数量。以上可以写为：
```bash
awk -F ':' '($3>10 && $3<30) {printf("用户UID：%2s \t 用户名：%2s\n",$3,$1)}' passwd
```
- 打印用户名为 sshd 的用户的 uid。
```bash
sed -n '/sshd/p' passwd |awk -F ':' '{print $3}'` 或 ` awk -F ':' '/sshd/{$3}'
```
主意依赖 sed 命令进行正则行定位，或者 awk 命令开头先进行正则行定位。
- 统计非空行的数量：
```bash
awk 'BEGIN {count=0}$1~/^$/{count++}END{print "count=" count}' passwd
```
- 输出 passwd 文件中 uid 大于 100 的用户名，并对其进行数量进行累加统计。主意数组以及循环的使用：
```bash
awk -F ':' 'BEGIN 
{count=0}{if ($3>100) name[count++]=$1}
END {for (i=0;i<count;i++) print i,name[i]} ' passwd
```