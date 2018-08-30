#!/bin/bash

#本脚本依靠一键脚本生成的start*.sh来监控服务，因此一键脚本的启动命令后续添加参数只能在尾部添加。
# nohup ./fisco-bcos  --genesis ./genesis.json  --config /home/ubuntu/weth/node0/config.json  > /home/ubuntu/weth/node0/log/log 2>&1 &

alarm() {
        echo "$1"
}

dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath
(
for configfile in `ls $dirpath/node*/config.json`
do
	config_ip=$(cat $configfile |grep -o '"listenip":".*"' | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+")
	config_port=$(cat $configfile |grep -o '"rpcport":".*"' | grep -o "[0-9]\+")
	configjs=$(ps aux | grep  "$configfile" |grep -v "grep"|awk -F " " '{print $15}')
	[ -z "$configjs" ] && {
        alarm "ERROR! $config_ip:$config_port does not exist"
		echo "start node $config_ip:$config_port"
        exit 1
    }
	#curl "http://10.135.0.55:8545" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":67}'
	#{"id":67,"jsonrpc":"2.0","result":"0x183ed"}
	heightresult=$(curl -s "http://$config_ip:$config_port" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":67}')
	height=$(echo $heightresult|awk -F'"' '{print $10}')
	[ -z "$height" ] &&  {
		alarm "ERROR! Cannot connect to $config_ip:$config_port" 
		exit 1
	}
	configdir=$(dirname $configfile)
	height_file="$configdir.height"
	prev_height=0
	[ -f $height_file ] && prev_height=$(cat $height_file)
	heightvalue=$(printf "%d\n" "$height")
    prev_heightvalue=$(printf "%d\n" "$prev_height")
	
	viewresult=$(curl -s "http://$config_ip:$config_port" -X POST --data '{"jsonrpc":"2.0","method":"eth_pbftView","params":[],"id":68}')
	view=$(echo $viewresult|awk -F'"' '{print $10}')
	[ -z "$view" ] &&  {
		alarm "ERROR! Cannot connect to $config_ip:$config_port" 
		exit 1
	}
	view_file="$configdir.view"
	prev_view=0
	[ -f $view_file ] && prev_view=$(cat $view_file)
	viewvalue=$(printf "%d\n" "$view")
    prev_viewvalue=$(printf "%d\n" "$prev_view")

	[  $heightvalue -eq  $prev_heightvalue ] && [ $viewvalue -eq  $prev_viewvalue ] && {
		alarm "ERROR! $config_ip:$config_port is not working properly: height $height and view $view no change" 
		exit 1
	}

	echo $height > $height_file
	echo $view > $view_file
	echo "OK! $config_ip:$config_port is working properly: height $height view $view" 
done) | while read line; do
        echo [$(date '+%F %T')]"$line"
done
