---
title: "错误处理"
date: 2021-05-25T18:12:48+08:00
draft: false
tags:
- rust
- 笔记
---
rust 没有类似其他语言异常的概念，而是分为可恢复`(Result<T, E>)`和不可恢复(panic!)错误。
## 不可恢复的错误 panic!
- panic! 默认展开程序——回朔栈并清理数据然后退出。
- 也可以选择直接退出，然后由操作系统回收内存，这样做可以减小二进制文件的大小。
```rust
// Cargo.toml 文件
[profile.release]
panic = 'abort'//直接退出
```
- 设置 `RUST_BACKTRACE=1` 环境变量可以打印详细的堆栈信息。需要开启 debug 模式。
## result 与可恢复的错误
- Result 是一个枚举：
```rust
enum Result<T, E> {
    Ok(T),
    Err(E),
}
```
错误处理的例子：
```rust
use std::fs::File;
use std::io::ErrorKind;

fn main() {
    let f = File::open("hello.txt");

    let f = match f {
        Ok(file) => file,// 文件成功打开
        Err(error) => match error.kind() {
            ErrorKind::NotFound => match File::create("hello.txt") {// 如果文件不存在尝试创建
                Ok(fc) => fc,
                Err(e) => panic!("Problem creating the file: {:?}", e),// 文件创建失败的情形
            },
            other_error => panic!("Problem opening the file: {:?}", other_error),// 不是文件不存在的类型
        },
    };
}
```
### unwrap 和 expect 简写
```rust
let f = File::open("hello.txt").unwrap();// 如果 Result 的值是 OK 则返回 OK 的值，否则调用 panic!
let f = File::open("hello.txt").expect("Failed to open hello.txt");// 如果 Result 的值是 OK 则返回 OK 的值，否则调用 panic! 并使用自定义的错误信息
```
### 返回错误信息
```rust
use std::io;
use std::io::Read;
use std::fs::File;
// 读取文件内容
fn read_username_from_file() -> Result<String, io::Error> {
    let f = File::open("hello.txt");

    let mut f = match f {
        Ok(file) => file,// 文件能够打开则赋值给变量 f
        Err(e) => return Err(e),// 文件打开错误则提前返回错误
    };

    let mut s = String::new();

    match f.read_to_string(&mut s) {
        Ok(_) => Ok(s),// 正常读取文件内容则则返回正确的文件内容
        Err(e) => Err(e),// 否则返回错误信息，由于在函数结尾所以无需创建 显示的 return
    }
}
```
### ? 运算符
- ?运算符简化了错误的回传
```rust
use std::io;
use std::io::Read;
use std::fs::File;

fn read_username_from_file() -> Result<String, io::Error> {
    let mut f = File::open("hello.txt")?;//如果文件能正常打开则继续执行，否则原样返回 Err
    let mut s = String::new();
    f.read_to_string(&mut s)?;// 如果能读取文件内容继续否则原样返回错误信息
    Ok(s)
    // ------更简单的链式调用写法
    let mut s = String::new();
    File::open("hello.txt")?.read_to_string(&mut s)?;
    Ok(s)
    // ------再简化的写法
    fs::read_to_string("hello.txt")
}
```
- 只能在返回 Result 或者实现了 std::ops::Try 类型的函数中使用 ? 运算符。
- main 函数默认返回 `()`。也可以返回 `Result<T, E>`：
```rust
use std::error::Error;
use std::fs::File;

fn main() -> Result<(), Box<dyn Error>> {
    let f = File::open("hello.txt")?;

    Ok(())
}
```
## 何时使用 panic!
- 一旦调用了 panic! 程序将不可恢复，相比而言返回 Result 是一个默认较好的选择。
- 示例、代码原型和测试都非常适合 panic.
- 当我们比编译器知道更多的情况,即确定不会出错的情况或者不容许可能的错误出现的情况。
## 错误处理指导原则
- 有可能会导致有害状态的情况下建议使用 panic!
- - 有害状态并不包含 预期 会偶尔发生的错误。
- - 在此之后代码的运行依赖于不处于这种有害状态。
- - 当没有可行的手段来将有害状态信息编码进所使用的类型中的情况。