---
title: "centos7在vbox中最小化安装以及共享文件夹设置实践"
date: 2017-08-21T19:56:44+08:00
tags: 
- VirtualBox
- centos
- linux
---

#### 本文缘起
限于即时通讯等各种因素日常开发智能在Windows中进行，这个时候就需要在虚拟机中安装一个linux系统已满足常规的开发、测试、和学习。我比较喜欢用VirtualBox作为虚拟电脑，因为它免费^-^。已经安装过很多次，一些关键操过些日子作都会忘掉，刚好虚拟电脑不小心被删除了，借此重装之机记录其中主要过程，以安装centos7为例。每次都下载4G以上的镜像包，要是网络环境不好，这个等待是让人无法忍受的。此次尝试安装最小化包（只有600M左右）。希望能帮到在vmware和vbox之间折腾的同僚。

#### 准备工作
- VirtualBox，可以去[官网](https://www.virtualbox.org/)下载最新的程序进行安装。
- centos7最小化安装包，国内推荐去阿里云镜像站下载：[https://mirrors.aliyun.com/centos/7.3.1611/isos/x86_64/](https://mirrors.aliyun.com/centos/7.3.1611/isos/x86_64/)。

#### 系统安装
这部分内容网上可以找到很多，这里就不在详细说明了，不过简单提一下步骤：
- 新建一个虚拟电脑，点击新建然后按照提示操作即可。如果没有找到64位系统选项你需要去BIOS中开启虚拟化支持，具体百度之。硬盘建议固定分配。
- 设置虚拟电脑存储->控制器，然后点击光盘小图标，再点选“选择一个虚拟光盘文件”，将下载好的iso镜像包添加进来。
- 设置虚拟电脑系统将光驱启动调至第一位（安装好后调成硬盘第一位）。
- 启动虚拟电脑按照提示完成安装。

#### 设置网络
默认的centos安装之后无法进行网络连接，需要手动配置，最小安装的就更不用说了，其他以下基础的命令工具都缺失。比如`ifconfig`命令都不存在的，当然它有更高级的`ip`命令替代（当初也有安装过最小版，但是因为没有`ifconfig`命令我直接安装完全版了，现在想来当时实在是太冤了）。只有设置好了网络才能安装需要的工具和环境愉快的玩耍，不然就像如下图一样不能进行任何网络连接，因为网卡是被禁止的状态：
![图1](/images/vbox-centos/1.png)
以下图文分步说明（除此之外当然也可以直接编辑网卡配置文件）：
- 输入`nmtui`进行网络编辑如下图，选择激活连接:
![图2](/images/vbox-centos/2.png) 
- 选择网卡并回车激活网络如下图：
![图3](/images/vbox-centos/3.png)
- 至此虚拟机已可以连接外网，但是这种方式激活的网络在重启电脑后就失效了，我在想要是用终端连接远程电脑并且用这种方式将网络取消激活了会怎么样呢...
- 设置为开机有效，即自动激活：上上图中的操作选择编辑连接进入编辑页面，设置为如下图所示的设置并选择“ok”保存设置。***注意！！！图中的“X”只能通过空格键选中和取消选中***：
![图4](/images/vbox-centos/4.png)

#### 安装必要的工具
- 安装rz、sz命令:`yum install lrzsz`
- 安装命令补齐（当然这个不是必须的）:`yum install bash-completion`

#### 设置xshell连接
- 在vbox中设置虚拟电脑网络端口转发，以实现xshell等Windows终端软件连接虚拟电脑。连接方式选择“网络地址转换”，然后配置端口转发规则，如下图所示。其中主机ip为vbox在Windows中创建的网卡ip一般为“192.168.56.1”,子系统ip则是虚拟电脑中自动分配给网卡的ip用`ip`命令查得。端口如果没有作其他特别的改动就是默认的22端口。
![图7](/images/vbox-centos/7.png)
- 举一反三，要在Windows下的浏览器中访问虚拟机中建立的网站等服务程序也是用这种端口转发的方式。

#### 设置共享文件夹

##### 设置vbox
如下图所选择一个Windows下的本地路径作为一个共享文件夹:
![图5](/images/vbox-centos/5.png)

##### 安装增强工具
网上的说法都是在开启的虚拟电脑窗口中选择 设备->安装增强功能。如果此操作能成功，那么恭喜！但是百分之98的情况下都会失败而且一般提示”未能加载虚拟光盘 C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso 到虚拟电脑os.
Could not mount the media/drive C:\ProgramFiles\Oracle\VirtualBox/VBoxGuestAdditions.iso (VERR_PDM_MEDIA_LOCKED).“就像下面这张图中一样。要是按照网上普遍的做法进行处理那么你就输了，如果第一次使用vbox有可能一天一夜都折腾不出来，然后开始怀疑vbox根本不能用，还是用收费并且笨重的vm吧...
![图6](/images/vbox-centos/6.png)
还有没有其他方法？那是必须的而且很简单:
- 将vbox安装目录的VBoxGuestAdditions.iso文件拷贝到虚拟机系统中（注意安装了rz命令之后用xshell连接虚拟机然后直接将文件拖动到xshell终端窗口中即可）。这个文件就是以上错误信息中说的这个文件。
- 如何将该文件拷贝到虚拟电脑中呢？答案是用前文安装的`rz`命令。当然，直接拖到xshell窗口中也是可以的。
- 将这个iso文件挂载到系统中，可以理解为解压,并执行安装：
	* `mkdir /mnt/cdrom`
	* `mount -o loop VBoxGuestAdditions.iso /mnt/cdrom/`
	* `./VBoxLinuxAdditions.run`
- 执行完以上步骤一定是不成功的，因为我们安装的是最简系统，会缺少很多东西，根据提示将缺少的东西安装上去就好了，错误信息在日志文件中查找一般而言路径为“/var/log/VBoxGuestAdditions.log”，在错误信息中给出。
- 遇到这种情况首先应该执行`yum update`命令，更新所有软件包，包括内核。
- 根据错误信息"      b. vboxadd.sh: failed: Look at /var/log/vboxadd-install.log to find out what went wrong.vboxadd.sh: failed: Please check that you have gcc, make, the header files for your Linux kernel and possibly perl installed.."安装缺失的软件包:`yum install gcc make kernel-devel kernel-header perl`
- 安装好依赖的软件包之后依然安装失败，此时尝试将内核加入环境变量:
	- 搜索内核路径:`find / -type d -name '*kernel*'`
	- 将得到的内核路径加入环境变量,如:`export KERN_DIR=/usr/src/kernels/3.10.0-514.26.2.el7.x86_64/`


一般而言做完以上操作之后就可以正常使用安装增强工具了。

#### 挂载共享文件夹
已上文在vbox中配置的“D:\goRoot“为例：
- `mkdir /mnt/share`
- `mount -t vboxsf goRoot /mnt/share`
- 如果报错：“/sbin/mount.vboxsf: mounting failed with the error: No such file or directory”，检查vbox共享目录是否设置正确，挂载目录/mnt/share是否创建成功。
至此万事具备，就差在Windows下愉快的玩耍centos虚拟机了。

