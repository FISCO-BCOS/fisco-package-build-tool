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
DEPENENCIES_DIR=$installPWD/dependencies
source $DEPENENCIES_DIR/scripts/utils.sh
source $DEPENENCIES_DIR/scripts/public_config.sh

DEFAULT_SYSTEM_CONTRACT_ADDRESS="0x919868496524eedc26dbb81915fa1547a20f8998"

help_str="please pass ip like: $0 internal_ip external_ip to install"

function check_param()
{
    is_internal_ip_valid=$(is_valid_ip $1)
    is_external_ip_valid=$(is_valid_ip $2)

    if [ "$is_internal_ip_valid" = "false" ] || [ "$is_external_ip_valid" = "false" ]
    then
        echo "miss internal ip and external ip as parameter!"
        echo $help_str
        return
        #exit
    else 
        if [ "$is_internal_ip_valid" = "false" ];then
            echo "internal ip invalid ,ip is "$is_internal_ip_valid
        else
            echo "external ip invalid ,ip is "$is_external_ip_valid
        fi
    fi
}

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

#enviroment for node in node.sh
function build_node_sh()
{
    node_str="
    export NODE_HOME=$buildPWD/nodejs;
    export PATH=\$PATH:\$NODE_HOME/bin;
    export NODE_PATH=\$NODE_HOME/lib/node_modules:\$NODE_HOME/lib/node_modules/ethereum-console/node_modules;
    "
    echo $node_str > $buildPWD/node.sh
    echo "source $buildPWD/node.sh" >> ~/.bashrc
    source ~/.bashrc
}

#install node
function install_nodejs()
{
    print_install_result "nodejs"

    mkdir -p $buildPWD/nodejs/bin/
    cd $installPWD/dependencies/nodejs/
    tar --strip-components 1 -xzvf node-v*tar.gz -C $buildPWD/nodejs/ 1>>/dev/null

    export NODE_HOME=$buildPWD/nodejs
    export PATH=$PATH:$NODE_HOME/bin

    #install node js enviroment in web3lib tool systemcontractv dictionary
    cd ../web3lib
    npm install >/dev/null 2>&1
    cd ../tool
    npm install >/dev/null 2>&1
    #cd ../systemcontract
    #npm install

    #cd $installPWD
    return 0
}

#install ethconsole
function install_ethconsole()
{
    print_install_result "ethconsole"

    #mkdir -p $installPWD/build/nodejs/
    mkdir -p $NODE_MODULES_DIR/
    mkdir -p $buildPWD/nodejs/bin/
    rm -rf $NODE_MODULES_DIR/ethereum-console/

    cd $installPWD/dependencies/nodejs/
    tar -xzvf ethereum-console.tar.gz 1>>/dev/null
    mv ethereum-console $NODE_MODULES_DIR/

    cd $buildPWD/nodejs/bin/
    rm -f ethconsole
    ln -s $NODE_MODULES_DIR/ethereum-console/main.js ethconsole
    cd $installPWD
    return 0
}

# install babel js, which is needed by process of deploy contract
function install_babel()
{
    print_install_result "babel.js"

    #cd $NODE_MODULES_DIR
    #npm install --save-dev babel-cli babel-preset-es2017 async
    cd $installPWD/dependencies/nodejs/

    #cp babelrc ~/.babelrc
    echo '{ "presets": ["es2017"]  }' > .babelrc
    #source .babelrc

    mkdir -p $NODE_MODULES_DIR/
    tar -xzvf babel.tar.gz 1>>/dev/null
    rm -rf $NODE_MODULES_DIR/babel-cli
    rm -rf $NODE_MODULES_DIR/babel-preset-es2017
    mv babel-cli $NODE_MODULES_DIR/
    mv babel-preset-es2017 $NODE_MODULES_DIR/
    cd $buildPWD/nodejs/bin/
    rm -f babel babel-doctor babel-external-helper babel-node

    ln -s $NODE_MODULES_DIR/babel-cli/bin/babel.js babel
    ln -s $NODE_MODULES_DIR/babel-cli/bin/babel-doctor.js babel-doctor
    ln -s $NODE_MODULES_DIR/babel-cli/bin/babel-external-helpers.js babel-external-helper
    ln -s $NODE_MODULES_DIR/babel-cli/bin/babel-node.js  babel-node

    cd $installPWD
    return 0
}

function copy_and_link_if_not_same()
{
    # $1 from  
    # $2 to
    # $3 link name (can be null)
    if  [ ! -f "$2" ] || [ "`md5sum $1 | awk '{print $1}'`" != "`md5sum $2 | awk '{print $1}'`" ];then
        sudo cp $1 $2
        if [ -n "$3" ];then
            sudo ln -s $1 $3
        fi
    #else
        #echo "copy: jump the same file " $2
    fi
}

#install dependency software
function install_dependencies() 
{
    if grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        sudo apt-get -y install openssl
        sudo apt-get -y install build-essential
        sudo apt-get -y install libcurl4-openssl-dev libgmp-dev
        sudo apt-get -y install libleveldb-dev  libmicrohttpd-dev
        sudo apt-get -y install libminiupnpc-dev
        sudo apt-get -y install libssl-dev libkrb5-dev
        sudo apt-get -y install lsof

        wget https://github.com/FISCO-BCOS/fisco-solc/raw/master/fisco-solc-ubuntu -O $DEPENENCIES_DIR/tool/fisco-solc
        sudo cp $DEPENENCIES_DIR/tool/fisco-solc /usr/local/bin/
        sudo chmod a+x /usr/local/bin/fisco-solc

    else
        sudo yum -y install git gcc-c++
        sudo yum -y install openssl openssl-devel
        sudo yum -y install leveldb-devel curl-devel 
        sudo yum -y install libmicrohttpd-devel gmp-devel 
        sudo yum -y install lsof

        wget https://github.com/FISCO-BCOS/fisco-solc/raw/master/fisco-solc-centos -O $DEPENENCIES_DIR/tool/fisco-solc
        sudo cp $DEPENENCIES_DIR/tool/fisco-solc /usr/local/bin/
        sudo chmod a+x /usr/local/bin/fisco-solc
    fi
}

#install
function install()
{
    echo "    Installing temp fisco-bcos environment start"
    request_sudo_permission
    ret=$?
    if [ $ret -ne 0 ]
    then
        return -1
    fi

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
    export CONFIG_JSON_NETWORK_ID_TPL=${DEFAULT_NETWORK_ID}

    MYVARS='${CHANNEL_PORT_VALUE_TPL}:${CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL}:${CONFIG_JSON_LISTENIP_TPL}:${CRYPTO_MODE_TPL}:${CONFIG_JSON_RPC_PORT_TPL}:${CONFIG_JSON_P2P_PORT_TPL}:${CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL}:${CONFIG_JSON_KEYSTORE_DIR_PATH_TPL}:${CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL}:${CONFIG_JSON_NETWORK_ID_TPL}'
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
        echo "WARNING : fisco-bcos --newaccount failed."
        return 1
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
    MYVARS='${WEB3SDK_CONFIG_IP}:${WEB3SDK_CONFIG_PORT}:${WEB3SDK_SYSTEM_CONTRACT_ADDR}'
    envsubst $MYVARS < $DEPENENCIES_DIR/tpl_dir/applicationContext.xml.tpl > ${current_web3sdk}/conf/applicationContext.xml
    # echo "${DEPENENCIES_DIR}/tpl_dir/applicationContext.xml.tpl > ${DEPENENCIES_DIR}/web3sdk/conf/applicationContext.xml"

    cd ${current_node_dir_base}
    bash start_node${Idx[0]}.sh

    echo "    Loading genesis file : "
    $DEPENENCIES_DIR/scripts/percent_num_progress_bar.sh 8 &
    sleep 8

    # check if temp node is running
    check_port ${WEB3SDK_CONFIG_PORT}
    if [ $? -eq 0 ];then
        echo "channel port $WEB3SDK_CONFIG_PORT is not listening, maybe temp node start failed."
        return 1
    fi

    #deploy system contract
    cd ${current_web3sdk}/bin
    chmod a+x ${current_web3sdk}/bin/system_contract_tools.sh
    bash ${current_web3sdk}/bin/system_contract_tools.sh DeploySystemContract

    #deploy system contract failed
    if [ ! -f ${current_web3sdk}/bin/output/SystemProxy.address ];then
        echo "WARNING : SystemProxy.address is not exist, maybe deploy system contract failed."
        bash ${current_node_dir_base}/stop_node${Idx[0]}.sh
        return 1
    fi 

    #cp output/SystemProxy.address $buildPWD/syaddress.txt
    syaddress=$(cat ${current_web3sdk}/bin/output/SystemProxy.address)
    if [ -z $syaddress ];then
        echo "WARNING : system contract address null, maybe deploy system contract failed."
        bash ${current_node_dir_base}/stop_node${Idx[0]}.sh
        return 2  
    fi
    cp ${current_web3sdk}/bin/output/SystemProxy.address $buildPWD/syaddress.txt

    sleep 1
    
    #god miner config
    chmod a+x web3sdk
    dos2unix web3sdk
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

    sed -i "s/${DEFAULT_SYSTEM_CONTRACT_ADDRESS}/$syaddress/g" ${current_web3sdk}/conf/applicationContext.xml
    echo "system contract deployed ,syaddress => "${syaddress}
    
    #replace system contract address
    sed -i "s/$DEFAULT_SYSTEM_CONTRACT_ADDRESS/$syaddress/g" ${current_node_dir}/config.json

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

