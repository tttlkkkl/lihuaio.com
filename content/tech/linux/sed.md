---
title: "Sed 笔记"
date: 2020-11-10T21:21:22+08:00
draft: false
tags:
- linux
- 笔记
---

流式处理，即按行处理。读入一行处理完输出之后再读入下一行进行处理。

## 命令格式:
```shell
sed [OPTION]... {script-only-if-no-other-script} [input-file]...
```

## 参数说明：
以下引用自[菜鸟教程](https://www.runoob.com/)
> - `-e<script>或--expression=<script>` 以选项中指定的script来处理输入的文本文件。
> - `-f<script文件>或--file=<script文件>` 以选项中指定的script文件来处理输入的文本文件。
> - `-h`或--help 显示帮助。
> - `-n`或--quiet或--silent 仅显示script处理后的结果。
> - `-V`或--version 显示版本信息。
> - `-i`将结果应用到源文件。

### 指令说明：
以下引用自[菜鸟教程](https://www.runoob.com/)
> - `a` ：新增， a 的后面可以接字串，而这些字串会在新的一行出现(目前的下一行)。
> - `c` ：取代， c 的后面可以接字串，这些字串可以取代 n1,n2 之间的行。
> - `d` ：删除，因为是删除啊，所以 d 后面通常不接任何内容。
> - `i` ：插入， i 的后面可以接字串，而这些字串会在新的一行出现(目前的上一行)。
> - `p` ：打印，亦即将某个选择的数据印出。通常 p 会与参数 sed -n 一起运行。
> - `s` ：取代，可以直接进行取代的工作哩！通常这个 s 的动作可以搭配正规表示法！例如 `1,20s/old/new/g` 。

### 行定位

- 定位一行: `x`;`/正则/`。
- 定位几行，范围定位：`x,y`;`/正则/,x`;`/正则/,/正则/`;`x,y!`取反。
- 间隔行定位: `first~step`,选择从first行开始，每隔step行。
- `sed -n 'p' file` : 打印文件内容并去除不相关行。
- `sed -n '5p' file` : 打印文件第五行。
- `sed -n '5,10p' file` : 打印文件第5到10行的内容。
- `sed -n '5,10p' file` : 打印文件第5到10行之外的内容。

### 修改内容

#### 基本修改
- `sed '30a helllo' file`: 在第30行后面新增一行，内容为 hello。
- `sed '30i helllo' file`: 在第30行前面新增一行，内容为 hello。
- `sed '30c helllo' file`: 替换第30行的内容为 hello。
- `sed '30d' file`: 删除第30行。
- `sed '$a line1 \n line2' file`:在文档结尾追加两行内容。
- `sed '/^$/d' file`:删除空行。主要在于正则找到空行。

#### 字符替换

- `sed 's/old/new/g' file`:把正则 old 替换为字符串 new 。不加 g 每行只被替换一次。
- `sed 's/^$/new/g' file`:把空行全部替换为 new 。

#### 高级操作

- `{cmd;cmd}`:`{}`应用多个命令，用`;`隔开。 `sed '{29d;s/1000/2000/g}'` 删除 29 行并将 1000 替换为 3000。
- `n` 读取下一行并用下一个命令处理。`sed -n '{n;p}' file` 打印偶数行。 `sed -n '{p;n}' file` 打印奇数行。
- `&` 代替固定字符串：`sed 's/xxx/&yyy/g' file`。将 xxx 替换为 xxxyyy。& 代表前面的 xxx 。
- `\u \l`: 首字母大小写转换。`sed 's/m:x/\u&xxx/' file` 将 m:x 替换为 m:xxxx 并且首字母 m 转换为大写。`\l` 首字母小写。
- `\U \L`: 多个字符大小写转换。`sed 's/.*\W.*/\U&/g' file` 把文件所有单词转换为大写。
- 正则`()`中的内容可以使用`\1 \2`等来引用。`\(\) \(\) \1 \2`: `sed 's/\(w1\)\(w2\)/\1x\2y/g'` 将 `w1 w2` 替换为 `w1x w2y`。
- `r` 复制指定的文件插入到匹配行后面。`sed '7r 1.txt' p.txt` 将 1.txt 中的内容插入到 p.txt 的第7行后面。
- `w` 复制匹配行到文件中。`sed '1w 1.txt' p.txt` 拷贝 p.txt 中的第一行写入到 1.txt 中。1.txt 中原有文件内容将会被清空。
- `q` 退出，不再处理后续内容。`sed '2q' p.txt` 执行到第二行后退出。