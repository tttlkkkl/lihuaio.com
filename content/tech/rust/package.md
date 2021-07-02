---
title: "包和 crate"
date: 2021-05-24T16:00:15+08:00
draft: false
tags:
- rust
- 笔记
---
- crate 是一个二进制项或者库。
- 包（package） 是提供一系列功能的一个或者多个 crate。
- 一个包会包含有一个 Cargo.toml 文件，阐述如何去构建这些 crate。
- 约定 src/main.rs 或者 src/lib.rs 是一个与包同名的二进制 crate 的 crate 根。
## 包的规则
- 一个包中至多 只能 包含一个库 crate(library crate)；
- 包中可以包含任意多个二进制 crate(binary crate)；
- 包中至少包含一个 crate，无论是库的还是二进制的。

## 模块
- 模块 让我们可以将一个 crate 中的代码进行分组，以提高可读性与重用性。
- 模块还控制项的可见性。
- 模块用`mod`关键字定义，模块可以相互嵌套。
- 模块树类似一个文件系统，整个模块树都处于一个名叫 `crate` 的隐式模块下面。

## 模块路径
- 绝对路径：从 crate 根开始，以 crate 名或者字面值 crate 开头。
- 相对路径：从当前模块开始，以 self、super 或当前模块的标识符开头。
- 绝对路径和相对路径都后跟一个或多个由双冒号（::）分割的标识符。
- 默认所有项（函数、方法、结构体、枚举、模块和常量）都是私有的。
- 父模块中的项不能使用子模块中的私有项，但是子模块中的项可以使用他们父模块中的项。
- 可以使用 `pub` 关键字将项变为共有的。
- 模块公有并不使其内容也是公有的。模块上的 pub 关键字只允许其父模块引用它。
- 可以使用 super 开头来构建从父模块开始的相对路径。
- 结构体的字段和方法都需要单独指定是否为公有。

## use 关键字
- 可以使用 use 关键字将路径引入到作用域中。
- 习惯性的引入目标项的父路径到作用域中，以表明是从外部引入的。
- 当使用 use 关键字将名称导入作用域时，在新作用域中可用的名称是私有的。
- 如果为了让调用你编写的代码的代码能够像在自己的作用域内引用这些类型，可以结合 pub 和 use,这就是重导入。
## 使用外部包
- 外部包需要在 `Cargo.toml` 显示导入，标准库的包除外。
```rust
use std::{cmp::Ordering, io};
// 等同
use std::cmp::Ordering;
use std::io;

use std::io::{self, Write};
// 等同
use std::io;
use std::io::Write;
```
- 通过 glob 运算符 `*` 引入一个路径下面的所有公有项。
```rust
use std::collections::*;
```
- Glob 会使得我们难以推导作用域中有什么名称和它们是在何处定义的,常用于 tests 测试模块中。

## 模块放入不同的文件
```rust
// src/lib.rs
mod front_of_house;//将在与模块同名的文件中加载模块的内容
```