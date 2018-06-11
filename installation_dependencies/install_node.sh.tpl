#!/bin/bash

#set -x
#set -e

#public config
installPWD=$PWD
DEPENENCIES_DIR=$installPWD/dependencies
source $DEPENENCIES_DIR/scripts/utils.sh
source $DEPENENCIES_DIR/scripts/public_config.sh

source $installPWD/dependencies/config.sh
g_is_genesis_host=$IS_GENESIS_HOST_TPL

if [ -f $installPWD/.i_am_genesis_host ]
then
    g_is_genesis_host=1
else
    g_is_genesis_host=0
fi

# build stop_node*.sh
function generate_stopsh_func()
{
    #kill -9 改为 kill -2
    stopsh="#!/bin/bash
    weth_pid=\`ps aux|grep \"$buildPWD/nodedir${Idx[$index]}/config.json\"|grep -v grep|awk '{print \$2}'\`
    kill_cmd=\"kill -2 \${weth_pid}\"
    echo \"\${kill_cmd}\"
    eval \${kill_cmd}"
    echo "$stopsh"
    return 0
}

# build start_node*.sh
function generate_startsh_func()
{
    startsh="#!/bin/bash
    nohup ./fisco-bcos  --genesis $DEPENENCIES_DIR/genesis.json  --config $buildPWD/nodedir${Idx[$index]}/config.json  >> $buildPWD/nodedir${Idx[$index]}/log/log 2>&1 &"
    echo "$startsh"
    return 0
}

# nodejs environment variable setting
function build_node_sh()
{
    node_str="
    export NODE_HOME=$buildPWD/nodejs;
    export PATH=\$PATH:\$NODE_HOME/bin;
    export NODE_PATH=\$NODE_HOME/lib/node_modules:\$NODE_HOME/lib/node_modules/ethereum-console/node_modules;
    "
    echo $node_str > $buildPWD/node.sh
    sudo chmod a+x $buildPWD/node.sh
    echo "source $buildPWD/node.sh" >> ~/.bashrc
    source ~/.bashrc >/dev/null 2>&1
}

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
    npm install
    cd ../tool
    npm install
    cd ../systemcontract
    npm install

    cd $installPWD
    return 0
}

function install_ethconsole()
{
    print_install_result "ethconsole"

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

function nodejs_env_check()
{
    echo "Checking nodejs enviroment beginning."
    #check nodejs enviroment
    type npm >/dev/null 2>&1
    if [ $? -eq 0 ];then
        ret=`npm -v`
        print_install_info "npm install success , npm versoin $ret."
    else
        echo "Error, install [npm] failed, you should install manually."
    fi

    type ethconsole >/dev/null 2>&1
    if [ $? -eq 0 ];then
        print_install_info "ethconsole install success."
    else
        echo "Error, install [ethconsole] failed, you should install manually."
    fi

    type babel-node >/dev/null 2>&1
    if [ $? -eq 0 ];then
        ret=`babel-node -V`
        print_install_info "babel-node install success , babel-node versoin $ret"
    else
        echo "Error, install [babel-node] failed, you should install manually."
    fi

    echo "Checking nodejs enviroment end."
}

function install_node_dependencies()
{
    #install nodejs related in the subcategory , if the user already install nodejs , nothing has effect.
    install_nodejs
    install_ethconsole
    install_babel

    build_node_sh

    return

    #CentOS
    # curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
    # curl --silent --location https://rpm.nodesource.com/setup_9.x | sudo bash -
    # sudo yum -y install nodejs

    #Ubuntu
    # curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
    # curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
    # sudo apt-get install -y nodejs

    #install cnpm
    #type cnpm >/dev/null 2>&1
    #if [ $? -eq 0 ];then
    #    ret=`cnpm -v`
    #    print_install_info "cnpm already exist, npm versoin $ret"
    #else
    #    sudo npm install -g --unsafe-perm cnpm --registry=https://registry.npm.taobao.org
    #fi

    #install ethconsle
    #type ethconsole >/dev/null 2>&1
    #if [ $? -eq 0 ];then
    #    print_install_info "ethconsole already exist, ethconsole info "`type ethconsole`
    #else
    #    sudo chmod a+w /root/.npm
    #    sudo npm install -g --unsafe-perm ethereum-console
    #fi

    #install babel
    #type babel-node >/dev/null 2>&1
    #if [ $? -eq 0 ];then
    #    ret=`babel-node -V`
    #    print_install_info "babel-node already exist, babel-node versoin $ret"
    #else
    #    sudo cnpm install -g babel-cli babel-preset-es2017
    #    echo '{ "presets": ["es2017"] }' > ~/.babelrc
    #fi
}

function build_tools()
{
    cp $DEPENENCIES_DIR/monitor/monitor.sh $installPWD/
    chmod +x $installPWD/monitor.sh
}

function install()
{
    echo "    Installing fisco-bcos environment start"
    request_sudo_permission
    ret=$?
    if [ $ret -ne 0 ]
    then
        return -1
    fi

    sudo chown -R $(whoami) $installPWD

    if [ -d $buildPWD ]
    then
        echo "you already install the fisco-bcos node in this directory!"
        echo "if you wanna re install the fisco-bcos node, please remove the directory: $buildPWD"
        echo "if you wanna install another fisco-bcos node(whether it is on the same host as before or not), you need to contact the administrator for a whole new intallation package!"
        return 2
    fi

    if [ $nodecount -le 0 ]; then
        echo "there has no node on this server, count is "$nodecount
        return
    fi

    print_dash

    install_dependencies

    i=0
    while [ $i -lt $nodecount ]
    do
        index=$i
        mkdir -p $buildPWD/nodedir${Idx[$index]}/
        mkdir -p $buildPWD/nodedir${Idx[$index]}/log/
        mkdir -p $buildPWD/nodedir${Idx[$index]}/keystore/
        mkdir -p $buildPWD/nodedir${Idx[$index]}/fisco-data/
        
        if [ $i -eq 0 ];then
            cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/sdk/* $DEPENENCIES_JTOOL_DIR/conf/  #ca info copy
        fi

        #cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/network.rlp $buildPWD/nodedir${Idx[$index]}/fisco-data/
        #cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/network.rlp.pub $buildPWD/nodedir${Idx[$index]}/fisco-data/
        #cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/datakey $buildPWD/nodedir${Idx[$index]}/fisco-data/ >/dev/null 2>&1
        cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/node/* $buildPWD/nodedir${Idx[$index]}/fisco-data/  #ca info copy
        cp $DEPENDENCIES_RLP_DIR/cryptomod.json $buildPWD/nodedir${Idx[$index]}/fisco-data/ >/dev/null 2>&1
        cp $DEPENENCIES_DIR/bootstrapnodes.json $buildPWD/nodedir${Idx[$index]}/fisco-data/ >/dev/null 2>&1
        cp $KEYSTORE_FILE_DIR/*.json $buildPWD/nodedir${Idx[$index]}/keystore/ >/dev/null 2>&1

        cd $buildPWD/nodedir${Idx[$index]}/fisco-data/
        nodeid=$(cat node.nodeid)
        echo "node id is "$nodeid

        export CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL=$(cat $DEPENENCIES_DIR/syaddress.txt)
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

         #port check
        check_port $CONFIG_JSON_RPC_PORT_TPL
        if [ $? -ne 0 ];then
            echo "node $i, rpc port check, $CONFIG_JSON_RPC_PORT_TPL is in use."
        fi 

        check_port $CHANNEL_PORT_VALUE_TPL
        if [ $? -ne 0 ];then
            echo "node $i, channel port check, $CHANNEL_PORT_VALUE_TPL is in use."
        fi
        check_port $CONFIG_JSON_P2P_PORT_TPL
        if [ $? -ne 0 ];then
            echo "node $i, p2p port check, $CONFIG_JSON_P2P_PORT_TPL is in use."
        fi

        # generate log.conf from tpl
        export OUTPUT_LOG_FILE_PATH_TPL=$buildPWD/nodedir${Idx[$index]}/log
        MYVARS='${OUTPUT_LOG_FILE_PATH_TPL}'
        envsubst $MYVARS < ${TPL_DIR_PATH}/log.conf.tpl > $buildPWD/nodedir${Idx[$index]}/fisco-data/log.conf

        generate_startsh=`generate_startsh_func`
        echo "${generate_startsh}" > $installPWD/start_node${Idx[$index]}.sh
        generate_stopsh=`generate_stopsh_func`
        echo "${generate_stopsh}" > $installPWD/stop_node${Idx[$index]}.sh
        chmod +x $installPWD/fisco-bcos
        chmod +x $installPWD/start_node${Idx[$index]}.sh
        chmod +x $installPWD/stop_node${Idx[$index]}.sh

        #
        cd $installPWD
        ./fisco-bcos --cryptokey $CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL/cryptomod.json 1>/dev/null 2>&1

        i=$(($i+1))
    done

    #config.js
    cd $installPWD/dependencies/web3lib/
    cp ../tpl_dir/config.js.tpl config.js
    sed -i "s/ip:port/${listenip[0]}:${rpcport[0]}/g"  $installPWD/dependencies/web3lib/config.js

    #jtool config
    export JTOOL_CONFIG_IP=${listenip[0]}
    export JTOOL_CONFIG_PORT=${channelPort[0]}
    export JTOOL_SYSTEM_CONTRACT_ADDR=$(cat $DEPENENCIES_DIR/syaddress.txt)
    MYVARS='${JTOOL_CONFIG_IP}:${JTOOL_CONFIG_PORT}:${JTOOL_SYSTEM_CONTRACT_ADDR}'
    echo "JTOOL_CONFIG_PORT=${channelPort[0]}"
    echo "JTOOL_SYSTEM_CONTRACT_ADDR=$(cat $DEPENENCIES_DIR/syaddress.txt)"
    envsubst $MYVARS < $DEPENENCIES_DIR/tpl_dir/applicationContext.xml.tpl > $installPWD/dependencies/jtool/conf/applicationContext.xml
    # echo "envsubst $MYVARS < $DEPENENCIES_DIR/tpl_dir/applicationContext.xml.tpl > $installPWD/dependencies/jtool/conf/applicationContext.xml"

    #systemcontractv contract address
    cp $DEPENENCIES_DIR/syaddress.txt $DEPENENCIES_DIR/systemcontract/output/SystemProxy.address

    build_tools

    cd $installPWD

    print_dash

    echo "    Installing fisco-bcos success!"

    install_node_dependencies

    return 0
}

function info()
{
    echo "install Information:"
    echo "****************************"
    echo "If can not start the fisco-bcos process, check your genesis.json, config.sh config.json, syaddress.txt and genesis_node_info.json file."
    echo "****************************"
}

case "$1" in
    'install')
        install
        ;;
    'info')
        info
        ;;
    *)
        echo "invalid option!"
        echo "Usage: $0 {install|info}"
        #exit 1
esac

