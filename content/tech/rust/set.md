---
title: "常见数据集合"
date: 2021-05-25T09:53:44+08:00
draft: false
tags:
- rust
- 笔记
---
## vector
- vector 允许存储多个值，在内存中顺序排列值。
- 使用 `Vec::new` 新建一个空的 vector。
```rust
let v: Vec<i32> = Vec::new();
```
- vector 是泛型实现的，可以存储任何类型的值。
- 使用`vec!`宏创建 vector：
```rust
let mut v = vec![1, 2, 3];
//更新vector
v.push(5);
```
- 丢弃 vector 时也会丢弃其所有元素。
- 读取 vector 的元素：
```rust
let v = vec![1, 2, 3, 4, 5];

let third: &i32 = &v[2];// 使用索引语法读取，索引越界将会导致程序奔溃
println!("The third element is {}", third);

match v.get(2) {// 使用 get 语法，get 返回 Option<&T>
    Some(third) => println!("The third element is {}", third),
    None => println!("There is no third element."),
}
```
- 使用 vector 引用获取其元素时不能更新元素。
```rust
let mut v = vec![1, 2, 3, 4, 5];
let first = &v[0];
v.push(6);//避免因为内存变更导致上面的引用失效
println!("The first element is: {}", first);
```
### 遍历 vector 元素
```rust
let v = vec![100, 32, 57];
for i in &v {//遍历，只读
    println!("{}", i);
}

let mut v = vec![100, 32, 57];
for i in &mut v {
    *i += 50;//改变元素的值，每个元素加 50
}
```
- 使用枚举来存储多种类型:
```rust
enum SpreadsheetCell {
    Int(i32),
    Float(f64),
    Text(String),
}
// 必须预先知道需要存储什么类型的值
// 使用枚举类型作为 vector 的值
let row = vec![
    SpreadsheetCell::Int(3),
    SpreadsheetCell::Text(String::from("blue")),
    SpreadsheetCell::Float(10.12),
];
```
## 字符串
- String 和字符串 slice 都是 UTF-8 编码的。
### 新建字符串
```rust
// 新建空字符串
let mut s = String::new();
// to_string()，from 初始化有内容的字符串：
let s = "initial contents".to_string();
let s = String::from("initial contents");
```
### 更新字符串
- push_str 更新字符串到字符串。
- push 更新一个字符到字符串。
```rust
let mut s = String::from("foo");
s.push_str("bar");// 采用 slice 不需要获取参数所有权
s.push('l');
```
### 拼接字符串
- 使用 + 运算符或 format! 宏拼接字符串。
```rust
let s1 = String::from("Hello, ");
let s2 = String::from("world!");
let s3 = s1 + &s2; // 注意 s1 被移动了，不能继续使用 。 &String 强转为 &Str。
// s3 将会包含 Hello, world!
```
- `+` 运算符使用了类似 `fn add(self, s: &str) -> String {}` 的函数签名。
- 只能将 &str 和 String 相加，不能将两个 String 值相加。
- 当需要连接很多个字符串的时候应该使用`format!`宏：
```rust
let s1 = String::from("tic");
let s2 = String::from("tac");
let s3 = String::from("toe");

let s = format!("{}-{}-{}", s1, s2, s3);//不会获取所有参数的所有权
```
### 索引字符串
- rust 不支持索引访问：
```rust
let s1 = String::from("hello");
let h = s1[0];//这个是错误的

let len = String::from("Hola").len();//返回 4
let len = String::from("Здравствуйте").len();//返回24，而不是12
```
- 因为 `UTF-8` 编码长度的不确定性，`rust` 索引不确保可以返回预期的字符，所以 `rust` 直接不支持字符串索引的访问。
- 还有一个 `Rust` 不允许使用索引获取 `String` 字符的原因是，索引操作预期总是需要常数时间 `(O(1))`。但是对于 `String` 不可能保证这样的性能，因为 `Rust` 必须从开头到索引位置遍历来确定有多少有效的字符。
### 字符串 slice
```rust
let hello = "Здравствуйте";

let s = &hello[0..4];//一个字母2个字节所以这里 s= Зд 。尝试获取 &hello[0..1] 会导致程序崩溃。
```
### 遍历字符串的方法
- 使用 chars 可以单独操作 Unicode 标量值. bytes 返回一个原始字节。
```rust
for c in "नमस्ते".chars() {
    println!("{}", c);
}
// 有效的 Unicode 标量值可能会由不止一个字节组成。
for b in "नमस्ते".bytes() {
    println!("{}", b);
}
```
## HashMap
- 哈希 map 可以用于需要任何类型作为键来寻找数据的情况，而不是像 vector 那样通过索引。
### 新建 hashMap
```rust
use std::collections::HashMap;

let mut scores = HashMap::new();

scores.insert(String::from("Blue"), 10);
scores.insert(String::from("Yellow"), 50);
```
- 所有的键必须是相同类型，值也必须都是相同类型。
- 使用 `collect` 创建 HashMap:
```rust
use std::collections::HashMap;

let teams  = vec![String::from("Blue"), String::from("Yellow")];
let initial_scores = vec![10, 50];

let scores: HashMap<_, _> = teams.iter().zip(initial_scores.iter()).collect();
// teams 里的值作为 k ，initial_scores 里的值作为 v。
```
### 哈希 map 和所有权
- 对于像 i32 这样的实现了 Copy trait 的类型，其值可以拷贝进哈希 map。
- 对于像 String 这样拥有所有权的值，其值将被移动而哈希 map 会成为这些值的所有者。
```rust
use std::collections::HashMap;

let field_name = String::from("Favorite color");
let field_value = String::from("Blue");

let mut map = HashMap::new();
map.insert(field_name, field_value);
// 这里 field_name 和 field_value 将会失效。发生了移动
```
### 访问哈希 map 中的值
```rust
use std::collections::HashMap;
let mut scores = HashMap::new();
let team_name = String::from("Blue");
let score = scores.get(&team_name);//返回 Option<V>
// 遍历
for (key, value) in &scores {
    println!("{}: {}", key, value);
}
```
### 更新 HashMap
- 当对一个已存在的 key 执行 insert 操作时，key 
- 使用 entry 在 key 不存在时新建这个 k-v 。
```rust
use std::collections::HashMap;

let mut scores = HashMap::new();
scores.insert(String::from("Blue"), 10);

scores.entry(String::from("Yellow")).or_insert(50);
scores.entry(String::from("Blue")).or_insert(50);
// or_insert 方法如果 key 的 value 不存在则创建这个值。最终都会返回值的可变引用。
println!("{:?}", scores);

// ---- 以下代码统计单词个数
let text = "hello world wonderful world";
let mut map = HashMap::new();
for word in text.split_whitespace() {
    let count = map.entry(word).or_insert(0);//如果是第一次看到某个单词，就插入值 0。
    *count += 1;
}

println!("{:?}", map);
```