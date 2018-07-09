[toc]
<center> <h1>FISCO BCOS物料包工具使用指南</h1> </center>

# 1. 背景介绍
- 工具主要功能 ：       
通过简单的配置 1. 可以很容易的搭建运行在指定服务器上的FISCO BCOS区块链 2. 服务器上搭建运行FISCO BCOS的docker容器, 进行组链。 快速搭建生产可用的FISCO BCOS环境。  
例如：配置三台服务器, 每台启动两个FISCO BCOS节点或者每台上面启动两个FISCO BCOS docker镜像, 则将生成三个安装包, 对应三台服务器, 将安装包上传到对应的服务器上, 继续按照指引安装, 在每台服务器上启动节点, 就可以组成一个区块链网络。

# 2. 术语  
* 两种节点类型：**创世节点, 非创世节点**。
* **创世节点**：配置文件配置的第一台服务器上的第一个节点为创世节点, 创世节点是第一个加入节点管理合约的节点, 其他节点启动时需要主动连接创世节点, 通过与创世节点的连接, 获取其他节点的连接信息, 构建正常的网络。(参考FISCO-BCOS系统合约介绍[[节点管理合约]](https://github.com/FISCO-BCOS/Wiki/tree/master/FISCO-BCOS%E7%B3%BB%E7%BB%9F%E5%90%88%E7%BA%A6%E4%BB%8B%E7%BB%8D#%E8%8A%82%E7%82%B9%E7%AE%A1%E7%90%86%E5%90%88%E7%BA%A6))。
* **非创世节点**：除去创世节点的其它节点。

# 3. 工具提供的功能
- [x] 从零开始搭建区块链：可以搭建出一条区块链的所有节点的安装包。
  * 步骤见( [5. 从零开始搭建区块链步骤](#buildblockchain) )
- [x] 区块链扩容。对以前的已经在跑的区块链, 可以提供其创世节点的相关文件, 创建出非创世节点, 并连接到这条区块链。
  * 步骤见( [附录一：指定给定的创世节点,扩容节点](#specific_genesis_node_expand) )

# 4. 安装依赖  
- [x]    机器配置  

   参考FISCO BCOS区块链操作手册：[[机器配置]](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual#11-机器配置)  
  
- [x]    软件依赖  

```shell
git 
dos2unix
openssl [1.0.2]
Oracle JDK[1.8]

[CentOS]
sudo yum -y install git 
sudo yum -y install dos2unix
sudo yum -y install openssl

[Ubuntu]
sudo apt -y install git
sudo apt -y install tofrodos
sudo apt -y install openssl
ln -s /usr/bin/todos /usr/bin/unix2dos 
ln -s /usr/bin/fromdos /usr/bin/dos2unix 
```

注意： yum/apt下载的JDK为openjdk, 并不符合使用要求, Oracle JDK[1.8] 可以在Oracle官网手动下载 ,下面附带下载连接[[ Oracle JDK 1.8 下载链接]](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

- [x]    其他依赖  
  sudo权限, 当前执行的用户需要具有sudo权限

# 5. <a name="buildblockchain" id="buildblockchain">从零开始搭建区块链步骤</a>
#### 5.1 准备
* 获取fisco-package-build-tool工具包  
git clone https://github.com/FISCO-BCOS/fisco-package-build-tool.git  
然后执行下面命令:  
```shell
$ cd fisco-package-build-tool
$ chmod a+x format.sh ; dos2unix format.sh ; ./format.sh
```

#### 5.2 配置新建区块链的节点信息

```shell
$ vim installation_config.sh
```

下面以在三台服务器上分别启动两个节点为例子，参考配置如下：  
```
#!/bin/bash

#github path for FISCO BCOS
FISCO_BCOS_GIT="https://github.com/FISCO-BCOS/FISCO-BCOS.git"
#local FISCO BCOS path, if FICSO BSOC is not exist in the path, pull it from the github.
FISCO_BCOS_LOCAL_PATH="../"

# default config for temp block node, if the port already exist, please change the following config.
P2P_PORT_FOR_TEMP_NODE=30303
RPC_PORT_FOR_TEMP_NODE=8545
CHANNEL_PORT_FOR_TEMP_NODE=8821

##config for docker generation
#if build docker install
IS_BUILD_FOR_DOCKER=0
#fisco-bcos docker repository, default "docker.io/fiscoorg/fiscobcos"
DOCKER_REPOSITORY="docker.io/fiscoorg/fiscobcos"
#fisco-bcos docker version, default "latest"
DOCKER_VERSION="docker-beta-v1.0.0703"

# config for ca
IS_CA_EXT_MODE=0

# config for the blockchain node
# the first node is the genesis node
# field 0 : p2pnetworkip
# field 1 : listennetworkip
# field 2 : node number on this host
# filed 3 : agent info
weth_host_0=("***REMOVED***" "***REMOVED***" "2" "agent_0")
weth_host_1=("***REMOVED***" "***REMOVED***" "2" "agent_1")
weth_host_2=("***REMOVED***" "***REMOVED***" "2" "agent_2")

MAIN_ARRAY=(
weth_host_0[@]
weth_host_1[@]
weth_host_2[@]
)
```

**配置项：**
- FISCO_BCOS_GIT  
  获取FISCO-BCOS的github路径,默认从https://github.com/FISCO-BCOS/FISCO-BCOS.git获取。 
- FISCO_BCOS_LOCAL_PATH  
  本地的FISCO-BCOS所在的目录, 如果该目录存在FISCO-BCOS目录, 则不会从github上面重新拉取FISCO-BCOS。**目前国内的github获取速度比较慢, 所以建议大家可以将FISCO-BCOS下载下来之后, 直接放入FISCO_BCOS_LOCAL_PATH配置的目录**。
- P2P\_PORT\_FOR\_TEMP\_NODE  
  RPC\_PORT\_FOR\_TEMP_NODE  
  CHANNEL\_PORT\_FOR\_TEMP\_NODE  
  在构建安装包时, 会启动一个临时的temp节点(详见配置说明 1), 用来进行系统合约的部署, 将构建的节点的节点信息注册到节点管理合约。这几个配置端口分别表示: p2p端口、rpc端口、  channel端口, 是启动的temp节点需要用到的临时端口, <span style="color:red">一般不需要改动, 但是要确保这些端口不要被占用</span>。
- weth\_host\_n是第n台服务器的配置。  
- field 0(p2p_network_ip)： p2p连接的网段ip, 根据p2p网络的网段配置。
- field 1(listen_network_ip)： 监听网段, 用来接收rpc、channel连接请求。
- field 2(node number on this host)：在该服务器上面需要创建的节点数目。  
- field 3(agent info)： 机构名称, 不关心机构则可以随意值, 但不能为空。  
weth_host_0=("***REMOVED***" "***REMOVED***" "2" "agent_0")  
说明需要在***REMOVED***这台服务器上面启动两个节点, 节点对应的机构名称是agent_0,。  
- IS_BUILD_FOR_DOCKER ： 是否构建docker运行环境。 1：是 , 其他值：否
- DOCKER_REPOSITORY : docker镜像库
- DOCKER_VERSION : docker的版本号
- IS_CA_EXT_MODE：秘钥管理机制开关,参考( [附录二：秘钥管理](#ca-manager) ), 一般采取默认值就可以。  
 **配置说明：**  
- 1. 工具在构建安装包(非扩容流程)过程中会启动一个temp节点, 用于系统合约的部署, 注册节点信息到节点管理合约, 生成genesis.json文件。  
- 2. 每个节点需要占用三个端口:p2p port、rpc port、channel port, 对于单台服务器上的节点端口使用规则, 默认从temp节点的端口+1开始, 依次增长。例如temp节点的端口配置为了p2p port 30303、rpc port 8545、channel port 8821, 则每台服务器上的第0个节点默认使用p2p port 30304、rpc port 8546、channel port 8822，第1个节点默认使用p2p port 30305、rpc port 8547、channel port 8823, 以此类推, 要确保这些端口没有被占用。  
- 3. 工具构建安装包过程中会涉及到从github上面拉取FISCO BCOS、编译FISCO BCOS流程, 具体规则如下：  
  a、首先检查/usr/local/bin目录下是否存在fisco-bcos文件,  若存在则说明fisco-bcos已经被编译安装, 不存在则继续流程b 。   
  b、判断配置文件中FISCO_BCOS_LOCAL_PATH的时路径是否存在名为FISCO-BCOS的文件夹, 存在则说明FISCO-BCOS源码已经存在, 直接进入FISCO-BCOS目录进行编译、安装流程, 否则进行流程c。  
  c、从FISCO_BCOS_GIT配置的github地址拉取FISCO-BCOS源码, 拉取完成之后进入FISCO-BCOS目录, 进行FISCO BCOS的编译安装流程, 编译生成的文件为fisco-bcos, 安装目录为/usr/local/bin。  
d、本工具拉取、编译的代码只会是FISCO BCOS的master分支, 如果需要运行其他分支的代码, 建议下载代码, 切换好分支, 或者将FISCO BCOS自行编译安装。 
- 4. 理论上来说, docker版本不需要这个编译流程, 但考虑到编译生成的fisco-bcos文件比较大, 自带不是很方便, 所以构建docker环境也会有编译的流程。

#### 5.3 创建安装包

```sh
$ ./generate_installation_packages.sh build
```

* 执行后在当前目录会自动生成**build**目录, 在build目录下生成安装包, 其中带有**genesis**字样的为创世节点所在服务器的安装包。  
按照示例配置, 会生成下面的四个安装包：
```
$ ls build/

***REMOVED***_with_***REMOVED***_installation_package
***REMOVED***_with_***REMOVED***_installation_package
***REMOVED***_with_***REMOVED***_genesis_installation_package
temp
```
其中temp目录为临时节点的目录, 其余的几个包分别为对应服务器上的安装包。

下面以***REMOVED***_with_***REMOVED***_genesis_installation_package包为例说明目录结构, 其他安装包的目录结构完全一致：
```shell
$ cd ***REMOVED***_with_***REMOVED***_genesis_installation_package
$ ls
$ dependencies  install_node.sh
```
- install_node.sh ：安装脚本, 将安装包上传至对应服务器后执行, 用来生成节点运行环境。  
- dependencies ：目录如下
```shell
$ ls dependencies/
$ cert  fisco-bcos  follow  monitor  node_action_info_dir  nodejs  rlp_dir  scripts  systemcontract  tool  tpl_dir  web3lib  web3sdk
```

dependencies目录文件说明：
- cert ： 证书工具, 在构建安装包过程中生成链的根证书、机构证书、节点证书、web3sdk证书信息。**最终根证书、根证书私钥、机构证书、机构证书、机构证书私钥信息都会保存在创世节点的该目录, 扩容时需要使用创世节点服务器为新的节点颁发证书**.
- follow : 存储系统合约地址文件、创世块文件等, **扩容时,系统合约地址、创世块文件需要从创世节点服务器的follow目录获取**。
```
follow目录:
$ ls dependencies/follow/
$ bootstrapnodes.json  config.sh  genesis.json  syaddress.txt

config.sh  : 用于构建config.json的关键配置
genesis.json  : 创世块文件
node_manager.sh  : 节点管理工具
syaddress.txt ： 系统合约地址
```
- node_action_info_dir：保存对应服务器上运行的节点的注册信息文件, 初次构建的节点该目录不需关心, **对于扩容构建的安装包,节点启动后, 需要注册目录下的文件内容到节点管理合约**.  
```
nodeactioninfo_***REMOVED***_0.json
nodeactioninfo_***REMOVED***_1.json
节点信息文件名的格式为nodeactioninfo_p2p_network_ip_IDX
说明：
IDX为索引值,从0开始,表示服务器上的第IDX个节点。
```
- rlp_dir：保存节点、web3sdk的证书.
```
rlp_dir/node_rlp_IDX/ca/node   #保存节点证书信息
rlp_dir/node_rlp_IDX/ca/sdk    #保存web3sdk证书信息
说明：IDX为索引值,从0开始,表示服务器上的第IDX个节点。
```
- tool：nodejs合约工具.
- web3sdk：web3sdk工具.
- systemcontract：nodejs系统合约工具.
- web3lib：nodejs公共依赖文件.
- nodejs：nodejs源码,版本为6.0.
- fisco-bcos：fisco-bcos可执行文件.

#### 5.4 扩容流程相关
> 综上所述, 构建的安装包与扩容流程相关的目录：
```
dependencies/follow
dependencies/cert
dependencies/node_action_info_dir
```

#### 5.5 准备工作  
* 将安装包上传到对应的服务器, 注意上传的安装包必须与服务器相对应, 否则搭链过程会出错。
* 一定要确认各个服务器之间的网络可连通, p2p网段的端口网络策略已经放开。

**注意**：
- [x]  1. ./generate_installation_packages.sh build执行出错, 可以参考下面FAQ的解决方案。
- [x]  2. ./generate_installation_packages.sh build过程出错, 解决问题后, 需要将build目录删除, 再执行下次./generate_installation_packages.sh build。
- [x]  3. 生成的安装包最好不要部署在build目录内, 部署在build目录时, 启动的fisco-bcos进程也会在build目录下, 会导致build目录无法删除, 下次想重新生成其他安装包时可能引发一些问题。


# <a name="deploy_genesis_host_node" id="deploy_genesis_host_node">6. 部署节点</a>  

在服务器上面直接运行节点与在服务器上运行docker镜像的节点(installation_config.sh中的IS_BUILD_FOR_DOCKER字段配置决定), 流程上会有些差异, 下面分开来说明.

#### 6.1 非docker方式
##### 6.1.1 执行安装脚本  
进入安装目录, 执行
```sh
$ ./install_node.sh install
```
正常执行在当前目录会多一个build目录, 进入目录：
```
$ cd build
$ ls 
$ node  nodejs  node_manager.sh  node.sh  start_all.sh  stop_all.sh  systemcontract  tool  web3lib  web3sdk
```

目录文件说明:
- node :节点的启停脚本, 数据目录.  
```
$ cd node
$ ls
$check_node.sh  genesis.json  init_web3_para.sh nodedir0 nodedir1  start_node0.sh  start_node1.sh  stop_node1.sh stop_node0.sh fisco-bcos

fisco-bcos : fisco-bcos可执行程序.  
genesis.json : 创世块文件.  
nodedirIDX ： IDX从0开始, 表示本服务器上安装的第IDX个节点的目录
start_nodeIDX ： 第IDX个节点的启动脚本.  
stop_noddeIDX ： 第IDX个节点的停止脚本.
check_node.sh : 检查节点是否运行, 使用方式： ./check_node IDX

重要子目录说明：
nodedirIDX/log ：日志目录, 第IDX个节点的log目录.
nodedirIDX/fisco-data ： 数据目录,第IDX节点的数据目录.
```
- nodejs : 本工具自带安装的nodejs, 版本为6.0.   
- node.sh : nodejs的环境变量.
- node_manager.sh : 用来管理节点注册与删除的脚本, 扩容时会用到.  
- start_all.sh：启动所有的节点.  
- stop_all.sh：停止所有的节点.  
- systemcontract: nodejs系统合约目录.  
- tool： nodejs工具目录.  
- web3lib：nodejs库文件.  
- web3sdk： web3sdk工具目录, 已经配置可用的web3sdk环境.

[[web3sdk使用说明链接]](https://github.com/FISCO-BCOS/web3sdk)  
[[web3lib、systemcontract、 tool目录作用参考用户手册]](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual)
##### 6.1.2 启动节点
在build目录执行start_all.sh脚本  
**注意:要先启动创世块节点所在的服务器!!!**

```sh
$ ./start_all.sh
start node0 ...
start node1 ...
check all node status => 
node0 is running.
node1 is running.
```

##### 6.1.3 验证

###### 6.1.3.1 日志

在所有的服务器的节点都启动之后, 验证区块链是否正常。  
```shell
tail -f node/nodedir0/log/log_*.log  | egrep "Generating seal"
INFO|2018-04-03 14:16:42:588|+++++++++++++++++++++++++++ Generating seal on8e5add00c337398ac5e9058432037aa646c20fb0d1d0fb7ddb4c6092c9d654fe#1tx:0,maxtx:1000,tq.num=0time:1522736202588
INFO|2018-04-03 14:16:43:595|+++++++++++++++++++++++++++ Generating seal ona98781aaa737b483c0eb24e845d7f352a943b9a5de77491c0cb6fd212c2fa7a4#1tx:0,maxtx:1000,tq.num=0time:1522736203595
```
可看到周期性的出现上面的日志，表示节点间在周期性的进行共识，整个链正常。

###### 6.1.3.2 部署合约

每个服务器执行install_node install之后, 都会在安装目录下安装nodejs、babel-node、ethconsole, 环境变量会写入当前安装用户的.bashrc文件, 用户需要使用这些工具可以：  
1. 退出当前登录, 重新登录一次.  
2. 执行node.sh脚本, bash node.sh.

部署合约验证, 进入build/tool目录： 
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

#### 6.2 docker方式安装 
##### 6.2.1 执行安装脚本 
进入安装目录, 执行
```sh
$ ./install_node.sh install
```
正常执行在当前目录会多一个docker目录:   
```
$ cd docker
$ ls

nodedir0  nodedir1 start_node0.sh  start_node1.sh stop_node0.sh  stop_node1.sh start_all.sh  stop_all.sh
```
- start_all.sh 启动所有的docker节点   
- stop_all.sh 停止所有的docker节点  
- start_nodeIDX : 启动第IDX个docker节点  
- stop_nodeIDX：停止第IDX个docker节点  
- nodedirIDX: 第IDX个docker节点的目录  
- nodedirIDX/log: 第IDX个docker节点的日志目录  
- nodedirIDX/fisco-data: 第IDX个docker节点的数据目录
- **docker节点启动每一个nodedirIDX目录会被映射到一个docker节点的/fisco-bcos/node目录,所以这两个目录的结构是一样的.**  

##### 6.2.2 启动节点
在build目录执行start_all.sh脚本  
**注意：要先启动创世块节点所在的服务器!!!**  
```sh
$ ./start_all.sh
start node0 ...
0e4214c0c93a5751cf2c8136d1a6a3ecce1f3d6350bdb3f88d5b8ba6ef2fe4d6
start node1 ...
79b5d3a6d930b2af308da7d1a3357a11946f11664842481676d6d638962b195e
```
##### 6.2.3 验证

###### 6.2.3.1 日志

在所有的服务器的节点都启动之后, 验证区块链是否正常。  
```shell
tail -f nodedir0/log/log_*.log  | egrep "Generating seal"
INFO|2018-04-03 14:16:42:588|+++++++++++++++++++++++++++ Generating seal on8e5add00c337398ac5e9058432037aa646c20fb0d1d0fb7ddb4c6092c9d654fe#1tx:0,maxtx:1000,tq.num=0time:1522736202588
INFO|2018-04-03 14:16:43:595|+++++++++++++++++++++++++++ Generating seal ona98781aaa737b483c0eb24e845d7f352a943b9a5de77491c0cb6fd212c2fa7a4#1tx:0,maxtx:1000,tq.num=0time:1522736203595
```
可看到周期性的出现上面的日志，表示节点间在周期性的进行共识，整个链正常。

###### 6.2.3.2 部署合约  
fisco-bcos节点启动在docker中时, 部署合约需要进入正在运行的docker镜像中,
使用下面的命令找到刚才启动的docker节点：
```
$ sudo docker ps -a -f name="fisco*"
CONTAINER ID        IMAGE                                      COMMAND                  CREATED             STATUS                           PORTS               NAMES
e4c3228c6b4c        fiscoorg/fiscobcos:docker-beta-v1.0.0703   "/fisco-bcos/start_n…"   2 hours ago         Up (137) About an hour ago                       fisco-node0_8550
4ad31c7794be        fiscoorg/fiscobcos:docker-beta-v1.0.0703   "/fisco-bcos/start_n…"   2 hours ago         Up (137) About an hour ago                       fisco-node1_8549
```
注意 NAMES一列:   
目前fisco-bcos的节点为了不重名, docker镜像的命名采取 fisco-nodeIDX_rpcport的格式, IDX表示索引, rpcport为config.json配置中rpcport的配置。  

选择fisco-node1_8549这个节点, 该节点镜像id为4ad31c7794be, 进入到docker中:

每个docker里面都有内置的完整的nodejs、web3sdk环境.  
进入docker之后需要先执行 **source /etc/profile 加载环境变量**.  
然后进入fisco-bcos的运行目录: /fisco-bcos
```
$ sudo docker exec -it 4ad31c7794be /bin/bash
$ cd /fisco-bcos
$ ls 
$ init_web3_para.sh nodejs systemcontract web3lib node  start_node.sh  tool web3sdk
```
- init_web3_para.sh : 用来初始化docker中fisco-bcos相关环境.  
- nodejs : nodejs安装目录  
- systemcontract ： nodejs系统合约工具目录.  
- web3lib : nodejs公共文件目录.  
- node : fisco-bcos数据目录.
- start_node.sh ： fisco-bcos启动脚本,启动docker时被调用.  
- tool :  nodejs工具目录.  
- web3sdk : web3sdk目录  

进入tool目录：  
```
$ cd tool
$ babel-node deploy.js HelloWorld
deploy.js  ........................Start........................
Soc File :HelloWorld
HelloWorldcomplie success！
send transaction success: 0x500c20c58ce8440b18502e88c2d54a4830681a18cee8b13465c1ceb2af08ae11
HelloWorldcontract address 0x61dba250334e0fd5804c71e7cbe79eabecef8abe
HelloWorld deploy success!
cns add operation => cns_name = HelloWorld
         cns_name =>HelloWorld
         contract =>HelloWorld
         version  =>
         address  =>0x61dba250334e0fd5804c71e7cbe79eabecef8abe
         abi      =>[{"constant":false,"inputs":[{"name":"n","type":"string"}],"name":"set","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"get","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"}]
send transaction success: 0x2eedcea5886c8e5b9c60688f7d8aa910fc22868ed2ae0349e7a34be7c34a71fa
```

# <a name="specific_genesis_node_expand" id="specific_genesis_node_expand">附录1. 区块链扩容</a>

#### 使用场景  
对以前的已经在跑的区块链, 可以提供其创世节点的相关文件, 创建出一个非创世节点, 使其可以连接到这条区块链。
#### 1. 从创世节点所在服务器上拷贝下面的的3个文件，放到区块链安装包创建工具所在的机器：
  * genesis.json
  * bootstrapnodes.json : 创世节点的连接ip信息。
  * syaddress.txt : 系统合约的地址。  
- [x]   这几个文件位于创世节点的安装包的dependencies/follow目录。
- [x]   区块链安装包创建工具所在的服务器如果之前没有编译、安装FISCO BCOS时, 也可以把创世节点上的fisco-bcos文件拿下来，放入/usr/local/bin目录下.

#### 2. 从创世节点所在服务器上面取出dependencies/cert目录, 里面包含之前创建的区块链的根证书、机构证书信息, 放到构建区块链安装包创建工具所在的机器。

#### 3. 配置

配置需要扩容的节点的信息,这个配置文件在区块链安装创建工具的安装目录的根目录：
```sh
vim specific_genesis_node_scale_config.sh
```
假如将上述文件放入/fisco-bcos/ext/目录下,扩容的机器为127.0.0.1, 配置如下：

```shell
p2p_network_ip="***REMOVED***"
listen_network_ip="***REMOVED***"
node_number=2
agency_info="agent_3"

genesis_json_file_path=/fisco-bcos/ext/genesis.json
genesis_node_info_file_path=/fisco-bcos/ext/bootstrapnodes.json
genesis_system_address_file_path=/fisco-bcos/ext/syaddress.txt
genesis_ca_dir_path=/fisco-bcos/ext/cert/
```
配置解释：
- p2p_network_ip：   p2p连接的网段ip, 根据p2p网络的网段配置。
- listen_network_ip：   监听网段ip, 用来接收rpc、channel、ssl连接。
- node_number：   在该服务器上面需要创建的节点数目。 
- agency_info：   机构名称, 如果不区分机构, 值随意, 但是不可以为空。
- genesis_json_file_path   genesis.json的路径
- genesis_node_info_file_path   bootstrapnodes.json的路径
- genesis_system_address_file_path  syaddress.txt的路径
- genesis_ca_dir_path  链的证书目录
- 
#### 3. 生成安装包

```shell
$ ./generate_installation_packages.sh expand
```
生成的安装包在`build/`目录下
```
***REMOVED***_with_***REMOVED***_installation_package
```
#### 4. 安装启动节点
将安装包上传至服务器, 进入目录, 执行./intall_node.sh install  
进入build目录或者docker目录.
启动节点: ./start_all.sh  

#### 5. 添加新增节点到节点管理合约
将dependencies/node_action_info_dir的nodeactioninfo_xxxxxxxxxxxx.json文件, 放入创世节点所在服务器的安装目录的node_action_info_dir, 然后执行node_manager.sh命令将新添加的节点注册到管理合约。

# <a name="密钥管理" id="ca-manager">附录2. 秘钥管理</a>
#### 1. 默认的管理机制  
- FISCO-BCOS默认情况下使用自己的工具分配证书, 工具位于下载的FSICO-BCOS目录的cert子目录, 使用方式参考[FISCO-BCOS 证书生成工具](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual#第二章-准备链环境)。
#### 2. 物料包工具的证书分配.  
- 物料包工具的证书分配默认采用FISCO-BCOS的证书分配机制.  
- 构建完成各个服务器的安装包之后, 整条链的根证书、机构证书会保存在创世节点所在服务器的dependencies/cert目录, 以上面示例的配置为例,  创世节点服务器cert目录内容(省略了一些不重要的文件)：
```
ca.crt
ca.key
agent_0\
    agency.crt
    agency.key
agent_1\
    agency.crt
    agency.key
agent_2\
    agency.crt
    agency.key
```
- ca.crt 根证书
- ca.key 根证书私钥
- agent_0\agency.crt agent_0机构证书 
- agent_0\agency.key agent_0机构证书私钥
- agent_1\agency.crt agent_1机构证书 
- agent_1\agency.key agent_1机构证书私钥
- agent_2\agency.crt agent_2机构证书 
- agent_2\agency.key agent_2机构证书私钥

#### 3. 节点启动时依赖的文件   
```
ca.crt 根证书, x509格式
agency.crt 机构证书, x509格式
node.crt 节点证书, x509格式
node.key 节点私钥证书, pkcs#8格式
node.private 节点的私钥, pkcs#8解析的私钥
```
上述文件如何生成可以参考[FISCO-BCOS证书生成](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual#第二章-准备链环境)

#### 3. 物料包工具的证书拓展机制.  
物料包工具提供了一种拓展功能, 在各个机构或者是节点并不希望暴露私钥信息, 仅仅提供节点证书信息(证书是可以暴露的)的情况下进行构建安装包, 证书实现自分配或者其他方式.  
使用流程如下：
##### 3.1 启用功能  
配置installation_config.sh中IS_CA_EXT_MODE=1.  

##### 3.2 放置节点的证书文件  
将需要搭建的节点的证书以：结构名称/node_p2pnetworkip_IDX/node.crt方式放入到ext/cert目录.  
以示例中的配置为例：
```
ext/cert
        agent0
                node_***REMOVED***_0/node.crt
                node_***REMOVED***_1/node.crt
        agent1
                node_***REMOVED***_0/node.crt
                node_***REMOVED***_1/node.crt
        agent2
                node_***REMOVED***_0/node.crt
                node_***REMOVED***_1/node.crt
                    
```

##### 3.2 其他流程
其他的流程保持不变, 最后在启动节点之前需要将节点依赖的其他证书文件放入节点的数据目录, 然后再启动节点, 用户放置的node.crt会自动拷贝, 用户可以不用重新放置。 

# 相关链接  
- [FISCO BCOS WIKI](https://github.com/FISCO-BCOS/Wiki)  
- [一键安装FISCO BCOS脚本](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/sample)  
- [FISCO BCOS区块链操作手册](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual)


# FAQ

- 一定要确保安装的机器上面的各个节点的端口都没有被占用, 当前服务器上面的端口配置可以查看安装目录下的 build/nodedirN/config.json 文件, 可以使用 netstat -anp | egrep 端口号 , 查看端口是否被占用。
 	```sh
	    "rpcport":"8546",
        "p2pport":"30304",
        "channelPort":"8822",
	```

- 一定要确保各个机器之前可以连接, 端口是放开的, 可以通过ping检查各个机器之前的网络连接, 使用telnet检查端口是否开通。
- 如果构建安装包过程有出错，但不知道错误在哪里，可以这样执行构建脚本：

	```sh
	$ bash -x generate_installation_packages.sh build
	```
- 如果安装过程有出错，但不知道错误在哪里，可以这样安装脚本：

	```sh
	$ bash -x install_node.sh install
	```
	
- 执行启动脚本start_node0.sh后, ps -aux | egrep fisco发现进程不存在, 可以查看./build/nodedir0/log/log文件的内容, 里面会有具体的报错内容。  
常见的一些报错如下：  
a. 
```
terminate called after throwing an instance of 'boost::exception_detail::clone_impl<dev::eth::DatabaseAlreadyOpen>'
  what():  DatabaseAlreadyOpen  
```
进程已经启动, 使用ps -aux | egrep fisco-bcos查看。  

b.
```
./fisco-bcos: error while loading shared libraries: libleveldb.so.1: cannot open shared object file: No such file or directory 
```

leveldb动态库缺失, 安装脚本里面默认使用 yum/apt 对依赖组件进行安装, 可能是 yum/apt 源缺失该组件。  
可以使用下面命令手动安装leveldb, 若leveldb安装不成功可以尝试替换yum/apt的源。
```
[CentOS]sudo yum -y install leveldb-devel
[Ubuntu]sudo apt-get -y install libleveldb-dev

```  
c.
```
terminate called after throwing an instance of 'boost::exception_detail::clone_impl<dev::FileError>' what():  FileError
```

操作文件失败抛出异常, 原因可能是当前登录的用户没有安装包目录的权限, 可以通过ls -lt查看当前文件夹对应的user/group/other以及对应的权限, 一般可以将安装包的user改为当前用户或者切换登录用户为安装包的user用户即可。  