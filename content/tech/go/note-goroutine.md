---
title: "GO笔记之并发"
date: 2020-05-12T14:54:24+08:00
draft: false
tags:
- go
- 笔记
---

### goroutine

`goroutine` 是 `go` 语言在语言层面对并发提供的支持。可以在单个进程里执行千万级的并发任务。

- 调度器不能保证多个`goroutine`的执行次序，且进程退出时不会等待`goroutine`结束。
- 默认情况下进程启动后紧允许一个系统线程服务于`goroutine`。可以使用环境变量或者`runtime.GOMAXPROCS`修改这个设定。
- 调用`runtime.Goexit`将立即终止当前`goroutine`执行，已注册的`defer`函数被确保执行。
- 调用`runtime.Gosched`暂停执行，让出底层线程。放回队列等待下次被调用。
### channel

go中提倡用通信共享数据，是`CSP`模型的具体实现。此外还有`Actor`模型还有`共享内存`模型。两者完全相反，`Actor`模型线程间没有数据共享。内存共享模型需要考虑各种死锁问题。

- 默认为同步模式，缓冲区为0，发送和接收端都就位后才可以继续执行。以下代码会报错:
```go
func main() {
	var x = make(chan int)
	x <- 3
	time.Sleep(5)
	fmt.Println(<-x)
}
```
改为下面的可以正常运行:
```go
func main() {
	var x = make(chan int)
	go func() {
		x <- 3
	}()
	go func() {
		fmt.Println(<-x)
	}()
	time.Sleep(5)
}
```
- 对于缓冲区不为`0`的`channel`，缓冲区满时发送阻塞，缓冲区为空时接收端阻塞。
- `range`和`ok-idiom`模式判断`channel`是否关闭。
- 向关闭的`chan`发送数据会引发`panic`,接收立即返回零值。 `nil` 通道无论接收还是发送都会被阻塞。
- 内置函数`len`返回未被读取的缓冲元素数量，`cap`返回缓冲区大小。
- 带缓冲区的`chan`具备更高的效率，但是应该考虑使用指针，避免大对象拷贝。尽量减小缓冲区大小。
- 可以将`chan`隐式转化为单向队列，只收或者只发。此转换不可逆。
```go
c := make(chan int, 3)
var send chan<- int = c 
var recv <-chan int = c
```

- channel状态与操作之间的关系:

|状态/操作|写操作|读操作|关闭操作|
|---|---|---|---|
|nil|写阻塞|写阻塞|产生panic|
|同步写阻塞|写阻塞|可读|产生panic|
|同步读阻塞|可写|读阻塞|可正常关闭|
|关闭|产生panic|立即返回零值（nil,false两个值）|产生panic|
|缓冲写阻塞|写阻塞|成功读取队列中数据|关闭成功，已写入数据可读|
|缓冲读阻塞|可写|读阻塞|可关闭|
|缓冲可读写|可写|可读|关闭成功，已写入数据可读|


### select
可以使用`select`语句在多个`channel`中选择一个做收发操作，或者执行`default case`。
- 在循环中使用 `default case` 需要注意。避免`default case`被大量执行,除非是业务预期。
- 用`select`实现超时:
```go
func main() {
	w := make(chan bool)
	c := make(chan int, 2)
	go func() {
		select {
		case v := <-c:
			fmt.Println(v)
		case <-time.After(time.Second * 3):
			fmt.Println("timeout.")
		}
		w <- true
	}()
	// c <- 1
	<-w
}
```