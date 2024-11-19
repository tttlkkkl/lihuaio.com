---
title: "批量下载远端文件到 aws s3"
date: 2021-07-06T12:05:58+08:00
draft: false
tags:
- ops
- s3
---

aws s3 没有保存远端文件的功能，需要先下载到本地再通过 s3 api 上传。
## 远端图片数据文件
```json
[   
    {
    "target": "ALEPH", 
    "source": "https://static-file-1259603563.file.myqcloud.com/static/cmc/xFnIcDbI/static/img/coins/128x128/5821.png"
    },
    {
    "target": "BTC", 
    "source": "https://static-file-1259603563.file.myqcloud.com/static/cmc/xFnIcDbI/static/img/coins/128x128/1.png"
    }
]
```
## 上传脚本
- 其实麻烦的地方在于批量获得远端文件的地址，本例中通过 jq 指令从 json 文件中提取。
```bash
#!/bin/bash -e
# 解析json中的地址数据并从远端下载图片转存到s3

# 解析 json 数组
list=$(jq -c '.[]' data.json)
# 按行循环 json 数组
for i in $list;
do
    # 提取 target 和 source 参数
    # 参数 r 可以提取元数据，否则获取到的字符串会包含 ""
    t=$(jq -r '.target'  <<< $i)
    s=$(jq -r '.source'  <<< $i)
    # 获取远端文件名称，并且组装成新的文件名
    s3_file_name="icon/128x128/$t-${s##*/}"
    # 下载远端文件到指定目录，-x 自动创建目录，-N 忽略已下载文件， -O 保持到指定文件路径中 
    wget -x -N -O $s3_file_name $s
    # 如果下载不到文件中途退出
    if [ ! -f $s3_file_name ];then
        echo "---------------------->文件 $s 不存在"
        exit
        else
        # 保存已下载文件名
        echo $s3_file_name >> up.txt
    fi
    # 上传的 s3 并授予公开读的ACL
    # 注意，aws s3 上传并修改 ACL 需要在存储桶中打开相应的安全开关
    aws s3 cp $s3_file_name s3://bucket/icon/128x128/$s3_file_name --acl public-read
done
```
- 其中 `jq -c '.[]' data.json` 指令从 json 文件中提取 array 的元素，结果类似：
```
{"target":"ALEPH","source":"https://static-file-1259603563.file.myqcloud.com/static/cmc/xFnIcDbI/static/img/coins/128x128/5821.png"}
{"target":"BTC","source":"https://static-file-1259603563.file.myqcloud.com/static/cmc/xFnIcDbI/static/img/coins/128x128/1.png"}
```
- 按行循环以上初步提取结果，进行下载和上传操作。这里如果使用 `while read line` 语法将无法使用两次 line 变量。