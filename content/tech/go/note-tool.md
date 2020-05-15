---
title: "GO笔记之工具"
date: 2020-05-14T17:09:51+08:00
draft: false
tags:
- go
- 笔记
---

本文内容直接摘抄自雨痕大牛的《Go 学习笔记》 方便查用。[github 地址](https://github.com/qyuhen/book)。

## 工具集
### go build
|参数|说明|⽰示例|
|---|---|---|
|-gcflags|传递给 5g/6g/8g 编译器的参数。| (5:arm, 6:x86-64, 8:x86) |
|-ldflags|传递给 5l/6l/8l 链接器的参数。||
|-work|查看编译临时目录。||
|-race|允许数据竞争检测 (仅⽀支持 amd64)。||
|-n|查看但不执行编译命令。||
|-x | 查看并执行编译命令。||
|-a|强制重新编译所有依赖包。||
|-v | 查看被编译的包名，包括依赖包。||
|-p n|并⾏行编译所使⽤用 CPU core 数量。默认全部。||
|-o|输出⽂文件名。||

#### gcflags
|参数|说明|示例|
|---|---|---|
|-B|禁用边界检查||
|-N|禁用优化||
|-l|禁用函数内联||
|-u|禁⽤ unsafe 代码||
|-m|输出优化信息||
|-S|输出汇编代码||

#### ldflags
|参数|说明|示例|
|---|---|---|
|-w|禁⽤ DRAWF 调试信息，但不包括符号表。||
|-s|禁用符号表。||
|-X|修改字符串符号值。|-X main.VER '0.99' -X main.S 'abc'|
|-H|链接⽂件类型，其中包括 windowsgui。|cmd/ld/doc.go|

更多参数:
```bash
go tool 6g -h 或 https://golang.org/cmd/gc/
go tool 6l -h 或 https://golang.org/cmd/ld/
```

### go install

和`go build`参数相同，将生成的文件拷贝到`bin`、`pkg`目录。优先使⽤ `GOBIN` 环境变量所指定目录。

### go clean

|参数|说明|示例|
|---|---|---|
|-n|查看但不执⾏清理命令。||
|-x|查看并执行清理命令。||
|-i|删除 bin、pkg 目录下的⼆进制⽂件||
|-r|清理所有依赖包临时文件。||

### go get

|参数|说明|示例|
|---|---|---|
|-d|仅下载，不执⾏安装命令。||
|-t|下载测试所需的依赖包。||
|-u|更新包，包括其依赖包。||
|-v|查看并执⾏命令。||

## 条件编译

通过 `runtime.GOOS/GOARCH` 判断，或使⽤用编译约束标记。

```go
// +build darwin linux
// 本行必须是空行
 package main
```
使用`-tags`参数来定义约束条件。如：
```bash
go build -tags=jsoniter
```
设定 `GOOS`、`GOARCH` 环境变量即可编译目标平台⽂件。如：
```bash
GOOS=linux GOARCH=amd64 go build -o test
```

## 预处理

`go generate` 扫描源代码文件，找出所有`//go:generate`注释，提取执行预处理命令。

- 命令必须放在`.go`文件。
- 每个文件可以包含多个 `generate` 文件。
- 命令行支持环境变量。
- 按文件名顺序依次提取执行。出错终止。
- 必须以 `//go:generate` 开头，双斜杠后没有空格。

|参数|说明|示例|
|---|---|---|
|-x|显示并且执行命令。||
|-n|显示但不执行命令。||
|-v|输出处理的包和源文件。||

可定义别名。须提前定义，仅在当前⽂件内有效:
```bash
 //go:generate -command YACC go tool yacc
 //go:generate YACC -o test.go -p parse test.y
```

## 调试

### GDB

默认情况下`GDB 7.1`以上版本都可以对编译后的二进制文件进行调试。

相关选项:
- 调试：禁用内联和优化：`-gcflags "-N -l"`。
- 发布：删除调试信息和符号表：`-ldflags "-w -s"`

除了使用`GDB`的断点命令外，还可以使用`runtime.Breakpoint`函数触发中断。

使用`runtime/debug.PrintStack`可用来输出调用栈信息。

某些情况下需要人工载入`runtime.gdb.py`。

.gdbinit:
```py
define goruntime
source /usr/local/go/src/runtime/runtime-gdb.py
end
set disassembly-flavor intel
set print pretty on
dir /usr/local/go/src/pkg/runtime
```

OSX 环境下，可能需要以 sudo ⽅方式启动 gdb。

### Data Race

可以开启数据竞争检测，以帮助在开发时发现数据竞争问题，它会记录和监测运行时内存访问状态，发出非同步访问警告信息。此功能严重影响性能不可以在生产环境中使用。通常作为非性能测试项启用:
```bash
go test -race
```

数据竞争检测的一个示例：
```go
import "sync"

func main() {
	var wg sync.WaitGroup
	wg.Add(2)
	x := 100
	go func() {
		defer wg.Done()
		for {
			x += 1
		}
	}()
	go func() {
		defer wg.Done()
		for {
			x += 100
		}
	}()
	wg.Wait()
}
```
```bash
go run -race main.go
```
输出:
```bash
==================
WARNING: DATA RACE
Read at 0x00c00009c010 by goroutine 7:
  main.main.func2()
      /Users/m/work/lihua/go-study/ss/main.go:18 +0x6c

Previous write at 0x00c00009c010 by goroutine 6:
  main.main.func1()
      /Users/m/work/lihua/go-study/ss/main.go:12 +0x82

Goroutine 7 (running) created at:
  main.main()
      /Users/m/work/lihua/go-study/ss/main.go:15 +0x102

Goroutine 6 (running) created at:
  main.main()
      /Users/m/work/lihua/go-study/ss/main.go:9 +0xd6
==================
```

## 测试

- 测试代码必须保存在 `*_test.go` ⽂文件。
- 测试函数命名符合 TestName 格式，Name 以⼤写字母开头。

### Test

使⽤ `testing.T` 相关方法决定测试状态。

|方法|说明|其他|
|---|---|---|
|Fail|标记失败，但继续执行该测试函数。||
|FailNow|失败，立即停止当前测试函数||
|Log|输出信息，在失败或者传入`-v`参数时|Logf|
|SkipNow|跳过当前测试函数|Skipf=SkipNow+Logf|
|Error|Fail+Log|Errorf|
|Fatal|FailNow+Log|Fatalf|

`go test`默认执行所有单元测试函数，支持`go build`参数。

|参数|说明|示例|
|---|---|---|
|-c|仅编译，不执行测试||
|-v|显示所有测试函数执行细节||
|-run regex|执行指定的测试函数（正则表达式）。||
|-parallel n|并发执行测试函数，默认 GOMAXPROCS||
|-timeout t|单个测试超时时间。|-timeout 2m30s|

可重写 `TestMain` 函数，处理⼀一些 `setup/teardown` 操作：
```go
import (
	"os"
	"testing"
)

func TestMain(m *testing.M) {

	println("setup")
	code := m.Run()
	println("teardown")
	os.Exit(code)
}
func TestA(t *testing.T) {}
func TestB(t *testing.T) {}
```

### Benchmark
性能测试需要运行足够次数才能计算单次执行平均时间。

默认情况下，`go test`不会执行性能测试函数，须使用`-bench`参数。

|参数|说明|示例|
|---|---|---|
|-bench regex|执⾏指定性能测试函数。(正则表达式)||
|-benchmem|输出内存统计信息。||
|-benchtime t|设置每个性能测试运⾏行时间。|-benchtime 1m30s|
|-cpu|设置并发测试。默认 `GOMAXPROCS`。|-cpu 1,2,4|

### Example

- 与 `testing.T` 类似，区别在于通过捕获 `stdout` 输出来判断测试结果。
- 不能使⽤内置函数 `print/println`，它们默认输出到 `stderr`。
- `Example` 代码可输出到⽂档。

### Cover

除显⽰代码覆盖率百分比外，还可输出详细分析记录文件。
|参数|说明|
|---|---|
|-cover|允许覆盖分析|
|-covermode|代码分析模式。 (set: 是否执⾏; count: 执⾏次数; atomic: 次数, 并发⽀持)|
|-coverprofile|输出结果⽂件。|

⽤浏览器输出结果，能查看更详细直观的信息。包括⽤不同颜⾊标记覆盖、运⾏次数等。

```bash
go tool cover -html=cover.out
```

### PProf

监控程序执行，找出性能破瓶颈。关于`PProf`的用法后续再行深入研讨。
除调⽤ `runtime/pprof` 相关函数外，还可直接⽤测试命令输出所需记录文件。
`go test`：
|参数|说明|
|---|---|
|-blockprofile block.out|goroutine 阻塞。|
|-blockprofilerate n|超出该参数设置时间的阻塞才被记录。单位:纳秒|
|-cpuprofile cpu.out|CPU。|
|-memprofile mem.out|内存分配。|
|-memprofilerate n|超出该参数 (bytes) 设置的内存分配才被记录。默认 512KB (mprof.go)|

以 net/http 包为⽰示，先生成记录⽂文件。
```bash
go test -v -test.bench "." -cpuprofile cpu.out -memprofile mem.out net/http
```
进入交互查看模式：
```bash
go tool pprof http.test mem.out
```

- flat: 仅当前函数，不包括其调⽤的其他函数。
- sum: 列表前⼏行所占百分⽐总和。
- cum: 当前函数完整调用堆栈。

默认输出 inuse_space，可在命令⾏指定其他值，包括排序方式。
```bash
go tool pprof -alloc_space -cum http.test mem.out
```
可输出函数调⽤的列表统计信息(交互模式)。
```bash
(pprof) peek parseCertificate
```
或者是更详细的源码模式。
```bash
(pprof) list parseCertificate
```
除交互模式外，还可直接输出统计结果。
```bash
go tool pprof -text http.test mem.out
```
输出图形⽂件。
```bash
go tool pprof -web http.test mem.out
```
还可⽤ `net/http/pprof` 实时查看 `runtime profiling` 信息。
```go
import (
	"net/http"
	_ "net/http/pprof"
	"time"
)

func main() {
	go http.ListenAndServe("localhost:6060", nil)
	for {
		time.Sleep(time.Second)
	}
}

```
浏览器访问地址:
http://localhost:6060/debug/pprof/

***附: ⾃定义统计数据，可用 `expvar` 导出，用浏览器访问 /debug/vars 查看。***