#!/bin/bash
currentPWD=$PWD

rpc_line=`cat $currentPWD/node/config.json|grep "rpcport"|grep -v "grep"|awk -F " " '{print $1}'`
channel_line=`cat $currentPWD/node/config.json|grep "channelPort"|grep -v "grep"|awk -F " " '{print $1}'`
listen_line=`cat $currentPWD/node/config.json|grep "listenip"|grep -v "grep"|awk -F " " '{print $1}'`
system_ddress_line=`cat $currentPWD/node/config.json|grep "systemproxyaddress"|grep -v "grep"|awk -F " " '{print $1}'`
rpc_port=$(echo ${rpc_line} |grep -o '"rpcport":".*"' | grep -o "[0-9]\+")
channel_port=$(echo ${channel_line} |grep -o '"channelPort":".*"' | grep -o "[0-9]\+")
listen_ip=$(echo ${listen_line} |grep -o ':".*"' | grep -o "[0-9 .]\+")
system_ddress=$(echo ${system_ddress_line} |grep -o ':".*"' | grep -o "[a-z 0-9]\+")

#change default value
sed -i "s/http:\/\/127.0.0.1:8545/http:\/\/${listen_ip}:${rpc_port}/g"  $currentPWD/web3lib/config.js >/dev/null 2>&1
sed -i "s/0x919868496524eedc26dbb81915fa1547a20f8998/${system_ddress}/g"  $currentPWD/web3sdk/conf/applicationContext.xml >/dev/null 2>&1
sed -i "s/node1@127.0.0.1:8822/node1@${listen_ip}:${channel_port}/g"  $currentPWD/web3sdk/conf/applicationContext.xml >/dev/null 2>&1

cp $currentPWD/node/web3sdk_ca/* $currentPWD/web3sdk/conf/ >/dev/null 2>&1
echo -n ${system_ddress} > $currentPWD/systemcontract/output/SystemProxy.address

echo "listen ip = "${listen_ip}
echo "channel_port = "${channel_port}
echo "rpc_port = "${rpc_port}
echo "system_ddress = "${system_ddress}