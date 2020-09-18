---
title: "[教程]使用 drone 实现博客自动部署"
date: 2020-09-18T14:02:27+08:00
draft: false
tags:
- ops
---

容器技术的发展使得 devops 也有了蓬勃的发展。drone 是我在众多 CI/CD 最终选择的工具。其基于 docker 容器的插件机制可以很方便的应对各种复杂环境更具有实用性和易用性。官网地址：[https://drone.io/](https://drone.io/)。除了可自行安装的社区版，也提供了在线运行服务。

实现流水线自动部署之后可以在任何支持 git 的地方更新博客。无需纠结环境不完备带来的不便。

本教程需要具备的前提条件:
- 使用 github 存储博客的源码。
- 跟本博客一样也是部署在阿里云 oss，部署方法见 [部署 hugo 网站到 oss ](/tech/oss-site)。
- 跟本博客一样采用 hugo 生成静态代码。
- 一个 docker 镜像仓库，使用 hub.docker.com 即可。

## 镜像构建
*注意：我已构建基于 hugo 0.75.1（非 extended）的 docker 镜像，如果无其他版本要求，可以直接使用该镜像。使用方法见文后流水线编排文件内容。*

完成部署需要做两件事：使用 hugo 将源码生成静态 html 站点文件，也就是 public 目录；将 public 目录下的内容上传至 oss 完成更新。

所以我们的 docker 镜像中需要包含 hugo 和 oss 上传工具 ossutil 。Dockerfile 文件如下：
```Dockerfile
FROM alpine:3.12

ADD http://gosspublic.alicdn.com/ossutil/1.6.19/ossutil64 /usr/bin/
# ADD https://github.com/gohugoio/hugo/releases/download/v0.75.0/hugo_extended_0.75.0_Linux-64bit.tar.gz /usr/bin
COPY hugo /usr/bin/
COPY run.sh /usr/bin/run.sh
RUN chmod 755 /usr/bin/ossutil64 && chmod +x /usr/bin/run.sh \
&& echo 'https://mirrors.aliyun.com/alpine/v3.12/main/' > /etc/apk/repositories \
&& echo 'https://mirrors.aliyun.com/alpine/v3.12/community/' >> /etc/apk/repositories \
&& apk add --no-cache git
ENTRYPOINT [ "/usr/bin/run.sh" ]
```
### Dockerfile 解释
由于我的博客以 git submodule 的方式安装了博客主题，所以还需要额外安装一个 git 。

为了加快安装速度替换 alpine 软件镜像源为国内阿里云提供的源地址。

官方编译的 hugo 由于开启了 cgo 导致直接下载的二进制文件无法在 alpine 镜像中运行。会报 not found 的错误。 需要关闭 cgo 重新编译 hugo 以添加到镜像中。

由于 ossutil 的运行需要进行授权，所以我们需要做一些初始化工作：将配置信息写入配置文件 ~/.ossutilconfig 中。run.sh 的内容如下：
```shell
#!/bin/sh
set -e

cat >~/.ossutilconfig<<EFO
[Credentials]
language=CH
accessKeyID=${accessKeyID}
accessKeySecret=${accessKeySecret}
endpoint=${endpoint}
EFO

if [ "${1#-}" != "$1" ]; then
	set -- ossutil64 "$@"
fi

exec "$@"
```
为了安全性密钥的值存储在 drone 的 Secrets 中。流水线运行时从 drone 获取并设置为容器的环境变量。run.sh 脚本获取环境变量并且创建 ~/.ossutilconfig 文件。

#### hugo 编译步骤：
- 在 hugo releases 页面下载对应的源码包。
- 如果本地有 golang 1.11 以及以上环境直接执行编译命令进行编译：
```shell
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o hugo
```
- 如果没有 golang 环境，那么你必须有 docker 环境，使用 docker 编译完成之后从其容器中拷贝 hugo 二进制文件。如果有更好的 docker 基础直接修改源码目录下的 Dockerfile 文件一次构建完成我们需要的镜像。

镜像构建完成后上传至 hub.docker.com 站点，供 drone.io 使用。

## 流水线布置
在博客源码目录创建 .drone.yml 文件，其内容即流水线的执行逻辑：
```yml
kind: pipeline
name: build

steps:
  - name: build-and-push
    image: tttlkkkl/oss:v1.0
    pull: if-not-exists
    environment:
      accessKeyID:
        from_secret: accessKeyID
      accessKeySecret:
        from_secret: accessKeySecret
      endpoint:
        from_secret: endpoint
    commands:
      - run.sh
      - git submodule init
      - git submodule update
      - hugo --environment=production
      - ossutil64 cp -r public oss://bucket-name/ -u
```
该流水线文件可以被正执行的前提：
- 使用 github 账号登录 drone.io 并按照提示进行必要的授权，确保 drone 可以读取博客源码仓库。
- 点击 drone.io 中列出的博客仓库名称，进入 SETTING 选项卡创建所需的密钥k-v对。本流水线编排脚本中需要有阿里云 oss 操作权限的 accessKeyID 和 accessKeySecret ，以及 oss 公网入口地址 endpoint 变量，如果已开启全地域加速此变量的值是 oss-accelerate.aliyuncs.com 。具体以自己的 oss 设置为准。
- 替换 bucket-name 为自己 oss bucket 的名称。

至此，每一次 git push 都会完成自动部署，轻松在办公室和家庭电脑之间交叉写博客。可以在流水线中限定 git 分支部署，避免不必要的更新。当然，也可以使用 hugo 提供的草稿功能。