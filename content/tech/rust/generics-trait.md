---
title: "泛型、rait和生命周期"
date: 2021-05-25T21:51:02+08:00
draft: false
tags:
- rust
- 笔记
---
利用范型和rait提取重复代码进行封装，以使代码更加简洁。
- 一般的使用 `type` 的简写 `T` 来代表泛型类型。
```rust
// 函数 largest 有泛型类型 T。它有个参数 list，其类型是元素为 T 的 slice。
// largest 函数的返回值类型也是 T。
fn largest<T>(list: &[T]) -> T {
}
```
### 结构体泛型
```rust
// 这表明结构体中的 x y 都是同一个类型
struct Point<T> {
    x: T,
    y: T,
}
let integer = Point { x: 5, y: 10 };
let float = Point { x: 1.0, y: 4.0 };
// x y 类型不同的定义
struct Point<T, U> {
    x: T,
    y: U,
}
```
### 枚举范型
```rust
enum Option<T> {
    Some(T),
    None,
}
enum Result<T, E> {
    Ok(T),
    Err(E),
}
```
### 方法泛型
```rust
// 泛型的结构体
struct Point<T> {
    x: T,
    y: T,
}
// 泛型结构体上定义 x 方法。返回结构体的 x
impl<T> Point<T> {
    fn x(&self) -> &T {
        &self.x
    }
}
```
- 在 impl 后面声明 T，这样就可以在 Point<T> 上实现的方法中使用它。如以下为`Point<f32>`实例创建一个方法，而不是`Point<T>`:
```rust
impl Point<f32> {
    fn distance_from_origin(&self) -> f32 {
        (self.x.powi(2) + self.y.powi(2)).sqrt()
    }
}
```
### 泛型的性能
- 泛型的性能和使用具体类型相比没有任何损失。
- Rust 通过在编译时进行泛型代码的 单态化（monomorphization）来保证效率。
- 单态化是一个通过填充编译时使用的具体类型，将通用代码转换为特定代码的过程。
- 编译器寻找所有泛型代码被调用的位置并使用泛型代码针对具体类型生成代码。

## trait 定义共享的行为
- trait 类似其他语言的接口 interface。
- trait 定义是一种将方法签名组合起来的方法，目的是定义一个实现某些目的所必需的行为的集合。
- trait 体中可以有多个方法：一行一个方法签名且都以分号结尾。
```rust
// 定义一个 trait
pub trait Summary {
    fn summarize(&self) -> String;
}
// 为结构体类型实现一个 trait
pub struct NewsArticle {
}
impl Summary for NewsArticle {
    fn summarize(&self) -> String {
    }
}
```
- 带有默认实现的 trait，可以在其他类型具体实现中被重载：
```rust
pub trait Summary {
    fn summarize(&self) -> String {
        String::from("(Read more...)")
    }
}
// 一个空的 impl 可以使类型使用 trait 的默认行为
impl Summary for NewsArticle {}
```
- 默认实现允许调用相同 trait 中的其他方法，哪怕这些方法没有默认实现。
```rust
pub trait Summary {
    fn summarize_author(&self) -> String;

    fn summarize(&self) -> String {
        format!("(Read more from {}...)", self.summarize_author())
        //调用未定义的 summarize_author() 方法
        // 一旦实现了 summarize_author() 就可以调用 summarize() 方法
    }
}
```
### trait 作为参数
```rust
// 不指定特定类型，只要实现了 Summary Trait 的类型都可以作为本方法的参数
pub fn notify(item: impl Summary) {
    println!("Breaking news! {}", item.summarize());
}
```
### Trait Bound 语法
- 适用于需要接收很多个 Trait 的情况。
```rust
pub fn notify(item1: impl Summary, item2: impl Summary) {}
// 等同
pub fn notify<T: Summary>(item1: T, item2: T) {}//强制接收多个相同的 Trait 
```
### 通过 + 指定多个 trait bound
```rust
pub fn notify(item: impl Summary + Display) {}
//等同
pub fn notify<T: Summary + Display>(item: T) {}
```
### 通过 where 简化 trait bound
```rust
fn some_function<T: Display + Clone, U: Clone + Debug>(t: T, u: U) -> i32 {}
//等同
fn some_function<T, U>(t: T, u: U) -> i32
    where T: Display + Clone,
          U: Clone + Debug
{}
```
### 返回实现了 trait 的类型
```rust
// 调用方只知道返回了实现了 Trait 的类型但是不知道返回的是 Tweet
fn returns_summarizable() -> impl Summary {
    Tweet {
    }
}
```

## 生命周期与引用有效性
- 生命周期的主要目标是避免悬垂引用，它会导致程序引用了非预期引用的数据。
```rust
{
    let r;
    {
        let x = 5;
        r = &x;//无法编译通过，因为离开作用域后 x 将不在有效
    }
    println!("r: {}", r);
}
```
- 生命周期可以理解为作用域存在的有效时间。