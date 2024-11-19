---
title: "docker 入门及学习建议"
date: 2020-05-09T14:38:12+08:00
draft: false
tags:
- docker
- 容器技术
- ops
---

### 引言
掌握`docker`的基本操作已经是互联网开发人员必不可少的工作技能。你可能已经意识到这个问题，但是却不知道该如何入手，不知道`docker`具体能用来做什么。你可能很困惑，就像你在困惑k8s到底用来做什么一样。因为你工作中可能没有做过运维任务，服务的开发和部署都是在既定的流程框架内完成的。我一开始也是同样的困惑。没有经历过没`docker`的那些痛苦，或者说没有体验过`docker`带来的便利，有这样的困惑是正常的。

我们需要带着目的去学习。所以`docker`到底是什么，是用来解决什么问题的呢。
### `docker` 是什么
抛开各种高大上的概念和术语，`docker`可以理解为一个运行时打包工具，一次打包就可以在装有`docker`的任何机器上运行。比如你要使用`nginx`部署一个静态网站到N台机器上，最直接的就是在这N台机器上安装`nginx`然后拷贝相关配置文件和代码到这N台机器的相应目录。实际上你可能会编写`shell`脚本来应对重复的工作,这是一个繁琐到让人抓狂的工作。另外一种是你可能使用虚拟机事先将运行环境`nginx`安装在虚拟机中，然后将虚拟机安装到N台主机上，避免了重复安装`nginx`的操作。但是虚拟机不是最佳方案，它启动一个完整的操作系统很耗系统资源，而且安装镜像比较大导致其传输效率很低。都把`docker`比做集装箱,操作系统或者云平台比做大货轮。那么虚拟机可以比做放在货轮上的大货车。两者优劣可想而知。

事实上关于服务的部署大致经历了三个时代：裸机部署时代、虚拟机部署时代、容器平台时代。由于虚拟机技术的弊端，它不是很普及可以说还没开始就被容器技术替代了。

可能还是很困惑，那么直接动手用`docker`跑一个你最熟悉的简单程序。要么继续深入的了解`docker`的概念：[《可能是把Docker的概念讲的最清楚的一篇文章》](http://dockone.io/article/6051)。

### `docker` 安装
现在`docker`的安装方式已经比较统一简洁，对于 windows或者mac系统的用户直接安装桌面版即可:[https://www.docker.com/](https://www.docker.com/)。
- `mac` 的`docker`桌面版我觉得是最适合开发和学习使用的，甚至还支持启动`k8s`环境。
- windows桌面版没有用过不做评论，但是可以确定的是你如果在`windows`中安装了`VirtualBox`或者其他虚拟机，那么`windows`桌面版和虚拟机你只能选择一个。一定要两者一起的话你只能使用`docker machine`安装`docker`，或者直接在虚拟机中安装`docker`。目前`windows`的`linux`子系统没法安装`docker`。总之，在`windows`下面玩`docker`有点不爽利。
- linux系统的用户一条命令安装最新版`docker ce(社区版，企业版是 docker ee)`：
```
curl https://get.docker.com|sh
```
当然也可以按照docker文档中的方式一步步安装：[`1docker`安装文档](https://docs.docker.com/engine/install/)。
### 先玩一下 `docker`
#### 启动一个 `nginx` 服务
```shell
docker run -it --name nginx --rm -p 80:80 nginx
```
如果80端口事先没有被占用，在浏览器访问`127.0.0.1`就可以看到熟悉的`nginx`欢迎界面了。
#### 让`nginx`服务运行一个自定义页面
不更改nginx配置的情况下，输出一个自定义页面。具体做法就是用我们编写好的页面替换`nginx`默认的欢迎页面。
#### 查看`nginx`默认首页的位置：
```shell
#进入已经在运行的nginx容器：
docker exec -it nginx /bin/bash
cat /etc/nginx/conf.d/default.conf
#或者重新创建一个容器并且进入：
docker run -it --rm nginx /bin/bash
cat /etc/nginx/conf.d/default.conf
# 或者直接获取默认配置文件的内容：
docker run -it --rm nginx cat /etc/nginx/conf.d/default.conf
```
以上都是为了查看`nginx`镜像中对`nginx`的默认站点的配置,你可能已经发现了在`docker run`命令最后面是可以运行任何当前镜像支持的命令的，不指定命令的时候运行镜像默认指定的命令，这个命令由`Dockerfile`文件定义。
可以看到默认首页位于 `/usr/share/nginx/html` 目录下,我们现在要做的就是使用自己创建的`index.html`代替默认的`index.html`。

#### 替换默认首页
```shell
# 创建自定义页面：
echo 'hello world!'>index.html
# 直接将文件覆盖复制到正常运行的容器中：
docker cp index.html nginx:/usr/share/nginx/html/index.html
# 在容器启动时通过文件挂载的方式覆盖默认首页:
docker run -it --name nginx --rm -p 80:80 -v $(pwd)/index.html:/usr/share/nginx/html/index.html nginx
# 将自定义页面打包到 docker 镜像文件中直接启动
# todo 见下一小节
```
### 认识 `Dockerfile`
普遍的把`docker`比做集装箱，那么这个`Dockerfile`就是集装箱的货运单，它定义了集装箱包含哪些内容，`docker`按照这个货运单去创建集装箱（镜像）。

这里就不再深入讨论`Dockerfile`。直接继续上一小节的内容以对`Dockerfile`有个初步的认识。
1. 创建一个 Dockerfile 文件,并编辑写入以下内容
```Dockerfile
FROM nginx
COPY index.html /usr/share/nginx/html/index.html 
```
确保整个过程中的`index.html`和`Dockerfile`都在一个文件夹下，然后运行以下镜像构建命令,将网页文件`index.html`打包到`nginx`这个运行时环境中，即名为`docker-study`的镜像：
```shell
docker build -t docker-study .
```
运行镜像看看是否可以达到预期:
```
docker run -p 80:80 nginx-study
```
举一反三，我们也可以直接将编辑好的`nginx`配置打包到镜像中，以达到更多的目的。
### 了解 `docker` 三剑客

#### `docker swarm`
`docker`社区原生提供的容器集群管理工具。`kubernetes`已经是事实上的容器编排标准，尽管已经合并到`docker`主程序上，但是依然很尴尬。所以除非兴趣使然或者确实需要我建议直接去学习`k8s`，毕竟我就是从`swarm`转到`k8s`的。
#### `docker compose`
用来组装多容器应用的工具，可以在`swarm`集群中部署分布式应用，这个还是比较有用的可以让你少写很多重复命令，不仅在实际生产环境在平常开发中也是有必要掌握一下的。
#### `docker machine`
支持多平台安装`docker`的工具，和`k8s`的`kubeadm`是一个性质的工具，除非必要这个不用理会。
