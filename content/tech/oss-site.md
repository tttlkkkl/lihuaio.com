---
title: "部署 hugo 网站到 oss "
date: 2020-05-07T21:08:18+08:00
draft: false
tags:
- hugo
- oss
---
### 关于oss
oss 是阿里云推出的一个文档存储服务类似亚马逊的 s3 。如果是熟悉 oss 的同志可直接忽略本文，你可能只是不知道 oss 还有静态网站托管功能，直接过去一顿操作即可。

### hugo 网站的部署方式
hugo官网有介绍N种静态网站部署方式，但是都是国外的，没有国内方案，访问起来会很慢。当然如果有自己的云服务器那些都是浮云，又是N种部署方式。我的个人服务器快要到期，而且部署上去之后发现还是又卡顿。试了一下阿里云oss之后打开速度还可以，索性将本站部署到oss上。先在此记录分享一下。

### 前置条件
万变不离其宗，就 oss 部署方案来说需要有以下前置条件：
- 一个阿里云账号，没有就去注册一个。连接：[aliyun.com](https://aliyun.com)。
- 一个已经备案的域名，国内云厂商的服务不备案是用不了域名的。当然可以不个性化的话也可以直接使用阿里云 oss 提供的域名。
- 9块钱人民币，用来购买一个 40GB 的 oss 通用存储包，一年有效期。这个价格可能会有变动，但是相比直接买一台服务器肯定要划算的。

### 小白教程
1. 首先阿里云账号头像那边点击 `访问控制` 进去创建一个开发账号并且赋予 oss 的管理权限。创建`AccessKey`供后续使用。
2. 在 oss 管理控制台创建一个bucket。
3. 下载上传工具，地址：[ossutil](https://help.aliyun.com/document_detail/120075.html)
4. 运行 `ossutil config` 按照提示设置好第一步中得到的 accessKeyID 和 accessKeySecret。
5. 生成站点并上传至 oss：
```
hugo --environment=production && ossutil cp -r public oss://<bucket>/ -u
```
6. 设置 oss 站点：打开 oss 控制台,在 bucket 的基础设置中找到`静态页面`。设置默认首页为`index.html`,默认404页面为`404.html`,开通子目录首页，文件404规则为index。如下图：
![oss静态网站设置示例](/images/oss-static-site.jpg)
7. 设置 bucket 读写权限为 `公共读`。
8. 申请一个免费证书，阿里云 SSL 证书服务，购买证书（没错免费的0元购买），单域名>>>DV SSL>>>免费版，按照页面说明完成证书申请即可。申请完成后下载`其他`证书类型。当然如果你能忍受3个月手动换一次证书的痛楚完全可以使用`acme.sh`签发的证书。
9. 设置域名，传输管理>>>绑定用户域名，将你自己的域名绑定上去，设置好证书托管，并且设置好域名 CNAME 解析之后就大功告成。
10. 为了更新方便，可以在站点项目根目录下创建`Makefile`文件，将常用命令写在其中，一条命令完成更新。
11. 贴上我的`Makefile`文件内容和本站源码地址：
```
run:
	rm -rf public && hugo --environment=production && docker build -t tttlkkkl/lihuaio.com . && docker run --rm -it -p 80:80 tttlkkkl/lihuaio.com
push:
	docker build -t tttlkkkl/lihuaio.com . && docker push tttlkkkl/lihuaio.com
d: 
	hugo server -D --environment=production
# 在本项目根目录执行 make oss 即可完成文章更新。
oss:
	hugo --environment=production && ossutil cp -r public oss://lihuaio/ -u
```
[本站 github 地址](https://github.com/tttlkkkl/lihuaio.com)