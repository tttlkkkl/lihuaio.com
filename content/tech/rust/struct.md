---
title: "rust 结构体"
date: 2021-05-20T10:00:30+08:00
draft: false
tags:
- rust
- 笔记
---

结构体同元组一样都可以包含不同类型的元素，区别在于结构体元素有明确的命名无需通过索引访问，无需关心元素顺序，更加灵活。
```rust
// 结构体定义
struct User {
    username: String,
    email: String,
    sign_in_count: u64,
    active: bool,
}
// 结构体实例化
let user1 = User {
    email: String::from("someone@example.com"),
    username: String::from("someusername123"),
    active: true,
    sign_in_count: 1,
};
// 初始化结构体的简洁写法
fn build_user(email: String, username: String) -> User {
    User {
        email,
        username,
        active: true,
        sign_in_count: 1,
    }
}
// 更新创建，创建 user2 其余值来自 user1
let user2 = User {
    email: String::from("another@example.com"),
    username: String::from("anotherusername567"),
    ..user1
};
// 元素访问
let x=user1.email;
```
- 要更改结构体实例字段，结构体变脸必须是可变的。

## 元组结构体
- 由 `struct` 关键字定义，但是只指定了字段的类型，没有指定字段名称。
- 以下 black，origin 都类似包含 3 个 i32 元素的元组，但不是一样的类型。其他基本和元组一样。
```rust
struct Color(i32, i32, i32);
struct Point(i32, i32, i32);

let black = Color(0, 0, 0);
let origin = Point(0, 0, 0);
```
## 类单元结构体
- 一个没有任何字段的结构体。
- 类似于 ()，即 unit 类型。
- 类单元结构体常常在你想要在某个类型上实现 trait 但不需要在类型中存储数据的时候发挥作用。

## 结构体数据的所有权
- 结构体元素如果没有所有权而是使用了引用，必须指定引用的生命周期，以确保元素字段在结构体变量有效时保持有效。
```rust
#[derive(Debug)] // debug 注解
struct Rectangle {
    width: u32,
    height: u32,
}

fn main() {
    let rect1 = Rectangle { width: 30, height: 50 };
    // {} 默认的 Display 输出 {:?} 格式化输出 {:#?} 展开的格式化输出
    println!("rect1 is {:?}", rect1);
}
```
## 方法
- 和一般函数一样，只是绑定到`struct`上面，需要通过结构体实例调用。
- 第一个函数参数总是 `self` 表示结构体自身。
- 用关键字 `impl` 在一个块中定义结构体方法。`impl` 块可以有多个。
```rust
impl Rectangle {
    fn area(&self) -> u32 {
        self.width * self.height
    }

    fn can_hold(&self, other: &Rectangle) -> bool {
        self.width > other.width && self.height > other.height
    }
}
```
## 关联函数
- 在 `impl` 块中定义不以 `self` 作为参数的函数称为结构体的关联函数，这仍然是函数，而不是函数。
- 使用`::`调用关联函数，如 `String::from`。关联函数用结构体名称调用，无需使用实例。