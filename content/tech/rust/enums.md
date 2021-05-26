---
title: "rust 枚举和模式匹配"
date: 2021-05-20T15:04:21+08:00
draft: false
tags:
- rust
- 笔记
---
- 枚举通过列举可能的 成员（variants） 来定义一个类型。
- 枚举用 enum 关键字定义。如：
```rust
enum IpAddrKind {
    V4,
    V6,
}
// 绑定数据类的枚举
enum IpAddr {
    V4(String),
    V6(String),
}
let home = IpAddr::V4(String::from("127.0.0.1"));
let loopback = IpAddr::V6(String::from("::1"));
```
- 枚举类型可以包含任何数据类型，包括枚举类型。
```rust
enum Message {
    Quit,//没有关联任何数据
    Move { x: i32, y: i32 },// 包含一个匿名结构体
    Write(String),// 包含一个 String
    ChangeColor(i32, i32, i32),// 包含3个i32
}
// 和定义结构体的对比
struct QuitMessage; // 类单元结构体
struct MoveMessage {
    x: i32,
    y: i32,
}
struct WriteMessage(String); // 元组结构体
struct ChangeColorMessage(i32, i32, i32); // 元组结构体
```
- 定义有多个关联值的枚举和定义多个不同类型的结构体相像。
- 枚举也可以使用`impl`关键字定义方法。

## Option 枚举
- rust 没有空值的概念，通过 Option 枚举来表示有和没有的概念。如下：
```rust
enum Option<T> {
    Some(T),
    None,
}
```
- rust 默认不会产生空值，如果要使用一个空值必须显示的定义为一个 `Option<T>` 类型,并进行处理。

## match 控制流运算符
```rust
enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter,
}

fn value_in_cents(coin: Coin) -> u8 {
    match coin {
        Coin::Penny =>  {
            println!("Lucky penny!");
            1
        },
        Coin::Nickel => 5,
        Coin::Dime => 10,
        Coin::Quarter => 25,
    }
}
```
- 顺序执行匹配模式，匹配成功后执行关联的代码，否则尝试继续匹配下一个分支。
- 匹配成功后不会继续执行下一个分支。
### 匹配 Option<T>
- 取一个 Option<i32> ，如果其中含有一个值，将其加一。如果其中没有值，函数应该返回 None 值，而不尝试执行任何操作。
```rust
fn plus_one(x: Option<i32>) -> Option<i32> {
    match x {
        None => None,
        Some(i) => Some(i + 1),
    }
}

let five = Some(5);
let six = plus_one(five);// 返回 Some(6)
let none = plus_one(None);// 没有任何操作
```
- 匹配是穷尽的，也即匹配必须处理所有可能出现的情况，否则无法编译通过。
- 通过通配符`_`(可以匹配所有的值)可以忽略不关心的可能的匹配情况。如下：
```rust
let some_u8_value = 0u8;
match some_u8_value {
    1 => println!("one"),
    3 => println!("three"),
    5 => println!("five"),
    7 => println!("seven"),
    _ => (),//以上的值未匹配将不做任何处理
}
```
## if let 简单控制流
- 等同于 match 匹配一个模式而忽略其他情况的情形。
```rust
let some_u8_value = Some(0u8);
match some_u8_value {
    Some(3) => println!("three"),
    _ => (),
}
// 等同于
if let Some(3) = some_u8_value {
    println!("three");
} else { // 等同于 match 里面的 _ => ()
    // todo
}
```