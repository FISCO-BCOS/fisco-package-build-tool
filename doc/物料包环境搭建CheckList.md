# 物料包环境搭建准备阶段CheckList
使用物料包搭建FISCO-BCOS时, 为减少搭建过程中遇到的问题, 建议在使用fisco-package-build-tool之前对整个搭建的环境有个前置的检查, 特别是生产环境的搭建, 尤其推荐CheckList作为一个必备的流程。  
## 检查的内容包含以下项：  
### **操作系统**  
支持操作系统:  
CentOS 7.2 64位  
Ubuntu 16.04 64位

- 检查系统是否为64位系统：  
使用**uname -m**命令, 64位系统的输出为x86_64, 32位系统的输出为i386或者i686.
```
$ uname -m
$ x86_64
```

- 操作系统版本检查：
```
CentOS
$ cat /etc/redhat-release 
$ CentOS Linux release 7.2.1511 (Core)

Ubuntu
$ cat /etc/os-release
$ NAME="Ubuntu"
$ VERSION="16.04.1 LTS (Xenial Xerus)"
$ ID=ubuntu
$ ID_LIKE=debian
$ PRETTY_NAME="Ubuntu 16.04.1 LTS"
$ VERSION_ID="16.04"
$ HOME_URL="http://www.ubuntu.com/"
$ SUPPORT_URL="http://help.ubuntu.com/"
$ BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
```

### **网络**
### **java环境**  
#### 1. 版本检查
FISCO BCOS需求版本Oracle JDK 1.8(java 1.8)
- [x] CentOS/Ubuntu默认安装或者通过yum/apt安装的JDK为openJDK, 并不符合使用的要求.  
- [x] 可以通过java -version查看版本, Oracle JDK输出包含\"Java(TM) SE\"字样, OpenJDK输出包含\"OpenJDK\"的字样, 很容易区分。  
```
Oracle JDK 输出：
$ java -version
$ java version "1.8.0_144"
$ Java(TM) SE Runtime Environment (build 1.8.0_144-b01)
$ Java HotSpot(TM) 64-Bit Server VM (build 25.144-b01, mixed mode)

OpenJDK 输出：
$ java -version
$ openjdk version "1.8.0_171"
$ OpenJDK Runtime Environment (build 1.8.0_171-b10)
$ OpenJDK 64-Bit Server VM (build 25.171-b10, mixed mode)
```

#### 2. 安装
当前系统如果没有安装JDK, 或者JDK的版本不符合预期, 可以参考[[Oracle JAVA 1.8 安装教程]](https://github.com/ywy2090/fisco-package-build-tool/blob/docker/doc/Oracle%20JAVA%201.8%20%E5%AE%89%E8%A3%85%E6%95%99%E7%A8%8B.md)。

### ***openssl版本***
openssl需求版本为1.0.2, 可以使用 openssl version 查看.
```
$ openssl version
$ OpenSSL 1.0.2k-fips  26 Jan 2017
```

服务器如果没有安装openssl, 可以使用yum/apt进行安装.
```
sudo yum -y install openssl
```

### ***yum/apt源检查***  
物料包工作过程中会使用yum/apt安装一些依赖项, 如果当前的yum/apt不存在依赖时, 工作过程会出现问题.  
```
CentOS 依赖
        sudo yum -y install bc
        sudo yum -y install gettext
        sudo yum -y install cmake3
        sudo yum -y install git gcc-c++
        sudo yum -y install openssl openssl-devel
        sudo yum -y install boost-devel leveldb-devel curl-devel 
        sudo yum -y install libmicrohttpd-devel gmp-devel 
        sudo yum -y install lsof

Ubuntu 依赖
        sudo apt-get -y install gettext
        sudo apt-get -y install bc
        sudo apt-get -y install cmake
        sudo apt-get -y install git
        sudo apt-get -y install openssl
        sudo apt-get -y install build-essential libboost-all-dev
        sudo apt-get -y install libcurl4-openssl-dev libgmp-dev
        sudo apt-get -y install libleveldb-dev  libmicrohttpd-dev
        sudo apt-get -y install libminiupnpc-dev
        sudo apt-get -y install libssl-dev libkrb5-dev
        sudo apt-get -y install lsof

```