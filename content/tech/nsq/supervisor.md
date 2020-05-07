---
title: "将nsq加入supervisor管理"
date: 2017-04-01T15:56:20+08:00
draft: true
tags:
    - nsq
    - supervisor
---


#### supervisor简介
supervisor是一个用python编写的强大的进程管理工具。网上相关资料铺天盖地，这里就不再重复了。
#### 安装
- centos中安装：
``` shell
sudo yum install python-setuptools-devel
easy_install supervisor
```
- ubuntu中安装：
``` shell
sudo apt-get install python-setuptools
sudo apt-get install  supervisor
```

#### 配置
ubuntu系统默认生成/etc/supervisor/supervisor.conf和/etc/supervisor/conf.d/ 只需要在此目录下加入以.conf结尾的服务配置即可。centos要自行建立相关目录和文件。
我开发机上的/etc/supervisor/supervisor.conf内容：
```
; supervisor config file

[unix_http_server]
file=/var/run/supervisor.sock   ; (the path to the socket file)
chmod=0700                       ; sockef file mode (default 0700)
[inet_http_server]
;web管理页面端口
port =127.0.0.1:9001
;用户名，进入管理界面时需要认证的话配置此项和下面的认证密码。
username=m
;用户密码
password =m
[supervisord]
logfile=/var/log/supervisor/supervisord.log ; (main log file;default $CWD/supervisord.log)
pidfile=/var/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
childlogdir=/var/log/supervisor            ; ('AUTO' child log dir, default $TEMP)

; the below section must remain in the config file for RPC
; (supervisorctl/web interface) to work, additional interfaces may be
; added by defining them in separate rpcinterface: sections
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock ; use a unix:// URL  for a unix socket

; The [include] section can just contain the "files" setting.  This
; setting can list multiple files (separated by whitespace or
        ; newlines).  It can also contain wildcards.  The filenames are
; interpreted as relative to this file.  Included files *cannot*
; include files themselves.

[include]
files = /etc/supervisor/conf.d/*.conf

```
下面是一个nsqd的启动配置,其余的同理：
```
[program:nsqd];nsqd既是启动的服务进程的名称
command=/usr/local/nsq/bin/nsqd -config=/etc/nsq/nsqd.cfg;执行的服务启动命令
process_name=%(program_name)s
autostart=true;程序是否随superviser启动而启动
autorestart=true;程序死了之后是否自动重启

;启动时间，如果超过这个时间没有挂，说明启动成功
startsecs=10
;启动用户
user=openerp
redirect_stderr=true
;log 文件
stdout_logfile=/www/log/supervisor/nsqd.log
stdout_logfile_maxtype=500MB
stdout_logfile_backups=50
stdout_capture_maxbytes=1MB
stdout_events_enable=false
loglevel=warn
```
编辑好文件并保存在/etc/supervisor/conf.d/目录下即可。

贴几个常用命令：
启动supervisord
supervisord -c /etc/supervisor/supervisord.conf


启动supervisord管理的所有进程
supervisorctl start all
停止supervisord管理的所有进程
supervisorctl stop all
启动supervisord管理的某一个特定进程
supervisorctl start program-name // program-name为[program:xx]中的xx
停止supervisord管理的某一个特定进程 
supervisorctl stop program-name  // program-name为[program:xx]中的xx
重启所有进程或所有进程
supervisorctl restart all  // 重启所有
supervisorctl reatart program-name // 重启某一进程，program-name为[program:xx]中的xx
 查看supervisord当前管理的所有进程的状态
supervisorctl status
停止supervisord
supervisorctl shutdown

