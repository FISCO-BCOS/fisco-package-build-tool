[TOC]

# 监控脚本monitor.sh

## 脚本介绍
使用物料包(**[fisco-package-build-tool](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/tools/index.html)**)搭建的FISCO-BCOS环境, 在build目录有个monitor.sh的脚本.  
用途如下：
1. 监控节点是否存活, 并且可以重新启动挂掉的节点.
2. 获取节点的块高和view信息, 判断节点共识是否正常.
3. 分析最近一分钟的节点日志打印, 收集日志关键错误打印信息, 准实时判断节点的状态.
4. 指定日志文件或者指定时间段, 分析节点的共识消息处理, 出块, 交易数量等信息, 判断节点的健康度. 

## 使用
```
Usage : bash monitor.sh 
          -m monitor | statistics. working mode, default : monitor .
          -f log_file : specified log file. 
          -d min_time : time range. default : 60(min), it should not longer than 60(min).
          -h : help. 
          example : 
                   bash  monitor.sh
                   bash  monitor.sh -m statistics -d 30
                   bash  monitor.sh -m statistics -f node0/log/log_2018120514.log
```
参数说明：  
-m : 指定monitor.sh的工作模式, 包括monitor和statistics两种模式：  
monitor模式检查节点是否存活、节点块高或者view切换是否正常、检查最近一分钟的日志有无关键错误打印.  
statistics模式对最近时间段的日志或者指定的日志文件进行分析, 对消息, 错误打印, 共识进行统计, 判断节点的工作状况.  
-f log_file：与 -m statistics 配合使用, 分析-f指定的日志文件.  
-d min_time：与 -m statistics 配合使用, 分析节点最近min_time时间点以内的日志.
### 节点状态
```
bash monitor.sh 
{"id":67,"jsonrpc":"2.0","result":"0x836"}
{"id":68,"jsonrpc":"2.0","result":"0x1928"}
[2018-12-27 16:59:50]  OK! 0.0.0.0:8545 is working properly: height 0x836 view 0x1928
[2018-12-27 16:59:50]  log parser min, 2018-12-27 16:58
```

```OK! $config_ip:$config_port is working properly: height $height view $view```    
节点正常启动, 并且共识模块正常工作。注意因为区块链有一定的容错能力, 共识正确不代表整个链完全正常工作, 不排除有其他的节点异常.

```ERROR! $config_ip:$config_port does not exist```    
节点进程不存在, 节点宕机, 会自动重启节点.

```ERROR! Cannot connect to $config_ip:$config_port```    
RPC请求失败, 节点宕机, 会自动重启节点.

```ERROR! $config_ip:$config_port is not working properly: height $height and view $view no change```  
节点正常启动, 但是节点块高、视图都没有变化, 共识异常, 需要运维人员查看与其他节点的连接是否正常。 一般情况是区块链中有节点挂掉或者网络无法连通, 导致共识无法工作.

```error[getLeader] nodes[$node0 $node1 ....$nodeN ], count=XXX```   
与节点node0, node1... nodeN节点断连, 需要检查对方节点是否正常启动, 以及节点之间的网络是否能够正常连通.

```error[Block Exec Slow], count=XXX```  
节点执行Block块的交易过慢, 运维人员注意查看机器的负载(CPU, IO, Mem).

```error[Block Commit Slow], count=XXX```  
节点执行Block块的交易过慢, 运维人员注意查看机器的负载(CPU, IO, Mem).

```error[TransactionQueue will OverFlow], count=XXX```  
交易队列累积的交易量过大, 业务层TPS过高或者是机器负载过大.

```error[Closing], count=XXX```  
与其他节点出现断连, 偶发出现属于正常, 节点可以自动重连, 频繁出现需要运维人员注意网络是否稳定. 

``` error[ChangeViewWarning] ```  
视图切换超时, 注意检查节点间的网络状况.

``` error[NETWORK] ```  
p2p发送过慢, 需要留意服务器的带宽以及负载.  

### 日志分析
- 最近N分钟日志(默认60min)
``` bash monitor.sh  -m statistics ```
- 指定日志文件
``` bash monitor.sh  -m statistics -f node0/log/log_2018122717.log ```
- **错误提示**   
``` ERROR! sealed blk not evenly distributed ```  
节点出块不均匀, 区块链节点挂掉或者底层bug会导致出块不均匀.

- **分析结果输出**  
以一个七个节点组成的区块链为例, 给个输出示例：
```
## log analyze result => 
  ==> blk count is 177   # 从日志中统计的出块数量
  ==> transaction count is 10260 # 日志中统计的执行交易量
  ==>> error message  # 错误信息打印, 包括error[getLeader] error[Block Exec Slow] error[Block Commit Slow] error[TransactionQueue will OverFlow] error[Closing] error[ChangeViewWarning] error[NETWORK]
  ==>> total view message # 从各个节点接受的handleView消息, from表示发送消息的节点索引
          from=1, count=2512
          from=2, count=1811
          from=3, count=2473
          from=4, count=2076
          from=5, count=2146
          from=6, count=2470
  ==>> direct view message # 从各个节点接受的直接发送的handleView消息
          from=1, count=2242
          from=2, count=1681
          from=3, count=2227
          from=4, count=1935
          from=5, count=1985
          from=6, count=2300
  ==>> forward view message # 从各个节点接受的转发的handleView消息
          from=1, count=270
          from=2, count=130
          from=3, count=246
          from=4, count=141
          from=5, count=161
          from=6, count=170
  ==>> total pre message  # 从各个节点接受的handlePre消息
          from=1, count=25
          from=2, count=26
          from=3, count=25
          from=4, count=26
          from=5, count=26
          from=6, count=22
  ==>> direct pre message # 从各个节点接受的直接发送的handlePre消息
          from=1, count=25
          from=2, count=26
          from=3, count=25
          from=4, count=26
          from=5, count=26
          from=6, count=22
  ==>> forward pre message # 从各个节点接受的转发的handlePre消息
  ==>> total sign message # 从各个节点接受的handleSign消息
          from=1, count=172
          from=2, count=177
          from=3, count=175
          from=4, count=176
          from=5, count=175
          from=6, count=175
  ==>> direct sign message # 从各个节点接受的直接发送的handleSign消息
          from=1, count=171
          from=2, count=175
          from=3, count=172
          from=4, count=171
          from=5, count=172
          from=6, count=171
  ==>> forward sign message #从各个节点接受的转发的handleSign消息
          from=1, count=1
          from=2, count=2
          from=3, count=3
          from=4, count=5
          from=5, count=3
          from=6, count=4
  ==>> total commit message #从各个节点接受的handleCommit消息
          from=1, count=177
          from=2, count=177
          from=3, count=177
          from=4, count=177
          from=5, count=177
          from=6, count=177
  ==>> direct commit message #从各个节点接受的直接发送的handleCommit消息
          from=1, count=144
          from=2, count=141
          from=3, count=156
          from=4, count=144
          from=5, count=148
          from=6, count=145
  ==>> forward commit message #从各个节点接受的转发的handleCommit消息
          from=1, count=33
          from=2, count=36
          from=3, count=21
          from=4, count=33
          from=5, count=29
          from=6, count=32
  ==>> report message #report打印统计, 各个节点的出块情况
          report, index=0, count=27
          report, index=1, count=25
          report, index=2, count=26
          report, index=3, count=25
          report, index=4, count=26
          report, index=5, count=26
          report, index=6, count=22
  ==>> pbft and seal time #pbft和seal的耗时情况
          # pbft_max_time is 167(ms), pbft_min_time is 5(ms) # 共识阶段消耗的最大时间与最小时间
          # seal_max_time is 237(ms), seal_min_time is 6(ms) # 出块消耗的最大时间与最小时间
          # pbft prepare count is 178 # handlePre消息数量
          # pbft sign count is 177 # handleSign消息数量
          # pbft commit count is 177 # handleCommit消息数量
          # pbft write block count is 177 # 写入block块数量
          # pbft_avg_time is 21(ms) # pbft共识平均耗时
          # seal_avg_time is 69(ms) # seal平均耗时
```

## 配置crontab  
为了能够持续监控节点的状态, 需要将monitor.sh配置到crontab定期执行.  
配置如下：
```
#每分钟查看节点是否正常启动, 正常共识, 有无关键错误打印
*/1  * * * * /data/app/fisco-bcos/build/monitor.sh >> /data/app/fisco-bcos/build/monitor.log 2>&1  
#每小时统计这段时间的消息处理, 出块, 交易信息
*/60  * * * * /data/app/fisco-bcos/build/monitor.sh -m statistics >> /data/app/fisco-bcos/build/monitor_s.log 2>&1
```

 用户在实际中需要将上面的路径修改为自己的实际路径。

## 对接告警系统    
monitor.sh中有个alarm函数, 内容如下：
```
alarm() {
        alert_ip=$(/sbin/ifconfig eth0 2>/dev/null | grep inet | awk '{print $2}')
        # time=`date "+%Y-%m-%d %H:%M:%S"`
        echo -e "\033[31m [$alert_ip] $1 \033[0m"
}
```
 monitor.sh脚本中检测到关键错误处都会调用该函数,  使用该函数将错误信息打印, 用户可以在该该函数中调用自己监控平台的API将错误信息作为参数发送至告警平台.
 
 - 对接案例：  
 假设用户的告警API为: http://127.0.0.1:1111/alarm/request
 POST参数为: {'title':'告警主题','alert_info':'告警内容'}
 则可以将alarm函数修改为：
```
  alarm() {
        alert_ip=$(/sbin/ifconfig eth0 2>/dev/null | grep inet | awk '{print $2}')
        echo -e "\033[31m [$alert_ip] $1 \033[0m"
        # 发送告警信息
        curl -H "Content-Type: application/json" -X POST --data "{'title':'fisco-bcos-alarm','alert_info':'$1'}" http://127.0.0.1:1111/alarm/request
}
```
 这样在fisco-bcos节点发生异常时可以通过自己的告警平台获知。
 