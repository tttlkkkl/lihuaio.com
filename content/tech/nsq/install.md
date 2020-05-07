---
title: "nsq 安装方式"
date: 2017-03-31T13:08:32+08:00
draft: false
tags:
    - nsq
---
### 简介
nsq可以理解为一个分布式的ＭＱ队列服务软件，关于其介绍网上一搜一大把，此处不再赘述，更详尽的可移步至[官网](http://nsq.io)．
nsq是go语言面世以来编写的最成功的应用之一，据说docker是最成功的go语言应用．


### 安装
#### 写在前面的废话:

官方的安装页面在[这里](http://nsq.io/deployment/installing.html),当然还有网络参差不齐的安装方法介绍，包括本篇。但是我希望一个从来没有接触过nsq没有接触过golang的“小白”也能轻松用起nsq。

本篇所有操作都是64位linux系统下进行(centos7,ubuntu)，有其他操作系统的请参考[官方安装页面](http://nsq.io/deployment/installing.html)。

#### 安装方式：

##### 源码安装:
需要先安装golang环境，还有gpm,然后执行以下命令:

    ``` shell
     gpm install
     go get github.com/nsqio/nsq/
     ./test.sh
    ```

其实如果你已经安装了go语言环境，那么你可以这样做：先进入GOROOT目录,然后再执行以下操作。

     ```shell
     mkdir -p ./github.com/nsqio
     cd ./github.com/nsqio
     git clone git@github.com:nsqio/nsq.git #下载go源码
     cd nsq/apps/nsqd
     go build  # 或者 go run nsqd.go 执行
     ```

完了之后就可以在当前目录找到一个名字为nsqd的可执行文件，windows下面为nsqd.exe，运行它就可以启动一个nsqd生产服务，其余的nsqadmin,nsqlookup同样方法安装。可执行文件生成后可以被拷贝到别的任意目录，仍然可以执行。

##### 二进制文件安装(推荐):
如果你已经按照上面的方式安装成功了，那么你应该可以理解这个其实就是直接下载官方已经编译好的各个操作系统对应的可执行文件，可以直接下载运行。我推荐新手采用这种方式,如果上面给出的官方安装页面中的二进制包无法下载，你可以到github [releases页面下载](https://github.com/nsqio/nsq/releases)

##### 加入环境变量:

假如你已经成功获得所有可执行文件，可以将它加入换进变量以快速启动，我是这样做的: 
    ```shell
        mkdir -p /usr/local/nsq/bin
        cp -rp ./* /usr/local/nsq/bin/ #如果你的源码文件都在当前目录
        vim /etc/profile #文件末尾加入这行：export PATH=$PATH:/usr/local/nsq/bin
        #保存然后继续
        source /etc/profile  #让环境变量生效
    ```
以上添加的是全局的环境变量，所有用户都可以使用nsq。

##### 快速开始:
    没错，就是照搬官方的快速开始，体验一下先，后续讲解进阶内容。
1.启动发现服务nsqlookupd：
    ```shell
        nsqlookupd
    ```
2.启动生产服务nsqd,并且注册到上面启动的发现服务中，走TCP：
    ```shell
        nsqd --lookupd-tcp-address=127.0.0.1:4160
    ```
3.启动web管理服务,并注册到发现服务，走https:
    ```shell
        nsqadmin --lookupd-http-address=127.0.0.1:4161
    ```
4.推送一条消息到nsqd的test话题中，会自动创建test话题：
    ```shell
        curl -d 'hello world 1' 'http://127.0.0.1:4151/pub?topic=test'
    ```
5.通过nsq_to_file工具消费上面推送进去的消息:
    ```shell
        nsq_to_file --topic=test --output-dir=/tmp --lookupd-http-address=127.0.0.1:4161
    ```
另外你可以访问 127.0.0.1:4171来查看nsq的情况
其实极端情况下可以只启动nsqd就可以单机使用，但是这就有点浪费为分布式而生的nsq了。


