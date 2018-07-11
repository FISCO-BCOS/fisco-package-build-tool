### V1.0.0 (2018-03-27)  

1. 物料包生成工具初始递交。  
2. 添加fisco-solc的安装, 安装目录为/user/local/bin/。  
3. 解决非root用户执行安装时, 安装ethconsole失败的问题。 
4. 添加README.me文件。   
5. 将nodejs安装改为本地安装, 不再通过yum进行。 

### V1.1.0 (2018-05-29)  
* Update:  
1. 适配新的连接管理机制.  
2. 文档更新.  
3. 新的连接管理导致的证书管理机制修改, 每个节点证书在构建安装包过程中生成.  

### V1.2.0 (2018-07-04) 
* Update:
1. 支持构建docker环境的搭建. 
2. 提供CA证书拓展机制, 可以不再使用FISCO-BCOS的内置证书分配机制. 
3. 简化搭建环境的步骤, 构建新链时, 所有节点均被注册到节点管理合约, 可以省略注册流程, 扩容时才需将新节点信息注册到节点管理合约. 
4. installation_config.sh中添加IS_BUILD_FOR_DOCKER、DOCKER_REPOSITORY、DOCKER_VERSION、IS_CA_EXT_MODE配置, 作用请参考使用手册. 
5. 删除identity type、crypto mode、super key这几个配置. 
identity type用来标记是否是出块节点, 在新版本中, 注册到管理合约的节点默认都是出块节点, 能够使用有效证书接入的节点都是观察节点(只同步块数据, 不出块). 
crypto mode用来标记落盘加密, 这个在后续中会添加用户指引如何使用该功能. 
6. 减少过程中不必要的nodejs环境搭建, 加快构建流程. 比如： 创建god账号信息使用fisco-bcos --newaccount内置的命令, 不再使用nodejs工具.
7. JDK的依赖版本由JDK 1.8改为OracleJDK 1.8, 内附下载地址.  
8. 添加openssl版本的检测.
9. 添加expand流程jdk、openssl版本的检测.