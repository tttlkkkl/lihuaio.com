---
title: "nginx 配置 HTTP 2.0 并使用letsencrypt签发证书"
date: 2018-01-31T22:15:50+08:00
draft: true
tags:
- http2
- letsencrypt
- https
- 免费https证书
---

#### 缘起
之前用letsencrypt将个人站升级到 HTTP 2.0，并设置了定时脚本但是证书并没有自动续期，手动续期证书还遇到DNS无法识别的问题。就此次续期详细的记录一下过程并分享给各位有https需求的同僚。

#### nginx配置HTTP 2.0

只有nginx版本大于1.9.5才能支持 HTTP 2.0,网上有很多教程记录了如何编译添加 ngx_http_v2_module 模块，以使nginx支持 HTTP 2.0 大多都已经很陈旧，就我个人经验只需要安装好依赖然后直接在编译参数中包含这几编译选项即可`--with-http_ssl_module` `--with-stream_ssl_module` `--with-stream_ssl_module` `--with-http_v2_module`

##### nginx编译依赖

```shell
yum -y install gcc gcc-c++  pcre-devel  openssl-devel gd-devel perl-ExtUtils-Embed GeoIP GeoIP-devel GeoIP-data libxslt* libxml2*
```
即使编译失败按照错误提示不断修正最终一定可以成功的~~

#### letsencrypt

目前 centos 和 ubuntu 的源中已经包含了 letsencrypt, 可以通过 `yum install certbot` 或 `apt install certbot` 来获取证书签发程序。但是安装后可能会运行失败（我就遇到了这种情况）。如果不想折腾的话克隆源码包到机器上然后执行也是一样的效果。
```shell
git clone https://github.com/letsencrypt/letsencrypt
```
现在这个库已经迁移到 [https://github.com/certbot/certbot](https://github.com/certbot/certbot),克隆这个库也是一样的：
```shell
git  clone https://github.com/certbot/certbot.git 
```
##### 证书签发

大致的命令格式:letsencrypt-auto [SUBCOMMAND] [options] [-d DOMAIN] [-d DOMAIN] [-w dir]...
options 可选的有 --apache、--nginx  、 --standalone、 --manual 、  --webroot 等。  这里列举我实际使用过能满足需求的几个。

###### --webroot:

这是通用选项，基本能满足大部分需求,以本站为例,如果我的网站根目录在/www/lihuasheng 可以执行以下命令来签发证书:
```shell
./letsencrypt-auto certonly --webroot --email yehong0000@163.com -d www.lihuasheng.cn -d lihuasheng.cn  -w /www/lihuasheng --agree-tos
```
首次签发证书时需要添加--agree-tos 参数,以创建一个账号。该命令将在 /www/lihuasheng 目录下面生成一个隐藏的文件夹 .well-known 并通过 域名 lihuasheng.cn/.well-known/  访问文件夹下面的文件以验证你对该域名的所有权。说到这里提一下，花生壳（oray.com）下面的申请的域名DNS不能被letsencrypt读取，导致验证失败，解决方法后文补充。

###### --nginx:
此选项针对nginx服务器生成证书文件，此选项可以帮助完成nginx的配置包括http强制跳转https，我使用手动配置。
命令示例:
```shell
./letsencrypt-auto --nginx --email xxx@163.com -d www.lihuasheng.cn -d lihuasheng.cn -w /www/lihuasheng
```

###### --standalone:
通过433端口验证域名所有权，而不是以上采用以上写文件的方式。使用此命令需要确保433端口没有被占用。
#### 自动续签：
证书90天有效，我们需要设置一个3个月自动续期的定时任务,假如我的库被克隆到 `/www/letsencrypt` 则可以添加定时任务如下:
```shell
0 0 1 */3 * /www/letsencrypt/letsencrypt-auto renew
```
#### 解决DNS不识别：
花生壳下解析的域名无法被letsencrypt读取导致证书签发失败。这种情况下可以选择将域名转移到其他域名服务商下面，不过这个操作起来很不方便，而且又不能保证转移后可以解决问题。目前最有效的做法是将域名转至[腾讯云DNS解析 qcloud](https://qcloud.com)。目前对于个人站而言，免费版可以满足需求。

登录[控制台](https://console.qcloud.com) 解析域名，域名成功解析后生成至少两个dns服务器地址，在花生壳控制台中ns管理中替换花生壳自身的解析服务器域名即可。

#### 本站http2配置:
```conf
server {
        listen              443 ssl http2;
        index index.html;
        server_name         lihuasheng.cn www.lihuasheng.cn;
        ssl_certificate /etc/letsencrypt/live/www.lihuasheng.cn/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/www.lihuasheng.cn/privkey.pem;
        root         /www/lihuasheng;
        ssl on;
        error_page 404 https://$host;
}
server{

        listen              80;
        server_name         lihuasheng.cn www.lihuasheng.cn;
        root         /www/lihuasheng;
        return 301 https://$host/$uri;
}
```
**注意：在证书签发时你可能需要注释最后一行强制跳转 https 的配置。**


---

#### 追加说明：
随着 letsencrypt 被越来越多的人熟知和接受，签发方式也多种多样，很多框架和网关就自带签发功能。
除去 k8s、treafik、等自身支持或有其他实现的情况，可以使用 https://acme.sh 轻松完成证书签发和更新。