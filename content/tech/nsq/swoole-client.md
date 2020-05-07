---
title: "基于SWOOLE的NSQ异步客户端"
date: 2017-05-16T22:10:28+08:00
draft: true
tags:
  - nsq
  - swoole
  - 异步客户端
---

swoole号称“重新定义PHP”，请注意这里的引号是语气加强。swoole的出现确实使PHP在网络异步编程着一块有了长足的进步，更多接信息可电梯直达[官网](http://www.swoole.com)。依托swoole的异步TCP客户端可以很容易的实现前文所述的NSQ TCP通信协议，由于没有在生产环境中进行过大规模的使用，其稳定性和可靠性不敢在此妄言，其他的也一定还有很多可改进的地方。可以确定的是它足够简单可以很容易的做出调整并应用到实际项目中。编写此类库的初衷有二：
- github上的基于PHP实现的NSQ类库长期未更新，支持的特性较少（AUTH都不支持），下载的类库缺少事件循环相关代码。
- 既然使用PHP消费NSQ，swoole扩展必是首选，不论从代码执行效率还是代码复杂度，亦或是对swoole的偏执都应该用swoole直接连接NSQ而不是用第三方类库。
故而动手造了这个轮子。
#### 简单使用
在类库源码目录下有`Pub.php`和`Sub.php`可以直接执行，测试类库可用性。
#### 流程图
![流程图](/images/nsq-5/flow.png)

#### 使用示例
已编写基于此客户端类库的使用示例,直接下载运行体验。
[github](https://github.com/tttlkkkl/swoole-nsq)。
[oschina](https://git.oschina.net/tttlkkkl/swoole-nsq)。

#### 编码实现
本来想详细的罗嗦一下具体实现过程，但是实在不知道如何开始，实在太罗嗦了还不如直接看代码来的快。
仓库地址（如有任何问题欢迎在留言区留言指正，还有顺便点个star）：
[github](https://github.com/tttlkkkl/nsq_swoole_client)。
[oschina](https://git.oschina.net/tttlkkkl/nsq_swoole_client)。


