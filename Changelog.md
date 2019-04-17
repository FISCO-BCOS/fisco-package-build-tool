### v1.0.0 (2018-03-27)  

1. 物料包生成工具初始递交。  
2. 添加fisco-solc的安装, 安装目录为/user/local/bin/。  
3. 解决非root用户执行安装时, 安装ethconsole失败的问题。 
4. 添加README.me文件。   
5. 将nodejs安装改为本地安装, 不再通过yum进行。 

### v1.1.0 (2018-05-29)  
* Update:  
1. 适配新的连接管理机制.  
2. 文档更新.  
3. 新的连接管理导致的证书管理机制修改, 每个节点证书在构建安装包过程中生成.  

### v1.1.1 (2018-07-09)
* Update
1. 适配FISCO-BCOS v1.3.1版本。
2. 构建过程中, 生成god账号过程使用fisco-bcos --newaccount命令, 不再使用nodejs命令, 加快生成速度。

### v1.2.0 (2018-07-04) 
* Update:
1. 支持构建docker环境的搭建. 
2. 增强容错性, 出错的情况下直接退出. 
3. 配置文件格式修改为config.ini. 
3. 添加fisco_bcos_version配置, 用来配置需要部署的fisco-bcos版本, 如果本地版本不符合则重新拉取代码编译更新.  
4. 简化搭建环境的步骤, 构建新链时, 所有记账节点均被注册到节点管理合约, 可以省略注册流程, 扩容或者观察节点需要转换为记账节点时才需将新节点信息注册到节点管理合约. 
5. 添加docker_toggle、docker_repository、docker_version、ca_ext配置, 作用请参考使用手册. 
6. 删除crypto mode、super key这几个配置：crypto mode用来标记落盘加密, 这个在后续中会添加用户指引如何使用该功能. 
7. 添加操作系统版本的校验, 目前支持的操作版本为CentOS 7.2+ 、Ubuntu 16.04 、Oracle Linux Server 7.4+.
7. JDK的依赖版本由JDK 1.8改为OracleJDK 1.8, 内附下载地址.  
8. 添加openssl版本的检测.
9. 扩容流程支持多台一起扩容.
10. 创世块节点的bootstrapnodes.json中不再添加自己的p2p链接信息.  
11. 添加更多的依赖检测, 遇到脚本停止工作.  
12. nodejs的依赖、fisco-solc改为内置, 不再下载.  
13. 调整目录结构.

### v1.2.1 (2018-10-10)
* Update:
1. 添加节点监控工具monitor.sh.
2. 添加日志清理工具rmlogs.sh.
3. 修改README.md中的链接路径.
4. 节点nodeIDX目录下的start.sh, check.sh, stop.sh只能在上级build目录执行的bug fix.
5. start.sh中添加ulimit -c unlimited, 打开生成core的开关.
6. 其他问题的纠正.

### v1.2.2 (2018-12-03)
* Update:
1. 构建区块链时, 将所有的节点的p2p连接ip、port信息写入bootstrapnodes.json文件.  
2. 扩容时, 将新添加的节点的链接信息写入bootstrapnodes.json文件.  
3. 扩容时, 添加检查config.ini中genesis_follow_dir配置的文件夹是否存在, 同时添加$genesis_follow_dir/cert、$genesis_follow_dir/bootstapnodes.json、$genesis_follow_dir/genesis.json、$genesis_follow_dir/syaddress.txt是否存在.

### v1.2.3 (2019-01-08)  
* Fix:  
1. 扩容生成的bootstrapnodes.json文件格式错误bug修正.  

* Update:
1. 更新监控脚本monitor.sh的功能.
2. 同步FISCO-BCOS/systemcontract目录修改: 删除FileInfoManager.sol FileServerManager.sol文件; compile.js文件中删除FileInfoManager.sol FileServerManager.sol ConsensusControl.sol ContractA.sol Authority.sol的编译; deploy.js中删除对FileInfoManager.sol FileServerManager.sol的部署;
3. monitor.js适配FISCO 1.3.7新接口.  
4. tool.js将十六进制显示修改为十进制.  
5. config.ini版本号修改为v1.3.7.

### v1.2.4 (2019-04-17)  
* Update:
1. 更新config.ini中fisco-bcos默认版本号为1.3.8.
2. build/expand时支持通过-p参数指定使用的fisco-bcos路径,或者通过-d参数从GitHub下载对应fisco-bcos版本.
3. stop.sh脚本添加超时重试机制.