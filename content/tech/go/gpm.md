---
title: "GO的调度"
date: 2020-05-28T10:39:48+08:00
draft: false
tags:
- go
- 笔记
---

先从一个代码开始:
```go
func main() {
	var x int
	threads := runtime.GOMAXPROCS(0)
	fmt.Println(threads)
	for i := 0; i < threads; i++ {
		go func() {
			for {
				x++
			}
		}()
	}
	time.Sleep(time.Second)
	fmt.Println("x =", x)
}
```
这个代码启动了逻辑核心个数的无法自行退出的协程，结果是程序卡住不会打印`x`的值。按照常识如果 main 函数中没有做阻塞操作那么应该是 1 秒后程序退出，同时也关闭所启动的协程。
代码用例来自[《深度解密Go语言之 scheduler》](https://juejin.im/post/5d6cfa13518825267a75685e)写的很棒，推荐一读。当然更详细深入的文章还有[《深入golang runtime的调度》](https://zboya.github.io/post/go_scheduler/)。

看过以上两篇文章一定可以理解以上代码为何没有按照预期的运行，结合着两篇文章还有 GO 的源码，越看越懵逼，越看越多。等后续腾出时间复习一下汇编再试着阅读相关源码吧，届时再试着完善本文。正如 《深入golang runtime的调度》 中所言:
> 很多gopher懂GPM，更多gopher不懂GPM！