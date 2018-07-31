#!/bin/bash

IS_DEBUG=0
function toggle_debug()
{
    IS_DEBUG=1
    mkdir -p build/
    #set -e
    #exec 5>build/debug_output.txt
    #exec 1>>build/debug_output.txt
    #exec 2>>build/debug_output.txt
    #BASH_XTRACEFD="5"
    PS4='$LINENO: '
    set -x
}
#toggle_debug

#public config
installPWD=$PWD
source $installPWD/dependencies/scripts/utils.sh
source $installPWD/dependencies/scripts/public_config.sh
source $installPWD/dependencies/scripts/dependencies_check.sh

#check_param $1 $2
source $DEPENENCIES_FOLLOW_DIR/config.sh

#genesis.json generator
function generate_genesisBlock()
{
    export TEMP_NODE_ID_TPL=$1
    export GOD_ACCOUNT_ID_TPL=$2

    MYVARS='${TEMP_NODE_ID_TPL}:${GOD_ACCOUNT_ID_TPL}'
    envsubst $MYVARS < ${DEPENDENCIES_TPL_DIR}/temp_node_genesis.json.tpl > $buildPWD/node/genesis.json
    echo "generate_genesisBlock ,god => "${GOD_ACCOUNT_ID_TPL}
}

#stop_nodeX.sh generator
function generate_stopsh()
{
    stopsh="#!/bin/bash
    weth_pid=\`ps aux|grep \"${NODE_INSTALL_DIR}/nodedir${Idx[$index]}/config.json\"|grep -v grep|awk '{print \$2}'\`
    kill_cmd=\"kill -9 \${weth_pid}\"
    eval \${kill_cmd}"
    echo "$stopsh"
}

#start_nodeX.sh generator
function generate_startgodsh()
{
    startsh="#!/bin/bash
    ulimit -c unlimited
    nohup ./fisco-bcos  --genesis ${NODE_INSTALL_DIR}/genesis.json  --config ${NODE_INSTALL_DIR}/nodedir${Idx[$index]}/config.json  --godminer ${NODE_INSTALL_DIR}/nodedir${Idx[$index]}/godminer.json > ${NODE_INSTALL_DIR}/nodedir${Idx[$index]}/log/log 2>&1 &"
    echo "$startsh"
}

#start_nodeX.sh generator
function generate_startsh()
{
    startsh="#!/bin/bash
    ulimit -c unlimited
    nohup ./fisco-bcos  --genesis ${NODE_INSTALL_DIR}/genesis.json  --config ${NODE_INSTALL_DIR}/nodedir${Idx[$index]}/config.json > ${NODE_INSTALL_DIR}/nodedir${Idx[$index]}/log/log 2>&1 &"
    echo "$startsh"
}

#install
function install()
{
    echo "    Installing temp fisco-bcos environment start"
    request_sudo_permission

    sudo chown -R $(whoami) $installPWD

    #mkdir node dir
    current_node_dir_base=${NODE_INSTALL_DIR}
    current_web3sdk=${WEB3SDK_INSTALL_DIR}
    mkdir -p ${current_node_dir_base}

    current_node_dir=${current_node_dir_base}/nodedir0/
    mkdir -p $current_node_dir/
    mkdir -p $current_node_dir/log/
    mkdir -p $current_node_dir/keystore/
    mkdir -p $current_node_dir/fisco-data/
        
    cp $DEPENDENCIES_RLP_DIR/node_rlp_0/ca/node/* $current_node_dir/fisco-data/  #ca info copy
    #copy web3sdk 
    cp -r $DEPENENCIES_WEB3SDK_DIR ${buildPWD}/
    cp $DEPENDENCIES_RLP_DIR/node_rlp_0/ca/sdk/* ${current_web3sdk}/conf/  #ca info copy
    cp $DEPENDENCIES_RLP_DIR/bootstrapnodes.json $current_node_dir/fisco-data/ >/dev/null 2>&1

    nodeid=$(cat ${current_node_dir}/fisco-data/node.nodeid)
    echo "temp node id is "$nodeid

    export CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL=${DEFAULT_SYSTEM_CONTRACT_ADDRESS}
    export CONFIG_JSON_LISTENIP_TPL=${listenip[0]}
    export CRYPTO_MODE_TPL=${crypto_mode}
    export CONFIG_JSON_RPC_PORT_TPL=${rpcport[0]}
    export CONFIG_JSON_P2P_PORT_TPL=${p2pport[0]}
    export CHANNEL_PORT_VALUE_TPL=${channelPort[0]}
    export CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL=${current_node_dir}/keys.info
    export CONFIG_JSON_KEYSTORE_DIR_PATH_TPL=${current_node_dir}/keystore/
    export CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL=${current_node_dir}/fisco-data/

    MYVARS='${CHANNEL_PORT_VALUE_TPL}:${CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL}:${CONFIG_JSON_LISTENIP_TPL}:${CRYPTO_MODE_TPL}:${CONFIG_JSON_RPC_PORT_TPL}:${CONFIG_JSON_P2P_PORT_TPL}:${CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL}:${CONFIG_JSON_KEYSTORE_DIR_PATH_TPL}:${CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL}'
    envsubst $MYVARS < ${DEPENDENCIES_TPL_DIR}/config.json.tpl > ${current_node_dir}/config.json
    
    # generate log.conf from tpl
    export OUTPUT_LOG_FILE_PATH_TPL=${current_node_dir}/log
    MYVARS='${OUTPUT_LOG_FILE_PATH_TPL}'
    envsubst $MYVARS < ${DEPENDENCIES_TPL_DIR}/log.conf.tpl > ${current_node_dir}/fisco-data/log.conf

    # copy fisco-bcos
    cp $DEPENENCIES_FISCO_DIR/fisco-bcos $current_node_dir_base/
    chmod a+x $current_node_dir_base/fisco-bcos
    cd $current_node_dir_base

    $current_node_dir_base/fisco-bcos --newaccount $current_node_dir_base/godInfo.txt
   
    local god_addr=$(cat $current_node_dir_base/godInfo.txt | grep address | awk -F ':' '{print $2}' 2>/dev/null)
    if [ -z ${god_addr} ];then
        error_messaage " fisco-bcos --newaccount opr faild." "false"
    fi

    cp $current_node_dir_base/godInfo.txt $buildPWD
    generate_genesisBlock ${nodeid} ${god_addr}

    generate_startsh=`generate_startsh`
    echo "${generate_startsh}" > ${current_node_dir_base}/start_node${Idx[0]}.sh

    generate_startgodsh=`generate_startgodsh`
    echo "${generate_startgodsh}" > ${current_node_dir_base}/start_node${Idx[0]}_godminer.sh

    generate_stopsh=`generate_stopsh`
    echo "${generate_stopsh}" > ${current_node_dir_base}/stop_node${Idx[0]}.sh
    chmod +x ${current_node_dir_base}/start_node${Idx[0]}_godminer.sh
    chmod +x ${current_node_dir_base}/start_node${Idx[0]}.sh
    chmod +x ${current_node_dir_base}/stop_node${Idx[0]}.sh

    export WEB3SDK_CONFIG_IP=${listenip[0]}
    export WEB3SDK_CONFIG_PORT=${CHANNEL_PORT_VALUE_TPL}
    export WEB3SDK_SYSTEM_CONTRACT_ADDR=${DEFAULT_SYSTEM_CONTRACT_ADDRESS}
    echo "KEYSTORE_PWD="${KEYSTORE_PWD}
    echo "CLIENTCERT_PWD="${CLIENTCERT_PWD}
    MYVARS='${CLIENTCERT_PWD}:${KEYSTORE_PWD}:${WEB3SDK_CONFIG_IP}:${WEB3SDK_CONFIG_PORT}:${WEB3SDK_SYSTEM_CONTRACT_ADDR}'
    envsubst $MYVARS < $DEPENENCIES_DIR/tpl_dir/applicationContext.xml.tpl > ${current_web3sdk}/conf/applicationContext.xml

    cd ${current_node_dir_base}
    bash start_node${Idx[0]}.sh

    echo "    Loading genesis file : "
    $DEPENENCIES_DIR/scripts/percent_num_progress_bar.sh 8 &
    sleep 8

    # check if temp node is running
    check_port ${WEB3SDK_CONFIG_PORT}
    if [ $? -eq 0 ];then
        error_messaage "channel port $WEB3SDK_CONFIG_PORT is not listening, temp node start not success."
    fi

    #deploy system contract
    cd ${current_web3sdk}/bin
    chmod a+x ${current_web3sdk}/bin/system_contract_tools.sh
    bash ${current_web3sdk}/bin/system_contract_tools.sh DeploySystemContract

    #deploy system contract failed
    if [ ! -f ${current_web3sdk}/bin/output/SystemProxy.address ];then
        bash ${current_node_dir_base}/stop_node${Idx[0]}.sh
        error_messaage "system contract address file is not exist, web3sdk deploy system contract not success."
    fi 

    syaddress=$(cat ${current_web3sdk}/bin/output/SystemProxy.address)
    if [ -z $syaddress ];then
        bash ${current_node_dir_base}/stop_node${Idx[0]}.sh
        error_messaage "system contract address file is empty, web3sdk deploy system contract not success." 
    fi
    
    cp ${current_web3sdk}/bin/output/SystemProxy.address $buildPWD/syaddress.txt

    sleep 1
    
    #god miner config
    chmod a+x web3sdk
    #dos2unix web3sdk
    blk=$(./web3sdk eth_blockNumber | grep BlockHeight | awk -F ':' '{print $2}' 2>/dev/null)
    echo "blk number is "$blk
    blk=$(($blk+1))
    blk=`printf "0x%02x\n" ${blk}`
    export GODMINERSTART_TPL=$blk
    export GODMINEREND_TPL="0xffffffffff"
    export NODEID_TPL=${nodeid}
    export NODEDESC_TPL=${Nodedesc}
    export AGENCYINFO_TPL=${Agencyinfo}
    export PEERIP_TPL="127.0.0.1"
    export IDENTITYTYPE_TPL="1"
    export PORT_TPL=${p2pport[0]}
    export IDX_TPL=0
    MYVARS='${IDX_TPL}:${PORT_TPL}:${IDENTITYTYPE_TPL}:${PEERIP_TPL}:${GODMINERSTART_TPL}:${GODMINEREND_TPL}:${NODEID_TPL}:${NODEDESC_TPL}:${AGENCYINFO_TPL}'
    envsubst $MYVARS < ${DEPENDENCIES_TPL_DIR}/godminer.json.tpl > ${current_node_dir}/godminer.json

    sed -i.bu "s/${DEFAULT_SYSTEM_CONTRACT_ADDRESS}/$syaddress/g" ${current_web3sdk}/conf/applicationContext.xml
    echo "system contract deployed ,syaddress => "${syaddress}
    
    #replace system contract address
    sed -i.bu "s/$DEFAULT_SYSTEM_CONTRACT_ADDRESS/$syaddress/g" ${current_node_dir}/config.json

    #sleep 6
    bash ${current_node_dir_base}/stop_node${Idx[0]}.sh

    cd $installPWD
    echo "    Installing temp node fisco-bcos success!"
    return 0
}

case "$1" in
    'install')
        install
        ;;
    *)
        echo "invalid option!"
        echo "Usage: $0 {install}"
esac

