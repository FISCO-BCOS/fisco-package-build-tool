#!/bin/bash
dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath
node=$(basename ${dirpath})
weth_pid=`ps aux|grep "${dirpath}/config.json"|grep "fisco-bcos"|grep -v grep|awk '{print $2}'`

if [ ! -z $weth_pid ];then
    echo "$node is running."
else
    echo "$node is not running."
fi