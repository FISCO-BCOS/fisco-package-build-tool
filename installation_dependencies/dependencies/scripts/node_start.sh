#!/bin/bash

dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath
node=$(basename ${dirpath})
ulimit -c unlimited 2>/dev/null
weth_pid=`ps aux|grep "${dirpath}/config.json"|grep "fisco-bcos"|grep -v grep|awk '{print $2}'`
if [ ! -z $weth_pid ];then
    echo " ${node} is running, pid is $weth_pid."
else 
    echo " start ${node} ..."
    chmod a+x ../fisco-bcos
    nohup ../fisco-bcos  --genesis ${dirpath}/genesis.json  --config ${dirpath}/config.json  >> ${dirpath}/log/log 2>&1 &
fi

