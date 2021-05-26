---
title: "rust 所有权"
date: 2021-05-15T17:35:57+08:00
draft: false
tags:
- rust
- 笔记
---
- 区别于自行管理内存的以及自带GC的语言。rust 通过管理权管理堆内存。
## 所有权规则
- 每一个值都有一个被称为所有者（owner）的变量。
- 值在任何时刻都只有一个所有者。
- 当所有者（变量）离开作用域，这个值将会被丢弃。
## 变量作用域
- 作用域是一项 item 在程序中的有效范围。全局作用域以及`{}`内的作用域。
- 离开作用域时 `rust` , 自动调用 `drop` 函数。
## 移动
- 栈上不可变变量的拷贝直接拷贝值(移动)。
- 非字面量字符串的拷贝，拷贝的是 `String` 的头信息，即存储字符串实际内存指针、长度、和容量信息的数据，并不是拷贝实际的堆上字符串数据。
- `移动`：为避免二次释放当堆上引用数据被拷贝赋值后原值将会无效，如下：
```rust
let s1 = String::from("hello");
let s2 = s1;// 赋值后，s1 将会失效。

println!("{}, world!", s1);//此语句将会编译报错
```
- Rust 永远也不会自动创建数据的 “深拷贝”。因此，任何 自动 的复制可以被认为对运行时性能影响较小。
## 克隆 
- 与移动相反，克隆会实际拷贝堆上数据。
```rust
let s1 = String::from("hello");
let s2 = s1.clone();//直接拷贝值

println!("s1 = {}, s2 = {}", s1, s2);//语句正常编译运行，因为进行了克隆操作，s1 没有失效
```
- 一个类型（栈上数据）被 `Copy trait` 注解，一个旧的变量在将其赋值给其他变量后仍然可用。
- Rust 不允许自身或其任何部分实现了 `Drop trait` 的类型使用 `Copy trait`。
- 任何简单标量值的组合可以是 `Copy` 的，不需要分配内存或某种形式资源的类型是 `Copy` 的,如下:
- - 所有整数类型，比如 u32。
- - 布尔类型，bool，它的值是 true 和 false。
- - 所有浮点数类型，比如 f64。
- - 字符类型，char。
- - 元组，当且仅当其包含的类型也都是 Copy 的时候。比如，(i32, i32) 是 Copy 的，但 (i32, String) 就不是。
## 所有权和函数
- 将值传递给函数在语义上与给变量赋值相似。向函数传递值可能会移动或者复制。
- 变量进入和离开作用域的示例：
```rust
fn main() {
    let s = String::from("hello");  // s 进入作用域

    takes_ownership(s);             // s 的值移动到函数里 ...
                                    // ... 所以到这里不再有效

    let x = 5;                      // x 进入作用域

    makes_copy(x);                  // x 应该移动函数里，
                                    // 但 i32 是 Copy 的，所以在后面可继续使用 x

} // 这里, x 先移出了作用域，然后是 s。但因为 s 的值已被移走，
  // 所以不会有特殊操作

fn takes_ownership(some_string: String) { // some_string 进入作用域
    println!("{}", some_string);
} // 这里，some_string 移出作用域并调用 `drop` 方法。占用的内存被释放

fn makes_copy(some_integer: i32) { // some_integer 进入作用域
    println!("{}", some_integer);
} // 这里，some_integer 移出作用域。不会有特殊操作
```
## 返回值和作用域
- 演示返回值转移所有权：
```rust
fn main() {
    let s1 = gives_ownership();         // gives_ownership 将返回值
                                        // 移给 s1

    let s2 = String::from("hello");     // s2 进入作用域

    let s3 = takes_and_gives_back(s2);  // s2 被移动到
                                        // takes_and_gives_back 中,
                                        // 它也将返回值移给 s3
} // 这里, s3 移出作用域并被丢弃。s2 也移出作用域，但已被移走，
  // 所以什么也不会发生。s1 移出作用域并被丢弃

fn gives_ownership() -> String {             // gives_ownership 将返回值移动给
                                             // 调用它的函数

    let some_string = String::from("hello"); // some_string 进入作用域.

    some_string                              // 返回 some_string 并移出给调用的函数
}

// takes_and_gives_back 将传入字符串并返回该值
fn takes_and_gives_back(a_string: String) -> String { // a_string 进入作用域

    a_string  // 返回 a_string 并移出给调用的函数
}
```
- 将值(非copy变量值)赋给另一个变量时移动它。
- 当持有堆中数据值的变量离开作用域时，其值将通过 drop 被清理掉，除非数据被移动为另一个变量所有。
## 引用与借用
- 引用：以变量的引用进行赋值或者传参不会转移变量的所有权。
```rust
// 直接传参会发生所有权转移
fn main() {
    let s1 = String::from("hello");

    let (s2, len) = calculate_length(s1);

    println!("The length of '{}' is {}.", s2, len);
}

fn calculate_length(s: String) -> (String, usize) {
    let length = s.len(); // len() 返回字符串的长度
    // 为了在外部继续使用字符串，返回字符串，将所有权转交回去
    (s, length)
}
// 使用引用传参，不转移s1的所有权，以继续使用s1。
fn main() {
    let s1 = String::from("hello");

    let len = calculate_length(&s1);

    println!("The length of '{}' is {}.", s1, len);
}

fn calculate_length(s: &String) -> usize {// s 是对 String 的引用
    s.len()
}// 这里，s 离开了作用域。但因为它并不拥有引用值的所有权，所以什么也不会发生
```
- 使用 `&` 引用相反的操作是 解引用`（dereferencing）`，它使用解引用运算符，`*`。
- 获取引用作为函数参数称为`借用`。
```rust
fn main() {
    let s = String::from("hello");

    change(&s);
}

fn change(some_string: &String) {
    some_string.push_str(", world");//没有所有权，无法修改
}
```
- 要修改引用变量必须用`mut`关键字定义变量可变并且定义引用可变：
```rust
fn main() {
    let mut s = String::from("hello");

    change(&mut s);
}

fn change(some_string: &mut String) {
    some_string.push_str(", world");//可实际更改字符串 s 的值
}
```
- 在特定作用域中的特定数据只能有一个可变引用。这个主要是为了在编译期就避免数据竞争的出现。
```rust
let mut s = String::from("hello");

let r1 = &mut s;
let r2 = &mut s;//错误

println!("{}, {}", r1, r2);
```
- 同样，也不能在拥有不可变引用的同时拥有可变引用。避免不可变引用受到可变引用的未知影响。
- 一个引用的作用域从声明的地方开始一直持续到最后一次使用为止。
```rust
let mut s = String::from("hello");

let r1 = &s;
let r2 = &s;
let r3 = &mut s; // 出错，不允许不可变引用和可变引用同时出现在同一个特定作用域

println!("{}, {}, and {}", r1, r2, r3);
//----
let mut s = String::from("hello");

let r1 = &s;
let r2 = &s;
println!("{} and {}", r1, r2);
// 此位置之后 r1 和 r2 不再使用

let r3 = &mut s; // 上面不可变引用作用域已结束，所以这里不是合法的
println!("{}", r3);
```
## 悬垂引用
- 指针的内存被释放，但是指针还存在的情况。
```rust
fn main() {
    let reference_to_nothing = dangle();
}

fn dangle() -> &String {// 返回一个字符串引用
    let s = String::from("hello");
    &s
}//离开作用域后字符串被释放，产生一个悬垂指针，将会产生编译错误。
```
- 同时只能存在一个可变引用或者同时只能存在多个不可变引用。
- 引用必须总是有效的。

## slice
- 引用一个集合中的一段连续序列。如`[0..5]`引用开始到第6个元素，等同于`[..5]`,同样`[1..]`引用第二到结尾，`[..]`引用整个字符串。
- 字符串字面值本身是一个 slice 。