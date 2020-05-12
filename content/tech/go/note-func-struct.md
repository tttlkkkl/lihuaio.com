---
title: "GO笔记之结构体、方法和接口"
date: 2020-05-12T11:52:41+08:00
draft: false
tags:
- go
- 笔记
---

### struct
- 可以定义指向自身的指针成员。
- 顺序初始化必须包含所有字段，并且顺序要和定义时一致。
- 标签是类型的组成部分。
- 匿名字段字段本质是和成员类型同名（不包括包名）的字段，被嵌入的字段可以是任何类型。
- 从外向内逐级查找所有层次的匿名字段直到发现目标或者出错。
- 同一层有相同字段时最好显示指定字段名，以免出现意外情况。
- 可以使用结构体的嵌套实现伪面向对象。

### 方法
⽅方法总是绑定对象实例，并隐式将实例作为第⼀一实参 (receiver)。


- 只能为当前包内命名类型定义⽅方法。
- 参数 `receiver` 可任意命名。如⽅方法中未曾使⽤用，可省略参数名。
- 参数 `receiver` 类型可以是 T 或 *T。基类型 T 不能是接⼝口或指针。
- 不⽀支持⽅方法重载，`receiver` 只是参数签名的组成部分。
- 可⽤用实例 `value` 或 `pointer` 调⽤用全部⽅方法，编译器⾃自动转换。
- 通过匿名字段，可获得和继承类似的复⽤用能⼒力。依据编译器查找次序，只需在外层定义同 名⽅方法，就可以实现 "override"。

#### 方法集

- 类型 `T` ⽅方法集包含全部 `receiver T` ⽅方法。
- 类型 `*T` ⽅方法集包含全部 `receiver T + *T` ⽅方法。
- 如类型 `S` 包含匿名字段 `T`，则 `S` ⽅方法集包含 `T` ⽅方法。 
- 如类型 `S` 包含匿名字段 `*T`，则 `S` ⽅方法集包含 `T + *T` ⽅方法。 
- 不管嵌⼊入 `T` 或 `*T`，`*S` ⽅方法集总是包含 `T + *T` ⽅方法。
- ⽤用实例 `value` 和 `pointer` 调⽤用⽅方法 (含匿名字段) 不受⽅方法集约束，编译器总是查找全部 ⽅方法，并⾃自动转换 `receiver` 实参。

#### 表达式
根据调⽤用者不同，⽅方法分为两种表现形式:
```
instance.method(args...) ---> <type>.func(instance, args...)
```
前者称为 `method value`，隐式传递极受着。后者 `method expression`，显示传递接收者。

```go
type Data struct{}

func (Data) TestValue()    {}
func (*Data) TestPointer() {}
func main() {
	var p *Data = nil
	p.TestPointer()

	(*Data)(nil).TestPointer() // method value
	(*Data).TestPointer(nil)   // method expression

	// p.TestValue() // invalid memory address or nil pointer dereference
	// (Data)(nil).TestValue() // cannot convert nil to type Data
	// Data.TestValue(nil) // cannot use nil as type Data in function argument
}
```

### interface

接口是方法签名的集合，任何包含接口定义的所有方法集的类型都实现了接口。包含的方法指具有相同名称、参数列表以及返回值。不需要有相同的参数名。

- 接⼝口命名习惯以 er 结尾。
- 接口定义方法签名。
- 接口没有数据字段。
- 接口跟结构体一样也可以嵌套。
- 一个类型可以实现多个接口。
- 空接口`interface{}`没有任何方法签名，任何方法都实现了空接口。可用于不确定类型的参数或变量。
- 匿名接口可以用作变量类型或结构体成员。

接口类型断言:
```go
	var o interface{} = &User{1, "Tom"}
	if i, ok := o.(fmt.Stringer); ok {
		fmt.Println(i,ok)
	}
}
```
- 用`switch`做批量类型断言时不支持`fallthrough`关键字。
- 超级接口对象可转换为子集接口，反之出错。

- 可以让编译器帮助检查，确保某个类型实现接口:
```go
var _ fmt.Stringer = (*Data)(nil)
```
- 让函数直接实现接口:
```go
type Tester interface {
	Do()
}
type FuncDo func()

func (f FuncDo) Do() { f() }
func main() {
	var t Tester = FuncDo(func() { println("Hello, World!") })
	t.Do()
}
```