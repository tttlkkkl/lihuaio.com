---
title: "VirtualBox 安装 alpine linux 记录"
date: 2018-06-24T14:55:00+08:00
tags:
- alpine
- linux
- VirtualBox
---

VirtualBox 下面下载安装 30多兆的虚拟机专用版即可，更为详细的安装教程再 csdn 能找到很多，我这里主要记录安装过程中遇到的一些坑。

#### 安装目标
不通过端口转发也能直接连接虚拟机，这就需要额外添加***端口转发***以外的一张网卡，就使用centos 的经历来说添加一张  络地址转换（NAT）的网卡 再添加一张 ***仅主机(HOST-Only)网络***的网卡可以达到目的。
#### 一个奇怪的错误：

```shell
e2fsprogs (missing):
 required by: world[e2fsprogs]
sfdisk (missing):
 required by: world[sfdisk]
syslinux (missing):
  required by: world[syslinux]
```
 这个看起来是像是硬盘出了问题，几经折腾发现实际上是因为选择的镜像站不可用或者虚拟机无法连接外网。

#### 第二个奇怪的错误：
``` shell
localhost:/home/m# ping www.baidu.com
ping: bad address 'www.baidu.com'


localhost:/home/m# nslookup https://www.baidu.com
nslookup: can't resolve '(null)': Name does not resolve

nslookup: can't resolve 'https://www.baidu.com': Try again
```
这个看起来是因为dns服务器有问题 `vi /etc/resolv.conf`  手动修改dns服务器，重启网络之后复原为 vbox dhcp  提供dns的地址,这个就让人束手无策了。折腾过后发现这个问题实际上是因为无法连接外网造成的。

#### 第三个奇怪的问题：

/etc/init.d/networking restart 重启网络时报错如下：

``` shell
	ip: RTNETLINK answers: File exists 
	ip addr flush eth0
	ip addr flush eth1
```

这个看起来是网卡出现了问题，事实上以上所有的问题都是因为添加了 ***仅主机(HOST-Only)网络*** 造成的问题。
正确的做法是添加第二张网卡时选择网卡类型为 ***桥接网卡***。

#### setup-alpine 
这里主要记录我个人认为必须或者必须要手动干预的几个步骤：

- Enter system hostname (short form, e.g. 'foo') [localhost] ：这一步可以选择一个自己看着顺眼的字符作为 alpine 系统的主机名。
- Changeing password for root New password: 必须要为root账户设置一个密码，因为时日常测试要用最好简单到只有一个字母或数字。
- Which timezone are you in? ('?' for list) [UTC]：国内输入 Asia/Shanghai  ，避免后续使用上的问题。
- Enter mirror number (1-21) or URL to add (or r/f/e/done) [f] ：这里必须键入 e 手动编辑镜像源，进入vi命令模式之后直接 `o` 另起一行键入国内的镜像源就行了。可选的输入有阿里云：`https://mirrors.aliyun.com/alpine/v3.7/main`  清华大学：`https://mirror.tuna.tsinghua.edu.cn/alpine/v3.7/main`。注意版本号。***注意：此步骤失败后续安装都无法成功，这就意味着虚拟机必须可以联通外网***

- 安装盘选择
``` shell
	Available disks are:
  	sda   (2.1 GB ATA    VBOX HARDDISK    )
	Which disk(s) would you like to use? (or '?' for help or 'none') [none]
```
这里选择安装盘，一般虚拟机只分配了一个硬盘，直接输入 sda 回车。
- 选择安装方式：
```shell
	The following disk is selected:
 	 sda   (8.6 GB ATA      VBOX HARDDISK    )
	How would you like to use it? ('sys', 'data', 'lvm' or '?' for help) [?]
```
这里键入 sys 才会把系统安装到硬盘上去。

####  宿主机 ssh 连接
- `ip address show` 命令查看网络配置，可以看到一个 `192.168.1`网段的ip，可以直接在宿主机通过这个 ip 连接 alpine。
- root 默认是禁止 ssh 登录的，可以 `adduser` 新建一个专门用于 ssh 登录的普通用户。

#### 共享文件夹
- 安装必要的包：`apk add virtualbox-guest-additions virtualbox-guest-modules-virthardened`
- 可能遇到的错误:
``` shell
	alpine:/home/m# apk add virtualbox-guest-additions virtualbox-guest-modules-	virthardened
	ERROR: unsatisfiable constraints:
 	 virtualbox-guest-additions (missing):
   	 required by: world[virtualbox-guest-additions]
  	virtualbox-guest-modules-virthardened (missing):
   	 required by: world[virtualbox-guest-modules-virthardened]
```
 出现这个错误时需要启用社区库：
`vi /etc/apk/repositories`  加一条记录，如阿里云镜像站：`https://mirrors.aliyun.com/alpine/v3.7/community` 保存。然后执行 `apk update`，再进行安装。
- 在虚拟机设置好共享文件夹，假如共享文件夹名称为 work 。
- 创建一个共享文件夹挂载目录 `mkdir /mnt/share`。
- 挂载共享文件夹:`mount -t vboxsf work /mnt/share`。如果这一步遇到错误尝试执行`modprobe -a vboxsf` 以激活共享目录模块。



