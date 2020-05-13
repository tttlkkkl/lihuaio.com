---
title: "制作一个生产环境可用的PHP基础镜像"
date: 2020-05-09T22:14:04+08:00
draft: false
tags:
- docker
- 容器技术
- php
- ops
---

### 引言
初学`docker`一定会觉得`Dockerfile`很难，其实只是无从下手的缘故。最好的学习方法就是看完每个`Dokerfile`指令的作用，然后不要急着去搞清楚，直接挑选一个你比较熟悉的服务软件动手自己制作一个。最好是直接到[docker官方镜像仓库](https://hub.docker.com)找到相应的官方镜像，然后顺藤摸瓜找到其`Dockerfile`文件，这一定是最佳实践。读懂它并且仿照它去进行二次构建，加入你所需要的东西。

本文就分享如何在`php`官方基础镜像的基础上构建一个生产环境可用的`php`镜像。为什么说是生产环境可用呢，因为基础镜像缺少很多扩展，一般情况下不满足实际项目的运行。

### 了解PHP基础镜像

PHP 基础镜像分为三个分支：
- cli: 没有开启 CGI 也就是说不能运行`fpm`。只可以运行命令行。
- fpm: 开启了CGI，可以用来运行`web`服务也可以用来运行`cli`命令。
- zts: 开启了线程安全的版本。

一般运行于`linux`平台的选用`fpm`就可以了。

### 需求分析以及镜像选择

本文中选用`php:7.3.7-fpm-alpine3.9`这个镜像，`php`版本为`7.3.7`，这个个版本已经不是最新的了，也没有落后太多。基于`alpine 3.9`这个系统镜像构建。至于为什么是`alpine`，因为`alpine`体积小，只有5M左右大小，是专门为容器而生的`linux`发行版，当然还有其他小体积的发行版但是我比较熟悉`alpine`。如果你不知道怎么选择那么也用`alpine`吧，经验法则告诉我们大部分人的选择不会错的太离谱。

我们的目的是构建一个可以支持大部分`PHP`应用的运行环境基础镜像所以先看一下官方基础镜像里面有哪些扩展，然后再按照我们的需要决定添加哪些扩展：
```bash
docker run php:7.3.7-fpm-alpine3.9 php -m
# 输出：
[PHP Modules]
Core
ctype
curl
date
dom
fileinfo
filter
ftp
hash
iconv
json
libxml
mbstring
mysqlnd
openssl
pcre
PDO
pdo_sqlite
Phar
posix
readline
Reflection
session
SimpleXML
sodium
SPL
sqlite3
standard
tokenizer
xml
xmlreader
xmlwriter
zlib

[Zend Modules]
```
按照经验我们还需要以下扩展才能大致满足需求:
- `redis` 扩展，redis作为主流缓存已经是`web`应用必不可少的组件。虽然有`php`写的`redis`类库，但是考虑到运行性能还有后期的`php`应用镜像的体积，我们还是有必要安装一个`redis`C的扩展到基础镜像中。
- `zip` 这个文件压缩也是使用频率较高的，当然如果你不这么认为的话也可以先不加入，等后续需要的时候再从本镜像构建一个新的镜像。
- `swoole` 同样的，如果你认为不是很必要可以暂时不添加。
- `gd` 现在虽然有很多云厂商提供的文件存储服务直接就带有图片处理服务，但是我认为图片处理扩展是必须的。图形验证码的生成不能没有这个扩展。当然如果你确定你的应用不需要图片处理也可以暂时不添加。
- `pdo_mysql` 这个就不用多说了，我认为进行数据库操作`pdo`是最省心的。其参数绑定特性可以最大程度的防止`sql`注入。这也是很多主流框架类库默认的`mysql`默认操作依赖。
- `opcache` 既然是生产环境可用，那么我们必须为运行性能作一些考虑，所以我认为这个扩展是必须添加的，可以设定为按需开启，毕竟开发环境开启`opcache`并不是一个明智的做法。
- `bcmath` 没有这个库的话可能一些框架或者类库的`composer`依赖校验会无法通过。而且不确定我们的应用程序中是否需要用到它，但是可以预见它被用到的可能性很大。毕竟程序的本质就是运算。
- `composer` 当然，这个并不是扩展，但是它需要运行在当前`php`环境中，才能检查我们`php`环境是否满足一个类库的运行，所以它必须要包含在基础镜像中。最简洁的做法是事先下载好其`phar`包，然后直接打包到当前镜像中。
#### 构建准备
- 下载`composer`运行包，放置在当前工程目录下。下载连接:[composer](https://github.com/composer/composer/releases)。
- 在当前工程目录下创建文件`conf.d/date.ini`， 设置`PHP`默认时区为东8区。其内容为:
```ini
date.timezone = Asia/Shanghai
```
- 在当前工程目录下创建文件`conf.d/opcode.ini`, 设置`opcode`默认的参数，并且设置环境变量`OPCODE`以控制其是否被开启。当环境变量`OPCODE`的值被设置为`1`的时候表示开启`opcode`,`0`则关闭。
```ini
opcache.enable=${OPCODE}
enable_clopcache.enable_cli=1
opcache.revalidate_freq=60
opcache.max_accelerated_files=100000
opcache.validate_timestamps=1
```
#### 最终的`Dockerfile`

说再多不如直接看代码看注释:
```Dockerfile
FROM php:7.3.7-fpm-alpine3.9
LABEL MAINTAINER="tttlkkkl <tttlkkkl@aliyun.com>"
LABEL description="php-fpm 镜像，已开启FCGI，可用于web服务，也可以用于运行 cli 程序。"
ENV TZ "Asia/Shanghai"
ENV TERM xterm
# 默认关闭opcode
ENV OPCODE 0

COPY ./conf.d/ $PHP_INI_DIR/conf.d/
COPY composer.phar /usr/local/bin/composer
RUN echo 'https://mirrors.aliyun.com/alpine/v3.9/main/' > /etc/apk/repositories && \
    echo 'https://mirrors.aliyun.com/alpine/v3.9/community/' >> /etc/apk/repositories

# PHPIZE_DEPS 包含 gcc g++ 等编译辅助类库，完成编译后删除
RUN apk add --no-cache $PHPIZE_DEPS \
    && apk add --no-cache libstdc++ libzip-dev vim\
    && apk update \
    && pecl install redis-4.3.0 \
    && pecl install zip \
    && pecl install swoole \
    && docker-php-ext-enable redis zip swoole\
    && apk del $PHPIZE_DEPS
# docker-php-ext-install 指令已经包含编译辅助类库的删除逻辑
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
    && apk update \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-install -j$(nproc) opcache \
    && docker-php-ext-install -j$(nproc) bcmath \
    && chmod +x /usr/local/bin/composer

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
```

需要解释的几个点:
- `PHP_INI_DIR`：这个环境变量的定义在`php`基础镜像`Dockerfile`中有定义，这也是读懂官方镜像`Dockerfile`文件的裨益之一。
- `PHPIZE_DEPS`：这个也是定义在基础镜像`Dockerfile`中，包含了扩展编译安装时需要但是`php`运行不需要的`linux`软件库。我们需要把它们挑选出来，在编译完扩展之后删除。
- 重置了`alpine`的镜像下载源为国内阿里云镜像站，以加快镜像的构建速度。不然在没有科学上网的情况下，你会抓狂比蜗牛还慢的构建速度。当然这个基础镜像本身的构建速度不会很快，可能还会下载超时导致构建失败，重试，随缘吧，总会构建成功的。
- 制作镜像一定要注意不要留下太多运行时不需要的文件，保证最小镜像体积。弄清楚每一步每一条命令的用途，切不可随意复制粘贴。

希望本文可以对你的`php`镜像制作带来一些帮助，事实上本文贴出的`Dockerfile`文件已经经过测试，你如果不想太折腾的话可以直接拿来用。

有不当之处还请指正。