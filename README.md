[toc]
<center> <h1>FISCO BCOS物料包工具使用指南</h1> </center>

# 一. 介绍
## 1.1 功能简介        
通过简单配置 ,可以在指定服务器上构建FISCO BCOS的区块链, 构成FISCO BCOS的节点既可以是普通节点(运行在服务器上的节点), 也可以是docker节点。 即可以非常快速的搭建临时使用的测试环境, 又能满足生产环境的需求。  
例如：  
配置三台服务器, 每台启动两个FISCO BCOS节点, 则将生成三个安装包, 对应三台服务器, 将安装包上传到对应的服务器上, 继续按照指引安装, 在每台服务器上启动节点, 就可以组成一个区块链网络。

## 1.2. 术语简介  
* 两种节点类型：**创世节点, 非创世节点**。
* **创世节点**：搭建一条新链时, 配置文件配置的第一台服务器上的第一个节点为创世节点, 创世节点是第一个加入节点管理合约的节点, 其他节点启动时需要主动连接创世节点, 通过与创世节点的连接, 获取其他节点的连接信息, 构建正常的网络。(参考FISCO-BCOS系统合约介绍[[节点管理合约]](https://github.com/FISCO-BCOS/Wiki/tree/master/FISCO-BCOS%E7%B3%BB%E7%BB%9F%E5%90%88%E7%BA%A6%E4%BB%8B%E7%BB%8D#%E8%8A%82%E7%82%B9%E7%AE%A1%E7%90%86%E5%90%88%E7%BA%A6))。
* **非创世节点**：除去创世节点的其它节点。

## 1.3. 特性功能
- [x] 从零开始搭建区块链：可以搭建出一条区块链的所有节点的安装包。
  * 步骤见( [5. 从零开始搭建区块链步骤](#buildblockchain) )
- [x] 区块链扩容。对以前的已经在跑的区块链, 可以提供其创世节点的相关文件, 创建出非创世节点, 并连接到这条区块链。
  * 步骤见( [附录一：指定给定的创世节点,扩容节点](#specific_genesis_node_expand) )

## 1.4. 依赖  
- [x]    机器配置  

   参考FISCO BCOS[机器配置](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual#第一章-部署fisco-bcos环境)  
   ```
   测试服务器： 
   CentOS 7.2 64位
   CentOS 7.4 64位
   Ubuntu 16.04 64位
   ```
  
- [x]    软件依赖  

```shell
docker
Oracle JDK[1.8]

[CentOS]
sudo yum -y install docker

[Ubuntu]
sudo apt -y install docker
```

**注意**
- 在需要搭建docker节点组链的情况下才需要安装docker, 如果只是搭建普通节点, 可以不需要.
- CentOS/Ubuntu默认安装或者使用yum/apt安装的是openJDK, 并不符合使用要求, Oracle JDK 1.8 的安装链接.  
[[ Oracle JDK 1.8 安装]](https://github.com/ywy2090/fisco-package-build-tool/blob/docker/doc/Oracle%20JAVA%201.8%20%E5%AE%89%E8%A3%85%E6%95%99%E7%A8%8B.md)

- [x]    其他依赖  
  sudo权限, 当前执行的用户需要具有sudo权限
  
# 二. <a name="buildblockchain" id="buildblockchain">部署区块链</a>  
本章节会通过一个示例说明如何使用物料包工具, 也会介绍使用物料包构建好的环境中比较重要的一些目录
如果你希望快速搭建并使用fisco bcos，请转至第四章部署区块链sample
## 2.1 下载物料包  


```shell
$ git clone https://github.com/FISCO-BCOS/fisco-package-build-tool.git
```
目录结构以及主要配置文件作用： 
```
fisco-package-build-tool
├── Changelog.md                       ChangLog更新记录       
├── config.ini                         配置文件
├── doc                                附属文档
├── ext                                拓展功能目录
├── generate_installation_packages.sh  主要执行文件
├── installation_dependencies          依赖文件目录
├── LICENSE                            license文件
├── README.md                          使用手册
└── release_note.txt                   版本号文件
```

## 2.2 配置

```shell
$ cd fisco-package-build-tool
$ vim config.ini
```

配置文件config.ini
```
[common]
; 物料包拉取FISCO-BCOS源码的github地址.
github_url=https://github.com/FISCO-BCOS/FISCO-BCOS.git
; 物料包拉取FISCO-BCOS源码之后, 会将源码保存在本地的目录, 保存的目录名称为FISCO-BCOS.
fisco_bcos_src_local=../
; 需要使用FISCO-BCOS的版本号, 使用物料包时需要将该值改为需要使用的版本号.
; 版本号可以是FISCO-BCOS已经发布的版本之一, 链接： https://github.com/FISCO-BCOS/FISCO-BCOS/releases
fisco_bcos_version=v1.3.1

[docker]
; 当前是否构建docker节点的安装包. 0:否    1:是
docker_toggle=0
; docker仓库地址.
docker_repository=fiscoorg/fisco-octo
; docker镜像版本号.
docker_version=v1.3.1

; 生成web3sdk证书时使用的keystore与clientcert的密码.
; 也是生成的web3sdk配置文件applicationContext.xml中keystorePassWord与clientCertPassWord的值.建议用户修改这两个值.
[web3sdk]
keystore_pwd=123456
clientcert_pwd=123456

[other]
; 是否采用CA拓展模式
; 一般情况不需要关系, 需要自己分配CA的情况下, 才需要打开。
ca_ext=0

; 扩容使用的一些参数
[expand]
; 分配CA证书的文件夹
genesis_ca_dir=cert
; 创世块文件
genesis_file=genesis.json
; 系统合约地址文件
system_address_file=syaddress.txt
; 连接节点信息文件
bootstrapnodes_file=bootstrapnodes.json

; 端口配置, 一般不用做修改, 使用默认值即可, 但是要注意不要端口冲突.
; 每个节点需要占用三个端口:p2p port、rpc port、channel port, 对于单台服务器上的节点端口使用规则, 默认配置的端口开始, 依次增长。
[ports]
; p2p端口
p2p_port=30303
; rpc端口
rpc_port=8545
; channel端口
channel_port=8821

; 节点信息
[nodes]
; 格式为 : nodeIDX=p2p_ip listen_ip num agent
; IDX为索引, 从0开始增加.
; p2p_ip     => 服务器上用于p2p通信的网段的ip.
; listen_ip  => 服务器上的监听端口, 用来接收rpc、channel的链接请求, 建议默认值为"0.0.0.0".
; num        => 在服务器上需要启动的节点的数目.
; agent      => 机构名称, 若是不关心机构信息, 值可以随意, 但是不可以为空.
node0=127.0.0.1  0.0.0.0  4  agent
``` 

下面以在三台服务器上部署区块链为例： 
```
服务器ip  ： 172.20.245.42 172.20.245.43 172.20.245.44  
机构分别为： agent_0   agent_1    agent_2  
节点数目  ： 每台服务器搭建两个节点
```

修改[nodes] section字段为：
```
[nodes]
node0=172.20.245.42  0.0.0.0  2  agent_0
node1=172.20.245.43  0.0.0.0  2  agent_1
node2=172.20.245.44  0.0.0.0  2  agent_2
```

## 2.3 创建安装包  
```
$ ./generate_installation_packages.sh build
```
执行成功之后会生成build目录, 目录下有生成的对应服务器的安装包：
```
build/
├── 172.20.245.42_with_0.0.0.0_genesis_installation_package
├── 172.20.245.43_with_0.0.0.0_installation_package
├── 172.20.245.44_with_0.0.0.0_installation_package
├── stderr.log  //  记录标准错误
└── temp        //  临时节点的目录, 用户不用关心.
```

* 其中带有**genesis**字样的为创世节点所在服务器的安装包。 

## 2.4 上传  
* 将安装包上传到对应的服务器, 注意上传的安装包必须与服务器相对应, 否则部署过程会出错。
* 一定要确认各个服务器之间的网络可连通, p2p网段的端口网络策略已经放开。

## 2.5 安装  
进入安装目录, 执行
```sh
$ ./install_node.sh install
```
正确执行在当前目录会多一个build目录, 目录结构如下：：
```
build/
├── node                   节点文件夹, 包含各个节点的目录、相关操作脚本
│   ├── check_node.sh      检查节点是否启动的脚本 
│   ├── fisco-bcos         fisco-bcos可执行程序
│   ├── genesis.json       创世块文件
│   ├── nodedir0           node0目录 
│   │   ├── config.json    node0 config.json配置文件
│   │   ├── fisco-data     node0 数据目录
│   │   └── log            node0 日志目录
│   ├── nodedir1           node1目录
│   │   ├── config.json    node1 config.json配置文件
│   │   ├── fisco-data     node1 数据目录
│   │   └── log            node1 日志目录
│   ├── start_node0.sh     node0的启动脚本
│   ├── start_node1.sh     node1的启动脚本
│   ├── stop_node0.sh      node0的停止脚本
│   └── stop_node1.sh      node1的停止脚本
├── nodejs                 nodejs的安装目录
├── node_manager.sh        节点管理脚本, 用于添加、删除、查询节点
├── node.sh                nodejs的环境变量
├── start_all.sh           启动所有节点脚本
├── stop_all.sh            停止所有节点脚本
├── systemcontract         nodejs系统合约工具
├── tool                   nodejs工具
├── web3lib                nodejs基础库
└── web3sdk                web3sdk环境
```

重要目录、文件说明:
- nodedirIDX : 节点nodeIDX的目录, IDX表示索引, 从0开始.
- nodedirIDX/fisco-data : 节点nodeIDX的数据目录
- nodedirIDX/log        : 节点nodeIDX的日志目录
- start_all.sh          : 启动所有的节点.  
- stop_all.sh           : 停止所有的节点.  
- systemcontract        : nodejs系统合约工具.  
- tool                  : nodejs工具.  
- web3lib               : nodejs基础库.  
- web3sdk               : web3sdk环境.

[[web3sdk使用说明链接]](https://github.com/FISCO-BCOS/web3sdk)  
[[web3lib、systemcontract、 tool目录作用参考用户手册]](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual)
## 2.6 启动节点

在build目录执行start_all.sh脚本  
**注意:要先启动创世块节点所在的服务器上的节点!!!**

```sh
$ ./start_all.sh
start node0 ...
start node1 ...
check all node status => 
node0 is running.
node1 is running.
```

## 2.7 验证

在所有的服务器的节点都启动之后, 验证区块链是否正常。
- **一定要所有服务器正常启动之后.**

### 2.7.1 日志

```shell
tail -f node/nodedir0/log/log_*.log  | egrep "Generating seal"
INFO|2018-08-03 14:16:42:588|+++++++++++++++++++++++++++ Generating seal on8e5add00c337398ac5e9058432037aa646c20fb0d1d0fb7ddb4c6092c9d654fe#1tx:0,maxtx:1000,tq.num=0time:1522736202588
INFO|2018-08-03 14:16:43:595|+++++++++++++++++++++++++++ Generating seal ona98781aaa737b483c0eb24e845d7f352a943b9a5de77491c0cb6fd212c2fa7a4#1tx:0,maxtx:1000,tq.num=0time:1522736203595
```
可看到周期性的出现上面的日志，表示节点间在周期性的进行共识，整个链正常。

### 2.7.2 部署合约

每个服务器执行install_node install之后, 都会在安装目录下安装nodejs、babel-node、ethconsole, 环境变量会写入当前安装用户的.bashrc文件, 用户需要使用这些工具可以：  
1. 退出当前登录, 重新登录一次.  
2. 执行node.sh脚本中的内容, 首先cat node.sh, 将显示的内容执行一遍.
```
 $ cat node.sh 
export NODE_HOME=/root/octo/fisco-bcos/build/nodejs; export PATH=$PATH:$NODE_HOME/bin; export NODE_PATH=$NODE_HOME/lib/node_modules:$NODE_HOME/lib/node_modules/ethereum-console/node_modules;
$ export NODE_HOME=/root/octo/fisco-bcos/build/nodejs; export PATH=$PATH:$NODE_HOME/bin; export NODE_PATH=$NODE_HOME/lib/node_modules:$NODE_HOME/lib/node_modules/ethereum-console/node_modules;
```

部署合约验证, 进入tool目录： 
```
$ cd tool
$ babel-node deploy.js HelloWorld
RPC=http://127.0.0.1:8546
Ouputpath=./output/
deploy.js  ........................Start........................
Soc File :HelloWorld
HelloWorldcomplie success！
send transaction success: 0xfb6237b0dab940e697e0d3a4d25dcbfd68a8e164e0897651fe4da6a83d180ccd
HelloWorldcontract address 0x61dba250334e0fd5804c71e7cbe79eabecef8abe
HelloWorld deploy success!
cns add operation => cns_name = HelloWorld
         cns_name =>HelloWorld
         contract =>HelloWorld
         version  =>
         address  =>0x61dba250334e0fd5804c71e7cbe79eabecef8abe
         abi      =>[{"constant":false,"inputs":[{"name":"n","type":"string"}],"name":"set","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"get","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"}]
send transaction success: 0x769e4ea7742b451e33cbb0d2a7d3126af8f277a52137624b3d4ae41681d58687
```
合约部署成功。


# 三. 扩容流程

- **扩容流程与部署流程最本质的差别是, 初次部署区块链时会生成一个temp节点, 进行系统合约的部署, 然后会将所有构建的节点信息都注册入节点管理合约, 最后temp节点导出生成genesis.json文件. 所以部署结束后, 每个节点信息都已经在节点管理合约, 但是在扩容时, 需要自己注册扩容的节点到节点管理合约。(参考FISCO-BCOS系统合约介绍[[节点管理合约]](https://github.com/FISCO-BCOS/Wiki/tree/master/FISCO-BCOS%E7%B3%BB%E7%BB%9F%E5%90%88%E7%BA%A6%E4%BB%8B%E7%BB%8D#%E8%8A%82%E7%82%B9%E7%AE%A1%E7%90%86%E5%90%88%E7%BA%A6))。**

## 3.1 使用场景  
对已经在运行的区块链, 可以提供其创世节点的相关文件, 创建出非创世节点, 使其可以连接到这条区块链。
## 3.2 获取扩容文件   
- 从创世节点所在服务器上拷贝下面的的3个文件，放到物料包工具所在的机器, 这几个文件位于创世节点安装包的dependencies/follow目录：
  * genesis.json 
  * bootstrapnodes.json  
  * syaddress.txt  
- [x]  也可以将创世节点的fisco-bcos文件放入物料包工具的/usr/local/bin目录.  

- 从创世节点所在服务器上取出dependencies/cert目录, 该目录包含创建时分配的根证书、机构证书, 放到物料包工具所在的机器。

假定将上述文件放入/fisco-bcos/目录.

## 3.3. 配置

配置需要扩容的节点的信息, 假定扩容的机器为: 172.20.245.45, 172.20.245.46 分别需要启动两个节点, 机构名称分别为agent_3、agent_4。
```sh
vim config.ini
```

修改扩容参数
```
; 扩容使用的一些参数
[expand]
; 分配CA证书的文件夹
genesis_ca_dir=/fisco-bcos/cert/
; 创世块文件
genesis_file=/fisco-bcos/genesis.json
; 系统合约地址文件
system_address_file=/fisco-bcos/syaddress.txt
; 连接节点信息文件
bootstrapnodes_file=/fisco-bcos/bootstrapnodes.json
```

修改节点列表为扩容的节点信息.
```
[nodes]
node0=172.20.245.45  0.0.0.0  2  agent_3
node1=172.20.245.46  0.0.0.0  2  agent_4
```

## 3.4. 扩容 
```
./generate_installation_packages.sh expand
```
成功之后会在build目录对应服务器上面的安装包
```
build
├── 172.20.245.45_with_0.0.0.0_installation_package
├── 172.20.245.46_with_0.0.0.0_installation_package
└── stderr.log
```

## 3.5 安装启动  
将安装包分别上传至对应服务器, 分别在每台服务器上面执行下列命令：  
- 执行安装
```
./install_node.sh install
```
- 启动节点
```
cd build
./start_all.sh
```

## 3.6 节点入网  

**在扩容时, 当前运行的链已经有数据, 当前新添加扩容的节点首先要进行数据同步, 建议新添加的节点在数据同步完成之后再将节点入网. 数据是否同步完成可以查看新添加节点的块高是否跟其他节点已经一致.**

以172.20.245.45这台服务器为例进行操作, 172.20.245.46操作类似：

节点的注册信息位于dependencies/node_action_info_dir目录下：
```
dependencies/node_action_info_dir/
├── nodeactioninfo_172_20_245_45_0.json
└── nodeactioninfo_172_20_245_45_1.json
```

**确保节点先启动.**   

注册
```
$ ./node_manager.sh registerNode `pwd` ../dependencies/node_action_info_dir/nodeactioninfo_172_20_245_45_0.json 
$ ./node_manager.sh registerNode `pwd` ../dependencies/node_action_info_dir/nodeactioninfo_172_20_245_45_1.json
```

验证,注册的节点是否正常:
```
$ tail -f node/nodedir0/log/log_2018071010.log   | egrep "Generating seal"
INFO|2018-07-10 10:49:29:818|+++++++++++++++++++++++++++ Generating seal oncf8e56468bab78ae807b392a6f75e881075e5c5fc034cec207c1d1fe96ce79a1#4tx:0,maxtx:1000,tq.num=0time:1531190969818
INFO|2018-07-10 10:49:35:863|+++++++++++++++++++++++++++ Generating seal one23f1af0174daa4c4353d00266aa31a8fcb58d3e7fbc17915d95748a3a77c540#4tx:0,maxtx:1000,tq.num=0time:1531190975863
INFO|2018-07-10 10:49:41:914|+++++++++++++++++++++++++++ Generating seal on2448f00f295210c07b25090b70f0b610e3b8303fe0a6ec0f8939656c25309b2f#4tx:0,maxtx:1000,tq.num=0time:1531190981914
INFO|2018-07-10 1
```
# 四. 部署区块链sample 
这里提供一个非常简单的例子, 用来示例使用本工具如何以最快的速度搭建一条在单台服务器上运行4个节点的FISCO BCOS的测试环境，
如果需要手动配置部署区块链请转到第三章。

假设当前用户的环境比较干净, 并没有修改配置文件config.ini。

## 4.1 下载物料包
```
$ git clone https://github.com/FISCO-BCOS/fisco-package-build-tool.git
```

## 4.2 生成安装包
```
$ cd fisco-package-build-tool
$ ./generate_installation_packages.sh build
......
//中间会有FISCO-BCOS下载、编译、安装, 时间会比较久, 执行成功最终在当前目录下会生成build目录.
......
```
查看生成的build目录结构
```
$ tree -L 1 build
build/
├── 127.0.0.1_with_0.0.0.0_genesis_installation_package
├── stderr.log
└── temp
```
其中 127.0.0.1_with_0.0.0.0_genesis_installation_package 即是生成的安装包.

## 4.3 安装
假定需要将FISCO BCOS安装在当前用户home目录下, 安装的目录名fisco-bcos。
```
$ mv build/127.0.0.1_with_0.0.0.0_genesis_installation_package ~/fisco-bcos
$ cd ~/fisco-bcos
$ ./install_node.sh install
..........
执行成功会生成build目录
```

## 4.4 启动  
```
$ cd build
$ ./start_all.sh
start node0 ...
start node1 ...
start node2 ...
start node3 ...
check all node status => 
node0 is running.
node1 is running.
node2 is running.
node3 is running.
```

## 4.5 验证  
```
$ tail -f node/nodedir0/log/log_2018080116.log | egrep "seal"
INFO|2018-08-01 16:52:18:362|+++++++++++++++++++++++++++ Generating seal on5b14215cff11d4b8624246de63bda850bcdead20e193b24889a5dff0d0e8a3c3#1tx:0,maxtx:1000,tq.num=0time:1533113538362
INFO|2018-08-01 16:52:22:432|+++++++++++++++++++++++++++ Generating seal on5e7589906bcbd846c03f5c6e806cced56f0a17526fb1e0c545b855b0f7722e14#1tx:0,maxtx:1000,tq.num=0time:1533113542432
```

## 4.6 部署成功  
Ok, 一条简单的测试链已经搭建成功。


# FAQ 
## generate_installation_packages.sh build/expand 报错提示.
- ERROR - build directory already exist, please remove it first.  
fisco-package-build-tool目录下已经存在build目录, 可以将build目录删除再执行。
- ERROR - no sudo permission, please add youself in the sudoers.  
当前登录的用户需要有sudo权限.
- ERROR - Unsupported or unidentified Linux distro.  
当前linux系统不支持, 目前FISCO-BCOS支持CentOS 7.2+、Ubuntu 16.04.
- ERROR - Unsupported Ubuntu Version. At least 16.04 is required.  
当前ubuntu版本不支持, 目前ubuntu版本仅支持ubuntu 16.04 64位操作系统.
- ERROR - Unsupported CentOS Version. At least 7.2 is required.  
当前CentOS系统不支持, 目前CentOS支持7.2+ 64位.
- ERROR - Unsupported Oracle Linux, At least 7.4 Oracle Linux is required.  
当前Oracle Linux不支持, 当前Oracle支持7.4+ 64位.
- ERROR - Unsupported Linux distribution    
不支持的linux系统.目前FISCO-BCOS支持CentOS 7.2+、Ubuntu 16.04.
- ERROR - Oracle JDK 1.8 be requied  
需要安装Oracle JDK 1.8.
- ERROR - OpenSSL 1.0.2 be requied  
openssl需要1.0.2版本.
- ERROR - XXX is not installed.  
XXX没有安装.  
- ERROR - FISCO BCOS gm version not support yet.  
物料包不支持国密版本的FISCO BCOS的安装.
- ERROR - At least FISCO-BCOS 1.3.0 is required.  
物料包工具支持的FISCO BCOS的最小版本为v1.3.0
- ERROR - Required version is xxx, now fisco bcos version is xxxx"  
当前fisco-bcos版本与配置的版本不一致, 建议手动编译自己需要的版本.
不支持国密版本的fisco-bcos环境搭建.
- ERROR - temp node rpc port check, XXX is in use.  
temp节点使用的rpc端口被占用, 可以netstat -anp | egrep XXX查看占用的进程是哪个. 
- ERROR - temp node channel port check, XXX is in use.  
temp节点使用的channel端口被占用, 可以netstat -anp | egrep XXX查看占用的进程是哪个. 
- ERROR - temp node p2p port check, XXX is in use.  
temp节点使用的p2p端口被占用, 可以netstat -anp | egrep XXX查看占用的进程是哪个. 
- ERROR - git clone FISCO-BCOS failed.  
下载FISCO-BCOS源码失败, 建议手动下载.  
- ERROR - system contract address file is not exist, web3sdk deploy system contract not success.  
temp节点部署系统合约失败.

## start_all.sh 显示nodeIDX is not running.  
这个提示是说nodeIDX启动失败, 可以ps -aux | egrep fisco 查看是否正常启动. 可以执行`cat node/nodedirIDX/log/log`查看节点启动失败的原因. 
常见的原因:
- libleveldb.so No such file or directory.
```
./fisco-bcos: error while loading shared libraries: libleveldb.so.1: cannot open shared object file: No such file or directory 
```
leveldb动态库缺失, 安装脚本里面默认使用 yum/apt 对依赖组件进行安装, 可能是 yum/apt 源缺失该组件。  
可以使用下面命令手动安装leveldb, 若leveldb安装不成功可以尝试替换yum/apt的源。
```
[CentOS]sudo yum -y install leveldb-devel
[Ubuntu]sudo apt-get -y install libleveldb-dev

```  
如果leveldb已经安装, 则可以尝试执行`sudo ldconfig`, 然后执行start_all.sh, 重新启动节点.

- FileError
```
terminate called after throwing an instance of 'boost::exception_detail::clone_impl<dev::FileError>' what():  FileError
```

操作文件失败抛出异常, 原因可能是当前登录的用户没有安装包目录的权限, 可以通过ls -lt查看当前文件夹对应的user/group/other以及对应的权限, 一般可以将安装包的user改为当前用户或者切换登录用户为安装包的user用户即.
