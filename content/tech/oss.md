---
title: "阿里云 oss 上传回调踩坑"
date: 2020-07-21T15:21:46+08:00
draft: false
tags:
- go
- oss
---

之前用 PHP 实现 oss 的文件上传，丝毫没有问题，轻松实现。直到使用 go 语言掉入回调大坑，好几天没有爬出来。在此记录一下。

## 坑1 & 被转义

正常情况下使用 go 进行 json 序列化的时候会对，`<`,`>`,`&` 进行转义。`&`最终会被转义成`\u0026`。传到 oss 那边无法被正确解析。可以使`&`在 json 序列化的过程中不被转义：

```go
type ossCallback struct {
	URL      string `json:"callbackUrl,omitempty"`
	Host     string `json:"callbackHost,omitempty"`
	Body     string `json:"callbackBody,omitempty"`
	BodyType string `json:"callbackBodyType,omitempty"`
}

func getCallbackParams(callbackParams map[string]string) string {
	callback := &ossCallback{
		URL:      callbackURL,
		BodyType: "application/x-www-form-urlencoded",
	}
	callback.Body = `bucket=${bucket}&object=${object}`
	if callbackParams != nil {
		var s []string
		for k, v := range callbackParams {
			s = append(s, "&", k, "=", v)
		}
		callback.Body = callback.Body + strings.Join(s, "")
	}
	bf := bytes.NewBuffer([]byte{})
	jsonEncoder := json.NewEncoder(bf)
	jsonEncoder.SetEscapeHTML(false)
	err := jsonEncoder.Encode(callback)
	if err != nil {
		return ""
	}
	return base64.StdEncoding.EncodeToString(bf.Bytes())
}
```

## 坑2 签名验证无法通过

正常情况下使用官给的 go 回调服务端示例可以正常完成签名。移植到框架中之后就不好使了，我这边用的使 gin 框架。经过排查发现是 Request.Body 发生了变更。首先是怀疑 gin 框架对 http.Request 进行了进一步的封装。追踪源码，在 `gin.go` 中发现了相关处理:
```go
func (engine *Engine) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	c := engine.pool.Get().(*Context)
    c.writermem.reset(w)
    // 原封不动的赋值，后面直到调用了用户定义的处理方法，都没有再对 Request 作出改变。
	c.Request = req
	c.reset()
	engine.handleHTTPRequest(c)

	engine.pool.Put(c)
}
```
Request.Body 实现了 io.ReadCloser 接口。读取完毕之后可能会被关闭。再次读取可能会取不到预期的数据。那么是 Request.Body 被读取之后执行了 Close 方法么。
网上给出的解决这种 Request.Body 多次读的解决办法是取出来之后写回，如下:
```go
bodyBytes, _ := ioutil.ReadAll(c.Request.Body)
// body 回写
c.Request.Body.Close()
c.Request.Body = ioutil.NopCloser(bytes.NewBuffer(bodyBytes))
```
ioutil.NopCloser 方法返回的 io.ReadCloser 直接是将 Close 置空。其实现方法如下:
```go
type nopCloser struct {
	io.Reader
}

func (nopCloser) Close() error { return nil }

// NopCloser returns a ReadCloser with a no-op Close method wrapping
// the provided Reader r.
func NopCloser(r io.Reader) io.ReadCloser {
	return nopCloser{r}
}
```
那么是因为数据读取后执行了 Close 方法导致的吗，答案是否定的。因为按照上面的的方法重写了 Close 方法之后仍然存在无法二次读取的问题。那么引起无法二次读的问题根源还是在 io.Reader 接口的实现上。

## 坑3 不支持 SNI

其实 oss 文档里面明确提及了目前不支持 SNI 。但是潜意识里不认为大如阿里云出的产品不可能不支持这么基本的功能。这就是坑爹的，坑死人不偿命的开始。因为首先会认为是己方出现的问题。漫长的 debug 就此开始。

具体表现就是返回 203 错误码,返回的内容如下：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>CallbackFailed</Code>
  <Message>Error status : 502.</Message>
  <RequestId>5F194F19F0F97532323681E6</RequestId>
  <HostId>xxxx.oss-cn-shenzhen.aliyuncs.com</HostId>
</Error>
```
造成这个错误的原因很多，在确定回调地址能够被正常访问，而服务端一个 ip 同时支持了多个不同域名在 443 端口的 https 的访问，那么不用怀疑。就是 oss 回调请求不带 SNI 信息引起的 TLS 握手失败。此时你无法从网关请求日志中看到请求信息。只能利用网络抓包工具进行分析和追查。
解决方法也简单。
- 直接将回调地址改为 http ，由于签名验证的存在，安全性是可以得到保证的。
- 单独为回调开一个 ip 启用 https 也是可以的。ipv4 下公网 ip 的稀有和配置实施对现有架构的影响，会导致这种方式的实现成本偏高。

## FAQ
### 什么是SNI？
TLS 的设计使然，在握手阶段就需要服务器下发证书给客户端。此时当同一个ip和端口组上绑定了多个不同域名的 https，那么就需要确定到底将哪个证书下发给客户端。因为此时连接还没有建立，是没有办法通过 http header 中的 host信息确定需要使用额证书的。SNI 全称： Server Name Indication，它扩展了TLS协议。在 client hello 信息中明文带上 host 信息，服务端依照这个 host 选择证书以建立 TLS 连接。

服务端对SNI的支持一般都很好，不支持SNI的情况一般出现在一些古老的客户端。随着互联网的发展这一状况将会得到改善。

### TLS 和 SSL 的区别？
- SSL 由于诸多安全问题，现在已经基本被弃用。不建议服务器再支持 SSL 协议。
- TLS 在 SSL 3.0 的基础上开发出来。TLS 协议和 SSL 3.0 之间的差异并不明显，但是他们都非常重要且 TLS 1.0 和 SSL 3.0不具有互操作性。
- TLS 目前有 1.0、1.1、1.2、1.3 四个版本。1.2和1.3 是建议使用而且被普遍支持的版本。
### 如何知道客户端是否支持SNI？
- 用 tcpdump 抓取服务端https端口的流量，拿到本地 wireshhark 中进行查看，可以很容易知道 client hello 阶段是否发送 SNI 信息：
```shell
tcpdump -i eth0 -s 0 -w /var/tmp/xxx.cap port 443
```
如下图所示，没有 SNI 信息，说明客户端不支持 SNI。
![抓包信息示例](/images/sni.png "SNI 抓包图示")