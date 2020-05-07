---
title: "consul 集群测试"
date: 2018-01-06T22:17:35+08:00
tags:
- consul
- 微服务
- 注册与发现
- 集群
---

#### 说明
本文在3个vbox构成的与真实环境近似的本地网络环境中测试consul的可用性，以及记录使用方法。
#### 环境准备
安装 centos 7 的 vbox 虚拟机，安装和配置方法参考本站《centos7在vbox中最小化安装以及共享文件夹设置实践 》一文，在虚拟机中安装consul，安装方式见[consul.io](https://www.consul.io)。到下载页面下载对应操作系统的本本，对于 linux 而言只需要将下载后解压出来的二进制文件拷贝到`/usr/bin`目录下面，并给予可执行权限即可：`chmod +x consul`。

将此虚拟机导出再导入以创建另外两个虚拟机，也可以用链接复制的方式创建另外两个虚拟机（推荐）。

确保机器之间可联通。最快捷的办法是在网络设置中为虚拟机设置两个网卡,网卡1选 网络地址转换(NAT),网卡2选 仅主机(Host-Only)网络，如下两图：
![网卡1](/images/consul-test/1.png)

![网卡2](/images/consul-test/2.png)

一般而言会通过dhcp分配一个与vbox虚拟网卡网段一致的ip如下图所示的192.168.56.101 再以同样的方法设置第二个虚拟机其ip应该是192.168.56.102第三个则是192.168.56.103顺序累加。此ip可在主机中ping通,虚拟机相互之间也可以ping通，consul需要绑定在这个ip上：

![联通网络示意1](/images/consul-test/3.png)

![联通网络示意2](/images/consul-test/4.png)

#### 集群启动
##### 机器命名
为方便后续描述这里定义一下主机:
sev1:192.168.56.101
sev1:192.168.56.102
sev1:192.168.56.103

##### sev1中启动第一个节点
- 创建配置目录:
```shell
mkdir /etc/consul.d
```
- 创建数据目录

```shell
mkdir -p /www/consul 
```
- 启动命令
```shell
consul agent -server -bootstrap-expect 1 -data-dir /www/consul -node=agent-one -bind=192.168.56.101 -config-dir /etc/consul.d -client 0.0.0.0 -ui
```
##### 选项说明
- -bootstrap-expect 指明预计要加入的其他节点的数量，这里为1表名以单节点启动而不进行服务选举,后续节点中不需要此参数因为不是以server角色启动
- -data-dir 指定数据存储目录。
- -node 指定节点名称。
- -bind 指定绑定ip，consul将监听此ip。
- -config-dir 指定配置文件目录。
- -client 0.0.0.0 -ui  启动ui界面,**注意如果没有-client 0.0.0.0 这一段web界面将只能通过127.0.0.1访问。**
#### sev2中启动第二个节点
- 创建配置目录:
```shell
mkdir /etc/consul.d
```
- 创建数据目录

```shell
mkdir -p /www/consul
```
- 启动命令
```shell
consul agent -data-dir /www/consul -node=agent-two -bind=192.168.56.102 -config-dir /etc/consul.d
```
#### sev3中启动第三个节点
- 创建配置目录:
```shell
mkdir /etc/consul.d
```
- 创建数据目录

```shell
mkdir -p /www/consul
```
- 启动命令
```shell
consul agent -data-dir /www/consul -node=agent-thr -bind=192.168.56.103 -config-dir /etc/consul.d
```
#### 联通节点
此时创建的3个consul节点还不能互通需要手动加入，在有server角色的sev1中执行命令(实际上可以在任意节点加入其它节点)。
```shell
consul join 192.168.56.102 & consul join 192.168.56.103
```

#### 可能遇到的错误
如果报错如下，检查防火墙是否允许8301端口，或者直接关闭防火墙:
```shell
Error joining address '192.168.56.102': Unexpected response code: 500 (1 error(s) occurred:

* Failed to join 192.168.56.102: dial tcp 192.168.56.102:8301: getsockopt: no route to host)
Failed to join any nodes.
```
#### 查看结果
```shell
consul members
```
显示如下:
```shell
[root@m m]# consul members
Node       Address              Status  Type    Build  Protocol  DC   Segment
agent-one  192.168.56.101:8301  alive   server  1.0.2  2         dc1  <all>
agent-thr  192.168.56.103:8301  alive   client  1.0.2  2         dc1  <default>
agent-two  192.168.56.102:8301  alive   client  1.0.2  2         dc1  <default>
```

#### web界面
![web界面](/images/consul-test/5.png)
