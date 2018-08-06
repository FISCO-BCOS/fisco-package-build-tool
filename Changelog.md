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

### V1.1.1 (2018-07-09)
* Update
1. 适配FISCO-BCOS v1.3.1版本。
2. 构建过程中, 生成god账号过程使用fisco-bcos --newaccount命令, 不再使用nodejs命令, 加快生成速度。

### V1.1.2 (2018-08-02)
* Update:  
1. 添加vim-common的安装, 解决xxd未安装生成私钥为空问题.  
2. applicationContext.xml中connoctSeconds字段默认值修改为100, 之前偶发的web3sdk无法连接到节点.  
3. 同步FISCO BCOS主目录tool、systemcontract、web3lib下面的修改.  
4. README.md更新.
