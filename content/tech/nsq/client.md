---
title: "NSQ客户端TCP协议详解"
date: 2017-05-15T15:56:20+08:00
tags:
  - nsq
  - nsq client
---

 nsq提供了各种语言的客户端，其中最完全的golang和python库。PHP库用PHP原生socket编写执行效率有待验证并且github上的代码下载下来后缺少事件循环相关代码。故决定基于swoole实现一个PHP版本的nsq客户端，部分代码参考原来的PHP客户端库。后续将分几篇文章讲述实现过程。
#### 客户端TCP协议
根据官方文档的说明，客户端连接之后需要发送一个“magic”标识的命令来约定通讯协议，本客户端使用V2通讯协议。TCP消息体是“  V2”，即两个空格接一个大写“V”再接一个“2”;成功后返回“OK”，相关消息解包和封包后续介绍。约定服务协议之后客户端可以发送“IDENTIFY”命令来进行服务协商，来确定是否需要auth认证，是否需要心跳，添加客户端自述等。当然客户端不能通过这个命令终止auth认证但是可以禁用心跳，更具体的请参看后文介绍。为了消费消息，客户端必须订阅（sub）到一个通道（channel）。nsq消息被发布（pub）到一个频道之后，每条消息都会在该话题（topic）下的频道中分发一个消息副本。每个频道中的消息都至少被发送一次，也就是是说处理相同业务逻辑的服务需要订阅到一个频道中。按照官方文档中的举例来说话题描述数据，而通道描述工作类型。比如以一个api请求名作为话题名称，然后话题中创建相应的通道，归档、分析增长、分析垃圾等作为通道名标识下行服务处理类型。订阅成功之后需要发送“RDY”命令来标识客户端准备接收的消息数量，如果为0将没有消息被发送到客户端，如果为100将有100条数据被发送到客户端。在本次客户端中每次都标识接收一条消息。

 V2版本通信协议默认每隔30秒向客户端发送一个心跳消息“_heartbeat_”，客户端需要通过“NOP”命令来响应，如果连续两个心跳检测消息没有被响应，TCP连接将会关闭。

#### 消息类型
```
首先来看一下官方文档给出的数据格式：
[x][x][x][x][x][x][x][x][x][x][x][x]...
|  (int32) ||  (int32) || (binary)
|  4-byte  ||  4-byte  || N-byte
------------------------------------...
    size     frame type     data
```
首先是4字节的32位大端序无符号长整数，标识消息长度（从第四个字节开始计算，第一个字节序号为0）。接着还是一个4字节的大端序无符号长整数，标识消息的类型，在PHP中用`unpack('N', $param);`解码。最后是消息内容。

- 消息类型为0表示正常的响应（response）消息。响应消息可以按照响应内容（data）分为以下两种。
    - `OK`响应，即成功。
    - `_heartbeat_`，即心跳响应。
- 消息类型为1表示错误响应，data部分为错误消息。
- 消息类型为2表示消费消息，data部分即为nsq消息。

消息类型的data部分遵循如下数据格式：
```
[x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x][x]...
|       (int64)        ||    ||      (hex string encoded in ASCII)           || (binary)
|       8-byte         ||    ||                 16-byte                      || N-byte
------------------------------------------------------------------------------------------...
  nanosecond timestamp    ^^                   message ID                       message body
                       (uint16)
                        2-byte
                       attempts
```
起始是一个8字节的64位整型数字表示一个纳秒级的时间戳。接着是一个2位的16位整型数字表示消息的重复次数，也即消息被重新排队次数。后面是16字节标识的消息id，解包后是一个字符串，具有唯一性。最后是nsq消息的真正内容，字符类型。具体解包过程请参看程序实现，参考原有PHP类库没有经过验证和测试。个人认为是正确可行的，在生产环境中已有大量应用。

#### 消息指令
##### `IDENTIFY`

这个指令更新服务器上的客户端元数据和协商功能，已在前文提到。消息格式如下：
```
IDENTIFY\n
[ 4-byte size in bytes ][ N-byte JSON data ]
```
消息格式是一个字符串“IDENTIFY”接一个回车换行“\n”。然后是一个4字节的大端序整数表示消息长度，即最后的data部分的长度。data内容是一个json格式的字符数据，它支持以下字段：

- short_id (nsqd v0.2.28+ 版本之后已经抛弃，使用 client_id 替换)这个标示符是描述的简易格式（比如，主机名）

- long_id (v0.2.28+ 版之后已经抛弃，使用 hostname 替换)这个标示符是描述的长格式。(比如. 主机名全名)

- client_id 这个标示符用来消除客户端的歧义 (比如. 一些指定给消费者)。

- hostname 部署了客户端的主机名。

- feature_negotiation (nsqd v0.2.19+) bool， 用来标示客户端支持的协商特性。如果服务器接受，将会以 JSON 的形式发送支持的特性和元数据。指定这个为true之后将会返回是否需要授权等协商信息。

- heartbeat_interval (nsqd v0.2.19+) 心跳的毫秒数。有效范围: 1000 <= heartbeat_interval <= configured_max (-1 禁用心跳)，--max-heartbeat-interval (nsqd 标志位) 控制最大值，默认值 --client-timeout / 2。

- output_buffer_size (nsqd v0.2.21+) 当 nsqd 写到这个客户端时将会用到的缓存的大小（字节数）。有效范围: 64 <= output_buffer_size <= configured_max (-1 禁用输出缓存)，--max-output-buffer-size (nsqd 标志位) 控制最大值，默认值 16kb。

- output_buffer_timeout (nsqd v0.2.21+)超时后，nsqd 缓冲的数据都会刷新到此客户端。有效范围: 1ms <= output_buffer_timeout <= configured_max (-1 禁用 timeouts)，--max-output-buffer-timeout (nsqd 标志位) 控制最大值，默认值 250ms。警告: 使用极小值 output_buffer_timeout (< 25ms) 配置客户端，将会显著提高 nsqd CPU 的使用率（通常客户端连接时 > 50 ）。这依赖于 Go 的 timers 的实现，它通过 Go 的优先队列运行时间维护。

- tls_v1 (nsqd v0.2.22+) 允许 TLS 来连接。--tls-cert and --tls-key (nsqd 标志位s) 允许 TLS 并配置服务器证书，如果服务器支持 TLS，将会回复 "tls_v1": true。客户端读取 IDENTIFY 响应后，必须立即开始 TLS 握手。完成 TLS 握手后服务器将会响应 OK。
- snappy (nsqd v0.2.23+) 允许 snappy 压缩这次连接，--snappy (nsqd 标志位) 允许服务端支持。客户端不允许同时 snappy 和 deflate。

- deflate (nsqd v0.2.23+) 允许 deflate 压缩这次连接。--deflate (nsqd 标志位) 允许服务端支持，客户端不允许同时 snappy 和 deflate。

- deflate_level (nsqd v0.2.23+) 配置 deflate 压缩这次连接的级别，--max-deflate-level (nsqd 标志位) 配置允许的最大值，有效范围: 1 <= deflate_level <= configured_max，值越高压缩率越好，但是 CPU 负载也高。

- sample_rate (nsqd v0.2.25+) 投递此次连接的消息接收率。有效范围: 0 <= sample_rate <= 99 (0 禁用)，默认值 0。

- user_agent (nsqd v0.2.25+) 这个字段的值将会在nsqadmin频道机器信息的“User-Agent”字段中展示。默认值: <client_library_name>/<version>。
- msg_timeout (nsqd v0.2.28+) 配置服务端发送消息给客户端的超时时间，成功后响应：“OK”，注意: 如果客户端发送了 feature_negotiation (并且服务端支持)，响应体将会是 JSON类似这样：
```
{
    "max_rdy_count": 2500,
    "version": "1.0.0-compat",
    "max_msg_timeout": 900000,
    "msg_timeout": 60000,
    "tls_v1": false,
    "deflate": false,
    "deflate_level": 0,
    "max_deflate_level": 6,
    "snappy": false,
    "sample_rate": 0,
    "auth_required": true,
    "output_buffer_size": 16384,
    "output_buffer_timeout": 250
}
```
错误后的响应内容:
```
E_INVALID
E_BAD_BODY
```

##### `SUB`

订阅话题（topic) /通道（channel)
消息格式：
```
SUB <topic_name> <channel_name>\n
```
<topic_name> - 字符串 (建议包含 #ephemeral 后缀)。
<channel_name> - 字符串 (建议包含 #ephemeral 后缀)。
最后是一个回车换行。
成功后响应:
`
OK
`
错误后响应:
```
E_INVALID
E_BAD_TOPIC
E_BAD_CHANNEL
PUB
```

##### `PUB`
发布一个消息到 话题（topic):
消息格式：
```
PUB <topic_name>\n
[ 4-byte size in bytes ][ N-byte binary data ]
```

<topic_name> - 字符串，目标话题名称 (建议 having #ephemeral suffix)，一个回车换行符。
接4字节的大端序整数标识消息长度，最后接消息内容，字符串。

成功后响应:

`OK`

错误后响应:
```
E_INVALID
E_BAD_TOPIC
E_BAD_MESSAGE
E_PUB_FAILED
```

###### `MPUB`

发布多个消息到话题（topic) ，nsqd v0.2.16+ 有效。
消息格式：
```
MPUB <topic_name>\n
[ 4-byte body size ]
[ 4-byte num messages ]
[ 4-byte message #1 size ][ N-byte binary data ]
      ... (repeated <num_messages> times)
```
<topic_name> 字符串 ，目标话题名称(建议 having #ephemeral suffix)。
接着是4字节的大端序整数表示消息长度，后面4字节的大端序整数表示消息个数。然后是单个消息体长度加消息内容，此部分个数和前面指定的消息个数一致。说着有点绕，上一段PHP封包函数代码，一目了然：
``` php
    /**
     * 批量推送消息到话题
     *
     * @param $topic
     * @param array $message
     *
     * @return string
     */
    public static function mPub($topic, array $message)
    {
        $cmd = self::packing('MPUB', $topic);
        $num = pack('N', count($message));
        $bodyLen = 0;
        $body = '';
        foreach ($message as $msg) {
            $len = strlen($msg);
            $bodyLen += $len;
            $body .= pack('N', $len) . $msg;
        }
        return $cmd . pack('N', $bodyLen) . $num . $body;
    }
```
成功后响应:

`OK`

错误后响应:
```
E_INVALID
E_BAD_TOPIC
E_BAD_BODY
E_BAD_MESSAGE
E_MPUB_FAILED
```

###### `RDY`

更新 RDY 状态 (表示你已经准备好接收N 消息),nsqd v0.2.20+ 使用 --max-rdy-count 表示这个值。
消息格式：
```
RDY <count>\n
```
<count> 客户端准备接收的消息个数，这个值不能大于nsqd配置中的最大值。

注意: 这个指令没有成功后响应。

错误后响应:`E_INVALID`


##### `FIN`

完成一个消息 (表示成功处理)。

消息格式：
```
FIN <message_id>\n
```
<message_id> 16字节的nsq消费消息id，即前文提到的唯一消息id。
注意: 这里没有成功后响应。

错误后响应:
```
E_INVALID
E_FIN_FAILED
```

##### `REQ`

重新将消息队列（表示处理失败）。

这个消息放在队尾，表示已经发布过，但是因为很多实现细节问题，不要严格信赖这个，将来会改进。

简单来说，消息在传播途中，并且超时就表示 REQ。
消息格式：

```
REQ <message_id> <timeout>\n
```
<message_id> 消息id。
<timeout> 排队超时时间。
注意: 这里没有成功后响应。

错误后响应:
```
E_INVALID
E_REQ_FAILED
```

##### `TOUCH`

重置传播途中的消息超时时间。

注意: 在 nsqd v0.2.17+ 可用。
消息格式：
```
TOUCH <message_id>\n
```
<message_id> 消息id。
注意: 这里没有成功后响应。

错误后响应:
```
E_INVALID
E_TOUCH_FAILED
```

##### `CLS`

清除连接（不再发送消息）
消息格式：
```
CLS\n
```
成功后响应:
```
CLOSE_WAIT
```
错误后响应:
```
E_INVALID
```

##### `NOP`

心跳反馈。
消息格式：
```
NOP\n
```
注意: 这里没有响应。

##### `AUTH`

注意: 在 nsqd v0.2.29+ 可用。

如果 IDENTIFY 响应中有 auth_required=true，客户端必须在 SUB,PUB或MPUB命令前前发送AUTH否则将无法继续后续操作。如果要启用auth需要在启动nsqd时通过“--auth-http-address”参数选项指定一个auth授权地址（注意这个写到配置文件中无效）。此时nsqd就要求tcp客户端进行授权验证。收到客户端授权指令后nsqd将会请求授权地址其uri为`/auth?remote_ip=127.0.0.1&secret=auth&tls=false`。授权服务器需要返回如下信息：
```
{
    "ttl": 5,
    "identity": "authServer",
    "identity_url": "http://w.auth.com/api/auth",
    "authorizations": [
        {
            "permissions": [
                "subscribe",
                "publish"
            ],
            "topic": "nsq_common",
            "channels": [
                ".*"
            ]
        },
        {
            "permissions": [
                "subscribe",
                "publish"
            ],
            "topic": "nsq_test",
            "channels": [
                ".*"
            ]
        }
    ]
}
```
下面再贴一段PHP代码来说明以上参数（看代码注释），可以将此代码保存在index.php文件中然后在目录执行`php -S 127.0.0.1:9005`再执行类似`sudo /usr/local/nsq/bin/nsqd -config=/usr/local/nsq/bin/nsqd.cfg --auth-http-address=127.0.0.1:9005`这样的命令来测试auth功能和特性。
``` php
$auth = [
    // 每隔五秒查询一次授权服务器
    'ttl'            => 5,
    //身份，授权成功后返回给客户端
    'identity'       => 'authServer',
    //授权链接可以忽略,授权成功后返回给客户端
    'identity_url'   => 'http://w.auth.com/api/auth',
    'authorizations' => [
        [
            'permissions' => ['subscribe', 'publish'],
			//授权的话题
            'topic'       => 'nsq_common',
			//授权的频道
            'channels'    => [
                '.*'
            ]
        ],
		[
            'permissions' => ['subscribe', 'publish'],
			//授权的话题
            'topic'       => 'nsq_test',
			//授权的频道
            'channels'    => [
                '.*'
            ]
        ]
    ]
];
//throw new Exception('');
echo json_encode($auth, JSON_UNESCAPED_UNICODE);
```
nsqd在“ttl”指定的时间（单位秒）内查询一次授权服务器，如果授权信息变更客户端需要重新提交授权信息否则将会所有订阅、发布等操作。授权对http或https的发布不起作用。也就是说需要客户端授权认证时只能使用TCP协议进行发布。除非nsq队列服务提供给第三方，否则内部系统中不建议启用授权认证。可以依此实现基于OAUTH协议的授权，视实际需要而定吧。
客户端成功认证后会收到类似这样一条响应消息：
```
{
    "identity": "authServer",
    "identity_url": "http://w.auth.com/api/auth",
    "permission_count": 2
}
```

消息格式：
```
AUTH\n
[ 4-byte size in bytes ][ N-byte Auth Secret ]
```
成功后响应:JSON 包含授权给客户端的身份，可选的 URL，和授权过的权限列表：
```
{"identity":"...", "identity_url":"...", "permission_count":1}
```
错误后响应:
```
E_AUTH_FAILED - An error occurred contacting an auth server
E_UNAUTHORIZED - No permissions found
```

#### 结语
至此已讲解完nsq的TCP协议，后续将讲解依此实现的PHP客户端,觉得有需要改进的地方欢迎留言，顺便帮加个star。
代码仓库：
- github：[github](https://github.com/tttlkkkl/nsq_swoole_client)
- oschina：[oschina](https://git.oschina.net/tttlkkkl/nsq_swoole_client)
