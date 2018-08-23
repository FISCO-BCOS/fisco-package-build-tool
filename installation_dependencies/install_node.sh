#!/bin/bash

#set -x
#set -e

#public config
installPWD=$PWD
DEPENENCIES_DIR=$installPWD/dependencies
source $DEPENENCIES_DIR/scripts/utils.sh
source $DEPENENCIES_DIR/scripts/public_config.sh
source $DEPENENCIES_DIR/scripts/os_version_check.sh
source $DEPENENCIES_DIR/scripts/dependencies_install.sh
source $DEPENENCIES_DIR/scripts/dependencies_check.sh
source $DEPENENCIES_DIR/scripts/ext_so.sh

source $DEPENENCIES_DIR/config.sh
g_is_genesis_host=${is_genesis_host}

# build stop_node*.sh
function generate_stopsh_func()
{
    stopsh="#!/bin/bash
    weth_pid=\`ps aux|grep \"${NODE_INSTALL_DIR}/node${Idx[$index]}/config.json\"|grep -v grep|awk '{print \$2}'\`
    kill_cmd=\"kill -9 \${weth_pid}\"
    if [ ! -z \$weth_pid ];then
        echo \"stop node${Idx[$index]} ...\"
        eval \${kill_cmd}
    else
        echo \"node${Idx[$index]} is not running.\"
    fi"
    echo "$stopsh"
    return 0
}

# build check_node*.sh
function generate_checksh_func()
{
    checknodesh="#!/bin/bash
    weth_pid=\`ps aux|grep \"${NODE_INSTALL_DIR}/node${Idx[$index]}/config.json\"|grep -v grep|awk '{print \$2}'\`
    if [ ! -z \$weth_pid ];then
        echo \"node\$1 is running.\"
    else
        echo \"node\$1 is not running.\"
    fi"
    echo "$checknodesh"
}

# build start_node*.sh
function generate_startsh_func()
{
    startsh="#!/bin/bash
    weth_pid=\`ps aux|grep \"${NODE_INSTALL_DIR}/node${Idx[$index]}/config.json\"|grep -v grep|awk '{print \$2}'\`
    if [ ! -z \$weth_pid ];then
        echo \"node${Idx[$index]} is running, pid is \$weth_pid.\"
    else
        echo \"start node${Idx[$index]} ...\"
        nohup ./fisco-bcos  --genesis ${NODE_INSTALL_DIR}/node${Idx[$index]}/genesis.json  --config ${NODE_INSTALL_DIR}/node${Idx[$index]}/config.json  >> ${NODE_INSTALL_DIR}/node${Idx[$index]}/log/log 2>&1 &
    fi"
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
    cd $DEPENENCIES_NODEJS_DIR
    tar --strip-components 1 -xzvf node-v*tar.gz -C $buildPWD/nodejs/ 1>>/dev/null

    export NODE_HOME=$buildPWD/nodejs
    export PATH=$PATH:$NODE_HOME/bin

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

function install_node()
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

function install_build()
{
    echo "    Installing fisco-bcos environment start"

    #check sudo permission
    request_sudo_permission
    # operation system check
    os_version_check
    # java version check
    java_version_check

    sudo chown -R $(whoami) $installPWD

    if [ -d $buildPWD ];then
        error_message "build dictinary already exist, remove it first."
    fi

    if [ -z $nodecount ] ||[ $nodecount -le 0 ]; then
        error_message "there has no node on this server, count is "$nodecount
    fi

    print_dash

    #dependencies check
    dependencies_install
    install_dependencies_check
    copy_so_file $DEPENENCIES_SO_DIR/ /usr/lib64

    #mkdir node dir
    current_node_dir_base=${NODE_INSTALL_DIR}
    mkdir -p ${current_node_dir_base}

    i=0
    while [ $i -lt $nodecount ]
    do
        index=$i
        current_node_dir=${current_node_dir_base}/node${Idx[$index]}
        mkdir -p $current_node_dir/
        mkdir -p $current_node_dir/log/
        mkdir -p $current_node_dir/keystore/
        mkdir -p $current_node_dir/data/

        if [ $i -eq 0 ];then
            #copy web3sdk
            cp -r $DEPENENCIES_WEB3SDK_DIR ${buildPWD}
            sudo chmod a+x ${buildPWD}/web3sdk/bin/web3sdk
            cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/sdk/* ${buildPWD}/web3sdk/conf/ >/dev/null 2>&1 #ca info copy
            if [ $g_is_genesis_host -eq 1 ];then
                cp $DEPENDENCIES_TPL_DIR/empty_bootstrapnodes.json ${current_node_dir}/data/bootstrapnodes.json >/dev/null 2>&1
            else
                cp $DEPENENCIES_FOLLOW_DIR/bootstrapnodes.json ${current_node_dir}/data/ >/dev/null 2>&1
            fi
        else
            cp $DEPENENCIES_FOLLOW_DIR/bootstrapnodes.json ${current_node_dir}/data/ >/dev/null 2>&1
        fi

        #copy node ca
        cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/node/* ${current_node_dir}/data/
        # cp $DEPENENCIES_FOLLOW_DIR/bootstrapnodes.json ${current_node_dir}/data/ >/dev/null 2>&1

        nodeid=$(cat ${current_node_dir}/data/node.nodeid)
        echo "node id is "$nodeid

        #genesis.json
        cp $DEPENENCIES_FOLLOW_DIR/genesis.json ${current_node_dir}
        
        # generate log.conf from tpl
        export OUTPUT_LOG_FILE_PATH_TPL=${current_node_dir}/log
        MYVARS='${OUTPUT_LOG_FILE_PATH_TPL}'
        envsubst $MYVARS < ${DEPENDENCIES_TPL_DIR}/log.conf.tpl > ${current_node_dir}/log.conf

        export CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL=$(cat $DEPENENCIES_FOLLOW_DIR/syaddress.txt)
        export CONFIG_JSON_LISTENIP_TPL=${listenip[$index]}
        export CRYPTO_MODE_TPL=${crypto_mode}
        export CONFIG_JSON_RPC_PORT_TPL=${rpcport[$index]}
        export CONFIG_JSON_P2P_PORT_TPL=${p2pport[$index]}
        export CHANNEL_PORT_VALUE_TPL=${channelPort[$index]}
        export CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL=${current_node_dir}/keys.info
        export CONFIG_JSON_KEYSTORE_DIR_PATH_TPL=${current_node_dir}/keystore/
        export CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL=${current_node_dir}/data/
        export CONFIG_JSON_FISCO_LOGCONF_DIR_PATH_TPL=${current_node_dir}/log.conf

        MYVARS='${CHANNEL_PORT_VALUE_TPL}:${CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL}:${CONFIG_JSON_LISTENIP_TPL}:${CRYPTO_MODE_TPL}:${CONFIG_JSON_RPC_PORT_TPL}:${CONFIG_JSON_P2P_PORT_TPL}:${CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL}:${CONFIG_JSON_KEYSTORE_DIR_PATH_TPL}:${CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL}:${CONFIG_JSON_FISCO_LOGCONF_DIR_PATH_TPL}'
        envsubst $MYVARS < ${DEPENDENCIES_TPL_DIR}/config.json.tpl > ${current_node_dir}/config.json

        generate_startsh=`generate_startsh_func`
        echo "${generate_startsh}" > ${current_node_dir}/start.sh
        generate_stopsh=`generate_stopsh_func`
        echo "${generate_stopsh}" > ${current_node_dir}/stop.sh
        generate_checksh_func=`generate_checksh_func`
        echo "${generate_checksh_func}" > ${current_node_dir}/check.sh

        chmod +x ${current_node_dir}/start.sh
        chmod +x ${current_node_dir}/stop.sh
        chmod +x ${current_node_dir}/check.sh

        i=$(($i+1))
    done

    cp $DEPENENCIES_SCRIPTES_DIR/start.sh $buildPWD/
    sudo chmod a+x $buildPWD/start.sh

    cp $DEPENENCIES_SCRIPTES_DIR/stop.sh $buildPWD/
    sudo chmod a+x $buildPWD/stop.sh

    cp $DEPENENCIES_SCRIPTES_DIR/check.sh $buildPWD/
    sudo chmod a+x $buildPWD/check.sh

    cp $DEPENENCIES_SCRIPTES_DIR/register.sh $buildPWD/
    sudo chmod a+x $buildPWD/register.sh

    cp $DEPENENCIES_SCRIPTES_DIR/unregister.sh $buildPWD/
    sudo chmod a+x $buildPWD/unregister.sh

    cp $DEPENENCIES_SCRIPTES_DIR/node_manager.sh $buildPWD/
    sudo chmod a+x $buildPWD/node_manager.sh

    #fisco-bcos
    cp $DEPENENCIES_FISCO_DIR/fisco-bcos $current_node_dir_base
    #chmod a+x fisco-bcos
    sudo chmod a+x $current_node_dir_base/fisco-bcos

    print_install_result "fisco-solc"

    # fisco-solc
    sudo cp $DEPENENCIES_DIR/solc/fisco-solc /usr/local/bin/
    sudo chmod a+x /usr/local/bin/fisco-solc

    #web3sdk config
    export WEB3SDK_CONFIG_IP=${listenip[0]}
    export WEB3SDK_CONFIG_PORT=${channelPort[0]}
    export WEB3SDK_SYSTEM_CONTRACT_ADDR=$(cat $DEPENENCIES_FOLLOW_DIR/syaddress.txt)
    export KEYSTORE_PWD=${keystore_pwd}
    export CLIENTCERT_PWD=${clientcert_pwd}
    MYVARS='${CLIENTCERT_PWD}:${KEYSTORE_PWD}:${WEB3SDK_CONFIG_IP}:${WEB3SDK_CONFIG_PORT}:${WEB3SDK_SYSTEM_CONTRACT_ADDR}'
    echo "WEB3SDK_CONFIG_PORT=${channelPort[0]}"
    echo "WEB3SDK_SYSTEM_CONTRACT_ADDR=$(cat $DEPENENCIES_FOLLOW_DIR/syaddress.txt)"
    echo "KEYSTORE_PWD="${KEYSTORE_PWD}
    echo "CLIENTCERT_PWD="${CLIENTCERT_PWD}
    envsubst $MYVARS < $DEPENENCIES_DIR/tpl_dir/applicationContext.xml.tpl > ${WEB3SDK_INSTALL_DIR}/conf/applicationContext.xml

    print_dash

    echo "    Installing fisco-bcos success!"

    #node js enviroment install
    install_node

    cp -r $DEPENENCIES_TOOL_DIR $buildPWD/
    cp -r $DEPENENCIES_SC_DIR $buildPWD/
    cp -r $DEPENENCIES_WEB3LIB_DIR $buildPWD/

    mkdir -p $buildPWD/web3lib/node_modules
    mkdir -p $buildPWD/tool/node_modules
    mkdir -p $buildPWD/systemcontract/node_modules
    tar --strip-components 1 -xzvf $DEPENENCIES_NODEJS_DIR/node_m*tar.gz -C $buildPWD/web3lib/node_modules/ >/dev/null 2>&1
    tar --strip-components 1 -xzvf $DEPENENCIES_NODEJS_DIR/node_m*tar.gz -C $buildPWD/tool/node_modules/ >/dev/null 2>&1
    tar --strip-components 1 -xzvf $DEPENENCIES_NODEJS_DIR/node_m*tar.gz -C $buildPWD/systemcontract/node_modules/ >/dev/null 2>&1

    #config.js
    cp $installPWD/dependencies/tpl_dir/config.js.tpl $buildPWD/web3lib/config.js
    sed -i.bu "s/ip:port/${listenip[0]}:${rpcport[0]}/g"  $buildPWD/web3lib/config.js

    #systemcontractv contract address
    cp $DEPENENCIES_FOLLOW_DIR/syaddress.txt $buildPWD/systemcontract/output/SystemProxy.address

    echo "    Installing fisco-bcos nodejs enviroment end!"

    return 0
}

install_build

