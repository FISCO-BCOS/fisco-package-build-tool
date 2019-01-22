#!/bin/bash
dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath
node=$(basename ${dirpath})
weth_pid=`ps aux|grep "${dirpath}/config.json"|grep "fisco-bcos"|grep -v grep|awk '{print $2}'`

if [ -z $weth_pid ];then
    echo " ${node} is not running."
    exit 0
fi

kill9_cmd="kill -9 ${weth_pid}"
if [[ "$1" == "--force" ]];then
    eval ${kill9_cmd}
    echo " ${kill9_cmd}, force kill fisco ."
    exit 0
fi

kill2_cmd="kill -2 ${weth_pid}"
try_times=10
i=0
while [ $i -lt ${try_times} ]
do
    eval ${kill2_cmd}
    sleep 1
    weth_pid=`ps aux|grep "${dirpath}/config.json"|grep "fisco-bcos"|grep -v grep|awk '{print $2}'`
    if [ -z $weth_pid ];then
        echo " stop ${node} success. "
        exit 0
    fi
    ((i=i+1))
done

echo " stop ${node} timeout, maybe stop failed, pid is ${weth_pid}. "