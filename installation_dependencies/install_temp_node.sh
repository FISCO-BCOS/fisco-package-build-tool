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

help_str="please pass ip like: $0 internal_ip external_ip to install"

#private config
DEFAULT_SYSTEM_CONTRACT_ADDRESS="0xdefd11efc7f5eb36c7a7853d9c7ffaf5366b292d"

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

source $installPWD/dependencies/config.sh

#genesis.json generator
function generate_genesisBlock()
{
    export TEMP_NODE_ID_TPL=$1
    export GOD_ACCOUNT_ID_TPL=$2

    MYVARS='${TEMP_NODE_ID_TPL}:${GOD_ACCOUNT_ID_TPL}'
    envsubst $MYVARS < ${TPL_DIR_PATH}/temp_node_genesis.json.tpl > $buildPWD/genesis.json
    echo "generate_genesisBlock ,god => "${GOD_ACCOUNT_ID_TPL}
}

#stop_nodeX.sh generator
function generate_stopsh()
{
    stopsh="#!/bin/bash
    weth_pid=\`ps aux|grep \"$buildPWD/nodedir${Idx[$index]}/config.json\"|grep -v grep|awk '{print \$2}'\`
    kill_cmd=\"kill -9 \${weth_pid}\"
    eval \${kill_cmd}"
    echo "$stopsh"
}


#start_nodeX.sh generator
function generate_startsh()
{
    startsh="#!/bin/bash
    ulimit -c unlimited
    nohup ./fisco-bcos  --genesis $buildPWD/genesis.json  --config $buildPWD/nodedir${Idx[$index]}/config.json  > $buildPWD/nodedir${Idx[$index]}/log/log 2>&1 &"
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

#god address generator
function generatorGod()
{
    #install_nodejs
    #cd $installPWD/dependencies/tool/
    #node accountManager.js > godInfo.txt
    #mv godInfo.txt $buildPWD
    #echo "godInfo is "
    #echo $(cat $buildPWD/godInfo.txt  2>/dev/null)

    mkdir -p $buildPWD
    cd $installPWD
    ./fisco-bcos --newaccount
    mv godInfo.txt $buildPWD
    echo "god Info => "
    echo $(cat $buildPWD/godInfo.txt  2>/dev/null)
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

    generatorGod
    
    i=0
    while [ $i -lt $nodecount ]
    do
        index=$i
        mkdir -p $buildPWD/nodedir${Idx[$index]}/
        mkdir -p $buildPWD/nodedir${Idx[$index]}/log
        mkdir -p $buildPWD/nodedir${Idx[$index]}/keystore
        mkdir -p $buildPWD/nodedir${Idx[$index]}/fisco-data

        cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/node/* $buildPWD/nodedir${Idx[$index]}/fisco-data/  #ca info copy
        cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/sdk/* $DEPENENCIES_JTOOL_DIR/conf/  #ca info copy
        cp $DEPENDENCIES_RLP_DIR/cryptomod.json $buildPWD/nodedir${Idx[$index]}/fisco-data/ >/dev/null 2>&1
        cp $DEPENDENCIES_RLP_DIR/bootstrapnodes.json $buildPWD/nodedir${Idx[$index]}/fisco-data/ >/dev/null 2>&1
        cp $KEYSTORE_FILE_DIR/*.json $buildPWD/nodedir${Idx[$index]}/keystore/ >/dev/null 2>&1

        cd $buildPWD/nodedir${Idx[$index]}/fisco-data/
        nodeid=$(cat node.nodeid)
        echo "temp node id is "$nodeid

        export CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL=${DEFAULT_SYSTEM_CONTRACT_ADDRESS}
        export CONFIG_JSON_LISTENIP_TPL=${listenip[$index]}
        export CRYPTO_MODE_TPL=${crypto_mode}
        export CONFIG_JSON_RPC_PORT_TPL=${rpcport[$index]}
        export CONFIG_JSON_P2P_PORT_TPL=${p2pport[$index]}
        export CHANNEL_PORT_VALUE_TPL=${channelPort[$index]}
        export CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL=${buildPWD}/nodedir${Idx[$index]}/keys.info
        export CONFIG_JSON_KEYSTORE_DIR_PATH_TPL=${buildPWD}/nodedir${Idx[$index]}/keystore/
        export CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL="${buildPWD}/nodedir${Idx[$index]}/fisco-data/"
        export CONFIG_JSON_NETWORK_ID_TPL=${DEFAULT_NETWORK_ID}

        MYVARS='${CHANNEL_PORT_VALUE_TPL}:${CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL}:${CONFIG_JSON_LISTENIP_TPL}:${CRYPTO_MODE_TPL}:${CONFIG_JSON_RPC_PORT_TPL}:${CONFIG_JSON_P2P_PORT_TPL}:${CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL}:${CONFIG_JSON_KEYSTORE_DIR_PATH_TPL}:${CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL}:${CONFIG_JSON_NETWORK_ID_TPL}'
        envsubst $MYVARS < ${TPL_DIR_PATH}/config.json.tpl > $buildPWD/nodedir${Idx[$index]}/config.json

         #port checkcheck
        check_port ${CONFIG_JSON_RPC_PORT_TPL}
        if [ $? -ne 0 ];then
            echo "temp node rpc port check, ${CONFIG_JSON_RPC_PORT_TPL} is in use."
        fi
       
        check_port ${CHANNEL_PORT_VALUE_TPL}
        if [ $? -ne 0 ];then
            echo "temp node channel port check, $CHANNEL_PORT_VALUE_TPL is in use."
        fi
        check_port ${CONFIG_JSON_P2P_PORT_TPL}
        if [ $? -ne 0 ];then
            echo "temp node p2p port check, ${CONFIG_JSON_P2P_PORT_TPL} is in use."
        fi

        # generate log.conf from tpl
        export OUTPUT_LOG_FILE_PATH_TPL=$buildPWD/nodedir${Idx[$index]}/log
        MYVARS='${OUTPUT_LOG_FILE_PATH_TPL}'
        envsubst $MYVARS < ${TPL_DIR_PATH}/log.conf.tpl > $buildPWD/nodedir${Idx[$index]}/fisco-data/log.conf

        local god_addr=""
        if [ -f $buildPWD/godInfo.txt ];then
            god_addr=$(cat $buildPWD/godInfo.txt | grep address | awk -F ':' '{print $2}' 2>/dev/null)
        fi

        if [ -z ${god_addr} ];then
            god_addr=$GOD_ADDRESS_DEFAULT_VALUE
        fi

        if [ $i -eq 0 ];
        then
            generate_genesisBlock ${nodeid} ${god_addr}
        fi

        generate_startsh=`generate_startsh`
        echo "${generate_startsh}" > $installPWD/start_node${Idx[$index]}.sh
        generate_stopsh=`generate_stopsh`
        echo "${generate_stopsh}" > $installPWD/stop_node${Idx[$index]}.sh
        chmod +x $installPWD/fisco-bcos
        chmod +x $installPWD/start_node${Idx[$index]}.sh
        chmod +x $installPWD/stop_node${Idx[$index]}.sh

        i=$(($i+1))
    done

    export JTOOL_CONFIG_IP=${listenip[0]}
    export JTOOL_CONFIG_PORT=${CHANNEL_PORT_VALUE_TPL}
    export JTOOL_SYSTEM_CONTRACT_ADDR="0x919868496524eedc26dbb81915fa1547a20f8998"
    MYVARS='${JTOOL_CONFIG_IP}:${JTOOL_CONFIG_PORT}:${JTOOL_SYSTEM_CONTRACT_ADDR}'
    envsubst $MYVARS < $DEPENENCIES_DIR/tpl_dir/applicationContext.xml.tpl > $DEPENENCIES_DIR/jtool/conf/applicationContext.xml
    # echo "${DEPENENCIES_DIR}/tpl_dir/applicationContext.xml.tpl > ${DEPENENCIES_DIR}/jtool/conf/applicationContext.xml"

    cd $installPWD
    ./start_node${Idx[0]}.sh

    echo "    Loading genesis file : "
    $DEPENENCIES_DIR/scripts/percent_num_progress_bar.sh 24 &
    sleep 24

    # check if temp node is running
    check_port ${JTOOL_CONFIG_PORT}
    if [ $? -eq 0 ];then
        echo "channel port $JTOOL_CONFIG_PORT is not listening, maybe temp node start failed."
        return 1
    fi
    
    #ps -ef|grep fisco-bcos

    cd $installPWD/dependencies/web3lib/
    cp ../tpl_dir/config.js.tpl config.js
    sed -i "s/ip:port/${listenip[0]}:${rpcport[0]}/g"  $installPWD/dependencies/web3lib/config.js

    #deploy system contract
    cd $installPWD/dependencies/jtool/bin
    chmod a+x system_contract_tools.sh
    ./system_contract_tools.sh DeploySystemContract

    #deploy system contract failed
    if [ ! -f output/SystemProxy.address ];then
        #echo "WARNING : SystemProxy.address is not exist, maybe deploy system contract failed."
        return 1
    fi

    cp output/SystemProxy.address $buildPWD/syaddress.txt
    syaddress=$(cat $buildPWD/syaddress.txt)

    #system contract address null
    if [ -z $syaddress ];then
        #echo "WARNING : system contract address null, maybe deploy system contract failed."
        return 2  
    fi

    sed -i "s/0x919868496524eedc26dbb81915fa1547a20f8998/$syaddress/g" ../conf/applicationContext.xml

    echo "system contract deployed ,SystemProxy.address is "${syaddress}
    #echo "jtool conf = "$(cat ../conf/applicationContext.xml)

    cd $installPWD
    j=0
    #replace system contract address
    while [ $j -lt $nodecount ]
    do
        sed -i "s/$DEFAULT_SYSTEM_CONTRACT_ADDRESS/$syaddress/g" $buildPWD/nodedir${Idx[$j]}/config.json
        j=$(($j+1))
    done

    #sleep 6
    ./stop_node${Idx[0]}.sh

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

