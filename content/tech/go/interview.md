---
title: "记录3个带坑的面试题"
date: 2020-09-16T15:46:34+08:00
draft: false
tags:
- go
- 面试
---

2020 年疫情加上国际国内经济环境的影响，明显感觉到职位竞争的惨烈。目前仍然在不断的自我提升和挑战中。也没有多少时间来写总结。这里先记录一下在某大公司遇到的 golang 面试题，因为看着很简单但是最终被吊打，所以记忆深刻。
## 题目
先贴题目出来，可以先看看如果你遇到这样的题目会怎么回答。又或者哪天你有幸遇到这个面试官，大概率会遇到这几个题目，我整个技术面都是围绕这几道题展开的。

### 第一题
有如下代码：
```go
package main

func main() {
	var arr = []int{1, 2, 3, 4, 5}
	for k, v := range arr {
		// 代码预留区
	}
}
```
问：v 的值是一个拷贝，那么可能存在两种拷贝方式。其一是对 arr 进行整体拷贝然后再对 arr 的副本进行遍历，其二是在遍历过程中对 arr 的元素进行拷贝。请在代码预留区写出代码以验证属于哪一种拷贝方式。

这个问题如果陷入定式思维很难想到方法。结果见文后。

### 第二题
有 n 级台阶，每次走一步或者两步。问共有几种方法可以走完这个台阶，请用 golang 写出计算代码。

这个问题接触过的应该觉得很简单，没有接触过的一定是陷入排列组合的死胡同。


### 第三题
有如下代码：
```go
package main

import "fmt"

func main() {
	for i := 0; i < 10; i++ {
		go func() {
			fmt.Println(i)
		}()
	}
}
```
问：根据协程调度特性判断程序大概会输出什么内容。

## 答案解析
### 第一题解析
关键点是要用 v 进行比较，但是另外一个比较因子在哪里呢。使用 uintptr 和 unsafe.Pointer 是否可以做一些事情？用闭包或者其他特性是否可以证明这个问题？如果你无法第一时间想到方法，那你一定会跟我一样陷入定式思维的泥沼。因为潜意识里会认为面试官应该在考察你什么高深的特性或者其他什么你不清楚的黑科技。事实上答案很简单，只需要在第一次迭代改变 arr 后续元素的值，看看输出是否符合预期即可。贴代码：
```go
func main() {
	var arr = []int{1, 2, 3, 4, 5}
	for k, v := range arr {
		// 代码预留区
		if k == 0 {
			arr[1] = 9
			arr[2] = 9
			arr[3] = 9
			arr[4] = 9
		}
		fmt.Printf("k:%d,v:%d\n", k, v)
	}
}
```
代码证明是拷贝 arr 的元素，不是拷贝整个 arr。

### 第二题解析
我第一个想法是先假设有 5 级台阶，然后我排出所有可能性，再找出其规律。然后就各种排列组合开始演算了……但是很难理清楚，陷入一个死循环。
真正的思路：假设走到第n级台阶用了 f(n) 种方法。

从 n-1 到第 n 级台阶有 f(n-1)+1种方法，只能走一步到头。

再往前推 n-2 级台阶到第 n 级台阶有 f(n-2)+3 种方法。因为每次最多可以走两步所以在第 n-2 级台阶到第 n 级台阶，要么一次两步走完，要么先一步走到第 n-1 级台阶再往上走。当先走到第 n-1 级台阶时 f(n-1) 包含了这种可能性。n-2 往前推任何一级都必定先到 n-1 或者 n-2 级台阶。所以只考虑 f(n) 和 f(n-1)、f(n-2) 之间的关系。就是 f(n)=f(n-1)+f(n-2)，至于为啥是这个等式我现在又迷糊了,说不清楚。这实际上就是斐波那契数的定义，其中 f(1)=1,f(2)=2是可以确定的。代码实现如下：
```go
func sum(n int) int {
	if n == 1 {
		return 1
	}
	if n == 2 {
		return 2
	}
	return sum(n-1) + sum(n-2)
}
```

### 第三题解析
这道题是个开放题。其中有几个坑点。
- 程序会直接退出，如果被题意扰乱很可能会忽略这个事实。此时可能会什么都没有输出，因为协程可能都没有得到调度执行，可能程序够快所以有协程得到执行那么会有输出，输出 0 到 10 之间的任意一个或者多个数。这是在多核运行的情况下，单核环境运行又是另外的情况。
- 假如 for 循环后加个阻塞，保证所有协程得到执行会输出什么呢？这里有几个坑：
1、闭包函数没有传入 i 的值（如果传入 i 的值那么在协程建立的时候就已经是进行了值拷贝传参，此时会打印 0-9 的数字各一次），所以函数被执行的时候 i 的值是多少就输出多少。
2、for 执行完毕的时候 i 的值是 10，而不是 9。
3、程序在单核环境中运行还是在多核机器中运行输出的结果也不一样。

程序在我 12 逻辑核心的 mac 上，这段代码会输出很多个 10 ，还有少量（1 到 2 个）的 1-9 之间的随机数。