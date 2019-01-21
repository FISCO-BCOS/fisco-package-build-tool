#!/bin/bash
currentPWD=/fisco-bcos/

cp $currentPWD/node/ext/node/* $currentPWD/node/data/ >/dev/null 2>&1
cp $currentPWD/node/ext/sdk/* $currentPWD/web3sdk/conf/ >/dev/null 2>&1
cp $currentPWD/node/ext/conf/syaddress.txt $currentPWD/systemcontract/output/SystemProxy.address >/dev/null 2>&1
cp $currentPWD/node/ext/conf/applicationContext.xml $currentPWD/web3sdk/conf/ >/dev/null 2>&1
cp $currentPWD/node/ext/conf/config.js $currentPWD/web3lib/ >/dev/null 2>&1
#cp $currentPWD/node/ext/fisco-bcos/* /usr/bin/ >/dev/null 2>&1
#chmod a+x /usr/bin/fisco-bcos

#echo "system_address => "$(cat $currentPWD/node/ext/conf/syaddress.txt)
