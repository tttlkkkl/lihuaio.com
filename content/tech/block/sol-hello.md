---
title: "编写 solana hello 示例程序"
date: 2021-05-26T20:52:51+08:00
draft: false
tags:
- 区块链
- solana
---
- solana 的智能合约执行 BPF 字节码，理论上只要支持生成 BPF 的程序语言都可以用来编写 solana 智能合约。
- rust 提供了 C/C++ 和 rust 的稳定支持。

## 基本概念
- Transactions 是由客户端向 solana 发起请求的基本单元。
- 一个 Transactions 可以包含多个 Instruction 。
- solana 收到 Transactions 后解析 Instruction ，然后根据 program_id 来调用对应的智能合约，并将 Instruction 传递给对应的智能合约。
- Instruction 是智能合约的基本单元。
- DApp 将自定义的指令数据序列化打包，连同账号信息发布到 solana ，solana 节点找到智能合约程序（需要执行的一段程序）并传递数据过去，合约程序获得数据执行合约逻辑。
- account 在 solana 上并不是只表示一个账号地址，而是泛指链上的资源：内存、文件、CPU 等。
- 用户需要为链上的文件付费，用 SOL 代币计费。如果想要关闭文件需要将此 account （文件）里面的 SOL 都转出。此时将无法为文件付费，文件将会被删除。
- 1000000000 lamport 等于 1 个 SOL。
### account 概念
```rust
// solana-program
pub struct AccountInfo<'a> {
    /// Public key of the account
    pub key: &'a Pubkey,
    /// Was the transaction signed by this account's public key?
    pub is_signer: bool,
    /// Is the account writable?
    pub is_writable: bool,
    /// The lamports in the account.  Modifiable by programs.
    pub lamports: Rc<RefCell<&'a mut u64>>,
    /// The data held in this account.  Modifiable by programs.
    pub data: Rc<RefCell<&'a mut [u8]>>,
    /// Program that owns this account
    pub owner: &'a Pubkey,
    /// This account's data contains a loaded program (and is now read-only)
    pub executable: bool,
    /// The epoch at which this account will next owe rent
    pub rent_epoch: Epoch,
}
```
### 合约程序具体需要做的事情
- 解析由 runtime 传过来的 instruction。
- 执行 instruction 对应的逻辑。
- 将执行结果中需要落地的部分，打包输出到指定的 Account 文件，即存储到区块链，区块链相当于一个分布式数据库。
## 本例实现的功能

## 准备工作
### 生成密钥对
- 从 https://rustup.rs/ 安装最新的 Rust 稳定版本。
- 从 https://docs.solana.com/cli/install-solana-cli-tools 安装 Solana 命令列管理工具。
- 将命令行配置的 url 设置成 localhost(本地) 集群。
```bash
solana config set --url localhost
```
- - 以上命令将配置写入 ~/.config/solana/cli/config.yml。文件内容（solana-cli 1.6.8）如下：
```yaml
---
json_rpc_url: "http://localhost:8899"
websocket_url: ""
keypair_path: ~/.config/solana/id.json
address_labels:
  "11111111111111111111111111111111": System Program
```
- - 其中 json_rpc_url 为集群地址。
- - 其中 keypair_path 为密钥对文件路径。
- 创建密钥对（钱包）:
```bash
# 创建默认密钥对写入到配置文件指定的文件中
solana-keygen new
# 创建第二个密钥对
solana-keygen new --outfile ~/.config/solana/id2.json
```
- 查看账号（pubkey，钱包地址）：
```bash
# 查看默认账号地址
solana-keygen pubkey
# 或者写入到文件
solana-keygen pubkey -o ~/.config/solana/default.pub
# 查看第二个密钥对账号地址
solana-keygen pubkey ~/.config/solana/id2.json
```
- 启动本地测试集群：
```bash
solana-test-validator
```
## 编写 DApp
- 官方示例中用了 nodejs 。对于不熟悉 nodejs 的纯后端同志来说理解起来有点困难，本例中使用 rust 进行编写。


## 编写智能合约