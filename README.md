[toc]
<center> <h1>FISCO BCOS安装包创建工具使用指南</h1> </center>


# 1. 背景介绍
* 本工具的主要功能：通过脚本实现一键搭建FISCO BCOS, 减少FISCO BCOS的搭建难度, 缩减繁琐的配置流程。
* 使用本工具, 进行一些简单配置后, 可以创建区块链节点的安装包。例如：如果配置了3台服务器每台启动3个区块链节点, 则将生成3个安装包, 分别对应3台服务器, 将安装包上传到对应的服务器上, 继续按照指引安装, 就可以在每台机器上启动区块链节点, 并组成一个区块链网络。

# 2. 术语  
* 区块链有两种节点：创世节点, 非创世节点。
* 创世节点：配置文件配置的第一台服务器上的第一个节点为创世节点, 这个节点是第一个加入节点管理合约的节点，所以需要作为第一个节点启动，当有新的节点有加入组网的请求，需要通过该节点，把新节点信息写入到节点管理合约。(参考FISCO-BCOS系统合约介绍[[节点管理合约]](https://github.com/FISCO-BCOS/Wiki/tree/master/FISCO-BCOS%E7%B3%BB%E7%BB%9F%E5%90%88%E7%BA%A6%E4%BB%8B%E7%BB%8D#%E8%8A%82%E7%82%B9%E7%AE%A1%E7%90%86%E5%90%88%E7%BA%A6))。
* 非创世节点：除去创世节点的区块链的其它节点。

# 3. 工具提供的功能
- [x] 从零开始搭建区块链：可以搭建出一条区块链的所有节点的安装包。
  * 步骤见( [5. 从零开始搭建区块链步骤](#buildblockchain) )
- [x] 从零开始搭建区块链后, 创建出所有节点的安装包后, 又需要对这条区块链进行扩容, 生成扩容节点的安装包。
  * 步骤见( [附录一：区块链扩容节点](#expand_node) )
- [x] 指定给定的创世节点的相关文件，生成非创世节点的安装包。对以前的已经在跑的区块链, 可以提供其创世节点的相关文件, 创建出非创世节点, 使其可以连接到这条区块链。
  * 步骤见( [附录二：指定给定的创世节点,扩容节点](#specific_genesis_node_expand) )

# 4. 安装依赖  
- [x]    机器配置  

   参考FISCO BCOS区块链操作手册：[[机器配置]](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual#11-机器配置)  
  
- [x]    软件依赖  

```shell
git 
dos2unix 
lsof 
java[1.8+]

[CentOS Install]
sudo yum -y install git 
sudo yum -y install dos2unix
sudo yum -y install java 
sudo yum -y install lsof

[Ubuntu Install]
sudo apt install git
sudo apt install lsof
sudo apt install openjdk-8-jre-headless
sudo apt install tofrodos
ln -s /usr/bin/todos /usr/bin/unix2dos 
ln -s /usr/bin/fromdos /usr/bin/dos2unix 
```

- [x]    其他依赖  
  sudo权限, 需要当前执行的用户具有sudo权限

# 5. <a name="buildblockchain" id="buildblockchain">从零开始搭建区块链步骤</a>
#### 5.1 准备
* 获取fisco-package-build-tool工具包  
git clone https://github.com/FISCO-BCOS/fisco-package-build-tool.git  
然后执行下面命令:  
```shell
chmod a+x format.sh ; dos2unix format.sh ; ./format.sh
```

#### 5.2 配置新建区块链的节点信息

```shell
$ cd fisco-package-build-tool
$ vim installation_config.sh
```

下面以在三台服务器上分别启动两个节点为例子，参考配置如下：

```
#github path for FISCO BCOS
FISCO_BCOS_GIT="https://github.com/FISCO-BCOS/FISCO-BCOS.git"
#local FISCO BCOS path, if FICSO BSOC is not exist in the path, pull it from the github.
FISCO_BCOS_LOCAL_PATH="../"

# default config for temp block node, if the port already exist, please change the following config.
P2P_PORT_FOR_TEMP_NODE=30303
RPC_PORT_FOR_TEMP_NODE=8545
CHANNEL_PORT_FOR_TEMP_NODE=8821
RPC_SSL_PORT_FOR_TEMP_NODE=18545

# config for the blockchain node
# the first node is the genesis node
# field 0 : p2p_network_ip
# field 1 : listen_network_ip
# field 2 : node number on this host
# field 3 : identity type
# field 4 : crypto mode
# field 5 : ssl 
# field 6 : super key
# filed 7 : agency info

weth_host_0=("172.20.245.42" "0.0.0.0" "2" "1" "1" "0" "d4f2ba36f0434c0a8c1d01b9df1c2bce" "agent_0")
weth_host_1=("172.20.245.43" "0.0.0.0" "2" "1" "1" "0" "d4f2ba36f0434c0a8c1d01b9df1c2bce" "agent_1")
weth_host_2=("172.20.245.44" "0.0.0.0" "2" "1" "1" "0" "d4f2ba36f0434c0a8c1d01b9df1c2bce" "agent_2")

MAIN_ARRAY=(
weth_host_0[@]
weth_host_1[@]
weth_host_2[@]
)
```

**配置项：**
* FISCO_BCOS_GIT  
  获取FISCO-BCOS的github路径,也可以不填写,默认从https://github.com/FISCO-BCOS/FISCO-BCOS.git获取。 
* FISCO_BCOS_LOCAL_PATH  
  本地的FISCO-BCOS所在的目录, 如果该目录下存在FISCO-BCOS目录, 则不会从github上面重新拉取FISCO-BCOS。**目前国内的github获取速度比较慢, 所以建议大家可以将FISCO-BCOS下载下来之后, 直接放入FISCO_BCOS_LOCAL_PATH目录**。
* P2P\_PORT\_FOR\_TEMP\_NODE  
  RPC\_PORT\_FOR\_TEMP_NODE  
  CHANNEL\_PORT\_FOR\_TEMP\_NODE  
  RPC\_SSL\_PORT\_FOR\_TEMP\_NODE  
  在构建安装包时, 会启动一个临时的temp节点(详见配置说明 1), 用来进行系统合约的部署, 创世节点信息的添加。这几个配置端口分别表示: p2p端口、rpc端口、  channel端口、ssl端口, 是启动的temp节点需要用到的临时端口, <span style="color:red">一般不需要改动, 但是要确保这些端口不要被占用</span>。
* weth\_host\_n是第n台服务器的配置。  
* field 0(p2p_network_ip)： p2p连接的网段ip, 根据p2p网络的网段配置。
* field 1(listen_network_ip)： 监听网段, 用来接收rpc、channel、ssl连接请求, 建议配置为"0.0.0.0"。
* field 2(node number on this host)：在该服务器上面需要创建的节点数目。  
* field 3(identity type)：节点类型, "1"：记账节点,  "0"：观察节点 。 
* field 4(crypto mode)： 落盘加密开关: "0":关闭,  "1":开启。  
* field 5(ssl)：节点之间连接是否使用ssl连接, "0":关闭 , "1":开启。
* field 6(super key)： 落盘加密的秘钥, 一般情况不用修改。  
* field 7(agency info)： 机构名称, 如果不需要区分机构时,值随意。  
比如：weth_host_0=("172.20.245.42" "0.0.0.0" "2" "1" "1" "null" "d4f2ba36f0434c0a8c1d01b9df1c2bce" "agent_0") 是第一台服务器上面的配置, 说明需要在172.20.245.42这台服务器上面启动两个节点。

**配置说明：**  
1. 工具在构建安装包(非扩容流程)过程中会启动一个temp节点, 用于系统合约的部署, 注册创世节点信息到节点管理合约, 生成genesis.json文件。  
2. 每个节点需要占用四个端口:p2p port、rpc port、channel port、ssl port, 对于单台服务器上的节点端口使用规则, 默认从temp节点的端口+1开始, 依次增长。例如temp节点的端口配置为了p2p port 30303、rpc port 8545、channel port 8821、ssl port 18821, 则每台服务器上的第0个节点默认使用p2p port 30304、rpc port 8546、channel port 8822、ssl port 18822端口，第1个节点默认使用p2p port 30305、rpc port 8547、channel port 8823、ssl port 18823, 以此类推, 要确保这些端口没有被占用。  
3. 工具构建安装包过程中会涉及到从github上面拉取FISCO BCOS、编译FISCO BCOS流程, 具体规则如下：  
  a、首先检查/usr/local/bin目录下是否存在fisco-bcos文件,  若存在则说明fisco-bcos已经被编译安装, 不存在则继续流程b 。   
  b、判断配置文件中FISCO_BCOS_LOCAL_PATH的路径是否存在名为FISCO-BCOS的文件夹, 存在则说明FISCO-BCOS源码已经存在, 直接进入FISCO-BCOS目录进行编译、安装流程, 否则进行流程c。  
  c、从FISCO_BCOS_GIT配置的github地址拉取FISCO-BCOS源码, 拉取完成之后进入FISCO-BCOS目录, 进行FISCO BCOS的编译安装流程。  

#### 5.3 创建安装包

```sh
$ ./generate_installation_packages.sh build
```

* 执行完脚本以后在当前目录会自动生成**build**目录, 在build目录下生成每台机器的安装包, 其中带有**genesis**字样的为创世节点所在服务器的安装包。  
按照示例配置, 会生成下面的四个文件：
```
ls build/
172.20.245.44_with_0.0.0.0_installation_package
172.20.245.43_with_0.0.0.0_installation_package
172.20.245.42_with_0.0.0.0_genesis_installation_package
temp
```
其中temp目录为临时节点的目录,不需要关心, 其余的几个包分别为对应服务器上节点的安装包。  
安装包的目录结构：

```shell
创世节点所在安装包目录内容：
dependencies  fisco-bcos  install_node.sh  node_action_info_dir  node_manager.sh  

非创世节点安装包目录内容：
dependencies  fisco-bcos  install_node.sh   
```
创世节点跟非创世节点相比多了node_manager.sh脚本跟node_action_info_dir目录。  
* node_manager.sh用来执行节点信息注册、取消、查询功能, 即操作节点管理合约。  
* node_action_info_dir目录保存了本次创建的所有节点的信息(包括创世节点与非创世节点)。按照示例中的配置node_action_info_dir目录下的内容为:  
```shell
nodeactioninfo_172.20.245.42_0.json  nodeactioninfo_172.20.245.42_1.json 
nodeactioninfo_172.20.245.43_0.json  nodeactioninfo_172.20.245.43_1.json 
nodeactioninfo_172.20.245.44_0.json  nodeactioninfo_172.20.245.44_1.json 
```
* 节点信息文件名的格式为nodeactioninfo_IP_IDX, IDX从0开始, 表示该服务器生成的第几个节点。

* install_node.sh脚本用来生成本机的数据目录、启动、停止脚本, 每个目录下都存在。

**注意**：
- [x]  1. 执行./generate_installation_packages.sh build如果出错, 解决问题重新执行之前, 需要将错误执行生成的build目录删除, 才能重新执行。
- [x]  2. 生成的安装包最好不要部署在build目录内, 部署在build目录时, 启动的fisco-bcos进程也会在build目录下启动, 会导致build目录无法删除, 下次想重新生成其他安装包时会有问题。

#### 5.4 上传安装包  
将安装包上传到对应的服务器, 注意上传的安装包必须与服务器相对应, 否则搭链过程会出错。

# <a name="deploy_genesis_host_node" id="deploy_genesis_host_node">6. 部署节点</a>
#### 6.1 准备
* 需要先部署创世节点的安装包，再部署非创世节点的安装包。
* 创世节点和非创世节点的部署步骤完全一致。只是非创世节点需要多做一步“添加节点”的操作(参考FISCO-BCOS使用手册[[多节点组网]](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual#第六章-多节点组网))。

#### 6.2 执行安装脚本

进入安装目录, 执行
```sh
$ ./install_node.sh install
```

执行完脚本以后会在当前目录自动生成： 
* build目录
* 启动脚本start_nodeN.sh：服务器上面配置生成多少个节点, 就会生成多少个启动脚本, N从0开始。
* 停止脚本stop_nodeN.sh：服务器上面配置生成多少个节点, 就会生成多少个停止脚本, N从0开始。  
上面配置的172.20.245.42服务器执行./install_node install后目录如下：
```
build         fisco-bcos       monitor.sh            node_manager.sh  start_node1.sh  stop_node0.sh
dependencies  install_node.sh  node_action_info_dir  start_node0.sh   stop_node1.sh
```

#### 6.3 启动节点

```sh
$ ./start_nodeN.sh
```
* 启动第N个节点, 启动后可以使用```ps -ef|egrep fisco-bcos```查看进程是否存在
* 如果需要停止这台机器上的对应节点，可以运行同一个目录下的```
./stop_nodeN.sh```

#### 6.4 添加节点到节点管理合约

节点组网
* 添加节点的操作只能在创世节点所在的服务器的安装目录进行，所有节点信息文件都会自动保存到<span style="color:red">创世节点安装目录根目录下的`node_action_info_dir`</span>目录。  
 以上述示例中的配置为例, 创世节点所在的
  `node_action_info_dir`中的内容如下：
  
```
$ ls
nodeactioninfo_172_20_245_42_0.json  nodeactioninfo_172_20_245_43_0.json  nodeactioninfo_172_20_245_44_0.json
nodeactioninfo_172_20_245_42_1.json  nodeactioninfo_172_20_245_43_1.json  nodeactioninfo_172_20_245_44_1.json
```

  使用`node_manager.sh`脚本进行添加  
  例如,如果需要添加这台服务器上的第0个节点：

  ```sh
  $ ./node_manager.sh registerNode `pwd`/node_action_info_dir/nodeactioninfo_172_20_245_42_0.json 
    ===================================================================
    node.json=file:/root/test/node_action_info_dir/nodeactioninfo_172_20_245_42_0.json
    NodeIdsLength= 1
    ----------node 0---------
    id=d418e60ebc87c1b982e8571b46367a3f99bc798f942bc36bfa558db481111aaee3b463d13594758384b6407520b43ce9e7e95dd01cd40da08b85ff4277c447ae
    ip=172.20.245.42
    port=30304
    category=1
    desc=172.20.245.42_0
    CAhash=
    agencyinfo=agent_0
    blocknumber=1
    Idx=0
  ```

* 每个节点的节点信息文件的文件名都包含了ip信息和index信息, 用于区分, 例如`nodeactioninfo_172_20_245_42_0.json`, 最后的那个"0"字符就是表示这是172_20_245_42这台服务器上面的第0个节点node0的节点信息文件。
* 建议每个节点在启动之后, 然后再执行node_manager.sh进行添加。 

验证  
    每注册一个节点可以在对应服务器的安装目录下执行：
```shell
tail -f build/nodedir0/log/info*log | egrep "Generating seal"
INFO|2018-04-03 14:16:42:588|+++++++++++++++++++++++++++ Generating seal on8e5add00c337398ac5e9058432037aa646c20fb0d1d0fb7ddb4c6092c9d654fe#1tx:0,maxtx:1000,tq.num=0time:1522736202588
INFO|2018-04-03 14:16:43:595|+++++++++++++++++++++++++++ Generating seal ona98781aaa737b483c0eb24e845d7f352a943b9a5de77491c0cb6fd212c2fa7a4#1tx:0,maxtx:1000,tq.num=0time:1522736203595
```
    可看到周期性的出现上面的日志，表示节点间在周期性的进行共识，节点注册正常。

#### 6.5 重新登录  
每个安装服务器都会安装nodejs、babel-node、ethconsole, 环境变量写入当前安装用户的.bashrc文件, 需要使用这些工具需要重新退出当前登录用户, 重新登录一次。

#### 6.6 部署成功
可以通过发送交易是否成功判断链是否搭建成功。 
在创世节点安装根目录下执行 ：  
cd dependencies/web3lib/  
npm install  
cd ../../dependencies/tool  
npm install  
然后测试合约部署是否正常： 
babel-node deploy.js Ok  

```
babel-node deploy.js Ok
RPC=http://0.0.0.0:8546
Ouputpath=./output/
deploy.js  ........................Start........................
Soc File :Ok
Ok
Ok编译成功！
发送交易成功: 0x30cbf34f57386c3d435dcdb4b15e03e6370f52eecef307664eed16fd806dd4d9
Ok合约地址 0xa40c864c28ee8b07dc2eeab4711e3161fc87e1e2
Ok部署成功！
cns add operation => cns_name = Ok
         cns_name =>Ok
         contract =>Ok
         version  =>
         address  =>0xa40c864c28ee8b07dc2eeab4711e3161fc87e1e2
         abi      =>[{"constant":false,"inputs":[{"name":"num","type":"uint256"}],"name":"trans","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"get","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"}]
===>> namecall params = {"contract":"ContractAbiMgr","func":"addAbi","version":"","params":["Ok","Ok","","[{\"constant\":false,\"inputs\":[{\"name\":\"num\",\"type\":\"uint256\"}],\"name\":\"trans\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"get\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"}]","0xa40c864c28ee8b07dc2eeab4711e3161fc87e1e2"]}
发送交易成功: 0x268daabbf8591c4ee93c59ea0e881b6dcdf56316ebae5f4078279f6859c39ffb
```




# <a name="expand_node" id="expand_node">附录1. 区块链扩容节点</a>
使用场景： build出所有节点的安装包后, 又需要在新添加的机器上面进行扩容, 生成扩容节点的安装包。**这种场景只适合扩容的节点在新的机器上**, 这个时候只需要在原来配置的基础上增加相应的机器的配置，然后重新执行一次下面的命令，扩容的安装包就生成好了, 然后将生成的安装包上传至对应服务器, 然后按照非创世节点的安装包的部署方式进行部署[参考章节：6.部署节点](#deploy_genesis_host_node)。
```sh
$ ./generate_installation_packages.sh build
```
* 注意：这种方式要保证之前的构建环境存在, build生成的目录没有被修改破坏。

# <a name="specific_genesis_node_expand" id="specific_genesis_node_expand">附录2. 指定给定的创世节点,扩容节点</a>

#### 使用场景  
对以前的已经在跑的区块链, 可以提供其创世节点的相关文件, 创建出一个非创世节点, 使其可以连接到这条区块链。
#### 1. 从创世节点的机器上拷贝下面的的3个文件，放到区块链安装包创建工具所在的机器：
  * genesis.json
  * genesis_node_info.json : 创世节点的节点信息文件的json。
  * syaddress.txt : 系统合约的地址。  
- [x]   这几个文件位于创世节点所在机器的安装目录下的dependencies子目录。
- [x]   区块链安装包创建工具所在的服务器如果之前没有编译、安装FISCO BCOS时, 也可以把创世节点上的fisco-bcos文件拿下来，放入/usr/local/bin目录下, 这样就可以不用重新编译FISCO BCOS.

#### 2.配置

配置需要扩容的节点的信息,这个配置文件在区块链安装包创建工具的安装目录的根目录：
```sh
vim specific_genesis_node_scale_config.sh
```
参考的demo配置如下：

```shell
external_ip="127.0.0.1"
internal_ip="127.0.0.1"
node_number=2
identity_type=1
crypto_mode=0
ssl="0"
super_key="d4f2ba36f0434c0a8c1d01b9df1c2bce"
agency_info="agent_test"

genesis_json_file_path=/fisco-bcos/fisco-package-build-tool/build/test/dependencies/genesis.json
genesis_node_info_file_path=/fisco-bcos/fisco-package-build-tool/build/test/dependencies/genesis_node_info.json
genesis_system_address_file_path=/fisco-bcos/fisco-package-build-tool/build/test/dependencies/syaddress.txt

```
配置解释：
* external_ip：   p2p连接的网段ip, 根据p2p网络的网段配置。
* internal_ip：   监听网段ip, 用来接收rpc、channel、ssl连接请求, 建议配置为"0.0.0.0"。
* node_number：   在该服务器上面需要创建的节点数目。  
* identity_type： 节点类型, "1"：记账节点,  "0"：观察节点。 
* crypto_mode：   落盘加密开关: "0":关闭,  "1":开启。  
* ssl：           是否使用ssl连接, "0":关闭 "1"开启。
* super_key：     落盘加密的秘钥, 一般情况不用修改。
* agency_info：   机构名称, 如果不区分机构, 值随意。
  
* genesis_json_file_path   genesis.json的路径
* genesis_node_info.json   genesis_node_info.json的路径
* syaddress.txt            syaddress.txt的路径

#### 3. 生成安装包

```shell
$ ./generate_installation_packages.sh expand
```
生成的安装包在`build/`目录下

#### 4. 安装启动节点
将安装包上传至服务器, 进入目录, 执行./intall_node.sh install  
依次执行 ./start_nodeN.sh启动节点  
可以通过 ps -aux | egrep fisco-bcos查看节点是否正常启动

#### 5. 添加新增节点到节点管理合约
将新节点的安装目录下dependencies/node_action_info_dir的nodeactioninfo_xxxxxxxxxxxx.json文件, 放入创世节点所在服务器的安装目录的node_action_info_dir, 然后执行node_manager.sh命令将新添加的节点注册到管理合约。

# 相关链接  
- [FISCO BCOS WIKI](https://github.com/FISCO-BCOS/Wiki)  
- [一键安装FISCO BCOS脚本](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/sample)  
- [FISCO BCOS区块链操作手册](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual)

# FAQ

- 一定要确保安装的机器上面的各个节点的端口都没有被占用, 当前服务器上面的端口配置可以查看安装目录下的 build/nodedirN/config.json 文件。
 	```sh
	    "rpcport":"8546",
        "p2pport":"30304",
        "rpcsslport":"18546",
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
	
- 如果执行启动脚本start_node0.sh后，ps发现进程不存在, 可以查看./build/nodedir0/log/log文件的内容, 查看是什么报错。
