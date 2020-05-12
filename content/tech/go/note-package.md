---
title: "GO笔记之包"
date: 2020-05-12T17:03:17+08:00
draft: false
tags:
- go
- 笔记
---

- 源码文件必须是`utf-8`格式。命名采用驼峰法，不建议使用下划线。`test`文件例外？
- 源文件头部以`package <name>`声明包名称。
- 包名类似命名空间，与包所在目录名称，源文件名无关。
- 目录名不建议使用`main`、`all`、`std`这三个保留名称。
- 可执行文件必须包含`main`包和`func main(){}`。
- 获取可执行文件路径:
```go
func main() {
	p, _ := exec.LookPath(os.Args[0])
	x, _ := filepath.Abs(p)
	fmt.Println(x)
}
```
### 包的导入

- 必须使用`import`导入包才可以被使用，不能循环导入。
```go
import(
    "x/xx" //默认模式 xx.A 访问
    r "x/xx" // 包重命名 r.A
    . "x/xx" // 简便模式 A
    _ "x/xx" //非导入模式紧让该包执行初始化函数
)
```
个人不推荐使用简便模式导入包，因为和当前包存在相同成员的时候可能会有歧义和其他不便之处：
```go
import (
	. "fmt"
)

func main() {
	Printf("%s", "xxx")
}

func Printf(s string, p ...interface{}) {
	print("ccccc")
}
```
实际上是 `fmt` 包中的方法首先被调用。
### 初始化函数
- 每个源文件中可以定义一个或者多个源文件。
- `init(){}`初始化函数的调用次序是未知的，全局变量应该直接使用`var`初始化。
- 初始化函数在单一线程被调用，只执行一次。
- 初始化函数在包所有全局变量初始化后执行。
- 所有初始化函数执行完毕之后才会调用`main`函数。
- 初始化函数无法被调用。

### doc
扩展工具`godoc`能自动提取注释生成帮助文档。
- 仅和成员相邻 (中间没有空⾏) 的注释被当做帮助信息。
- 相邻⾏会并成同⼀一段落，⽤空⾏分隔段落。
- 缩进表⽰格式化⽂本，⽐比如⽰例代码。
- ⾃动转换 `URL` 为链接。
- ⾃动合并多个源码⽂件中的 `package` ⽂档。
- ⽆法显式 `package main` 中的成员文档。
- 建议⽤用专⻔的 `doc.go` 保存 `package` 帮助信息。
- 包⽂档第⼀一整句 (中英⽂句号结束) 被当做 `packages` 列表说明。
- ⾮测试源码⽂件中以 `BUG(author)` 开始的注释，会在帮助文档 `Bugs` 节点中显示。
- 以`Example`或`Example_`开头的方法会被当成示例函数。
- 使⽤用 `suffix` 作为⽰例名称，其⾸字母必须小写。
- 文件中仅有一个`Example`函数，并且调用了该文件其他成员，那么示例会显示整个文件内容。