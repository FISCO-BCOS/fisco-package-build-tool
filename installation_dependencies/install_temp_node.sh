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
LD_LIBRARY_PATH=$LD_LIBRARY_PATH":/workspace/deploy_zldev_cpp_ethereum/dependencies/lib"

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
            error_msg "internal ip invalid ,ip is "$is_internal_ip_valid
        else
            error_msg "external ip invalid ,ip is "$is_external_ip_valid
        fi
    fi
}

#check_param $1 $2

source $installPWD/dependencies/config.sh

#创世块文件生成模板
#此模板会用来第一次生成genesis.json文件，后面导入合约后还会再导出新的genesis.json文件
function generate_genesisBlock()
{
    export TEMP_NODE_ID_TPL=$1
    export GOD_ACCOUNT_ID_TPL=$2

    MYVARS='${TEMP_NODE_ID_TPL}:${GOD_ACCOUNT_ID_TPL}'
    envsubst $MYVARS < ${TPL_DIR_PATH}/temp_node_genesis.json.tpl > $buildPWD/genesis.json
}


#后续节点配置生成模板
#根据config.sh和node1info.json生成
function generate_config_func()
{
    config_json="{
    \"sealEngine\":\"PBFT\",
    \"systemproxyaddress\":\"$DEFAULT_SYSTEM_CONTRACT_ADDRESS\",
    \"listenip\":\"${listenip1}\",
    \"rpcport\":\"${rpcport1}\",
    \"rpcsslport\":\"${RPC_SSL_PORT_TPL}\",
    \"channelPort\":\"${CHANNEL_PORT_VALUE_TPL}\",
    \"p2pport\":\"${p2pport1}\",
    \"wallet\":\"${buildPWD}/nodedir${Idx[$index]}/keys.info\",
    \"keystoredir\":\"${buildPWD}/nodedir${Idx[$index]}/keystore/\",
    \"datadir\":\"${buildPWD}/nodedir${Idx[$index]}/fisco-data/\",
    \"networkid\":\"${networkid}\",
    \"vm\":\"interpreter\",
    \"logverbosity\":\"4\",
    \"coverlog\":\"OFF\",
    \"eventlog\":\"ON\",
    \"params\": {
    \"accountStartNonce\": \"0x00\",
    \"maximumExtraDataSize\": \"0x0400\",
    \"tieBreakingGas\": false,
    \"blockReward\": \"0x14D1120D7B160000\",
    \"networkID\" : \"0x0\"},
    \"NodeextraInfo\":[    ${node1Info} {
    \"Nodeid\":\"${nodeid1}\",
    \"Nodedesc\": \"${Nodedesc1}\",
    \"Agencyinfo\": \"${Agencyinfo1}\",
    \"Peerip\": \"${Peerip1}\",
    \"Identitytype\": ${Identitytype1},
    \"Port\":${Port1},  
    \"Idx\":${Idx1} 
}	]
}"
echo "$config_json"
return 0
}

#为后续添加节点生成config.json提供创世节点信息
function generate_node1Json()
{
    config_node1_json="{
    \"Nodeid\":\"${nodeid1}\", 
    \"Nodedesc\": \"${Nodedesc1}\",
    \"Agencyinfo\": \"${Agencyinfo1}\",
    \"Peerip\": \"${Peerip1}\",
    \"Identitytype\": ${Identitytype1},
    \"Port\":${Port1},
    \"Idx\":${Idx1}
},"
echo "$config_node1_json"
return 0
}

#为后续添加节点提供配置信息
function generate_node_action_infoJson()
{
    config_node_action_info_json="{
    \"id\":\"${nodeid1}\", 
    \"desc\": \"${Nodedesc1}\",
    \"agencyinfo\": \"${Agencyinfo1}\",
    \"ip\": \"${Peerip1}\",
    \"category\": ${Identitytype1},
    \"port\":${Port1},
    \"CAhash\":\"\",
    \"idx\":${Idx1}
}"
echo "$config_node_action_info_json"
return 0
}


#停止脚本生成模板
function generate_stopsh()
{
    stopsh="#!/bin/bash
    weth_pid=\`ps aux|grep \"$buildPWD/nodedir${Idx[$index]}/config.json\"|grep -v grep|awk '{print \$2}'\`
    kill_cmd=\"kill -9 \${weth_pid}\"
    eval \${kill_cmd}"
    echo "$stopsh"
}


#generate start shell for node
function generate_startsh()
{
    startsh="#!/bin/bash
    ulimit -c unlimited
    nohup ./fisco-bcos  --genesis $buildPWD/genesis.json  --config $buildPWD/nodedir${Idx[$index]}/config.json  > $buildPWD/nodedir${Idx[$index]}/log/log 2>&1 &"
    echo "$startsh"
}

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
    #echo $NODE_PATH 
    #echo $NODE_HOME
}

function install_nodejs()
{
    print_install_result "nodejs"

    mkdir -p $buildPWD/nodejs/bin/
    cd $installPWD/dependencies/nodejs/
    tar --strip-components 1 -xzvf node-v*tar.gz -C $buildPWD/nodejs/ 1>>/dev/null

    build_node_sh

    cd $installPWD
    return 0
}


#本脚本安装后，使用ethconsole需要新开shell
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
}


#上传合约需要
#本脚本安装后，使用babel需要新开shell
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

function install_dependencies() 
{
    if grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        #sudo apt-get -y install cmake
        sudo apt-get -y install npm
        sudo apt-get -y install openssl
        sudo apt-get -y install libssl-dev libkrb5-dev
        sudo apt-get -y install nodejs-legacy
        sudo npm install -g cnpm --registry=https://registry.npm.taobao.org
        sudo cnpm install -g babel-cli babel-preset-es2017
        echo '{ "presets": ["es2017"] }' > ~/.babelrc
        sudo npm install -g secp256k1
    else
        #sudo yum -y install cmake3
        sudo yum -y install openssl openssl-devel
        sudo yum -y install nodejs
        sudo yum -y install npm
        sudo npm install -g cnpm --registry=https://registry.npm.taobao.org
        sudo cnpm install -g babel-cli babel-preset-es2017
        echo '{ "presets": ["es2017"] }' > ~/.babelrc
    fi
}

function build_follower_dependencies()
{
    cd $installPWD
    mkdir -p $FOLLOWER_DEPENENCIES_DIR/
    cp $buildPWD/genesis.json $FOLLOWER_DEPENENCIES_DIR/
    cp $buildPWD/node1info.json $FOLLOWER_DEPENENCIES_DIR/
    cp $buildPWD/syaddress.txt $FOLLOWER_DEPENENCIES_DIR/
    #cp $buildPWD/nodeactioninfo*.json $FOLLOWER_DEPENENCIES_DIR/
}

function build_follower_install_package()
{
    build_follower_dependencies

    cd $installPWD
    rm -rf $FOLLOWER_INSTALL_PACKAGE_NAME
    mkdir -p $FOLLOWER_INSTALL_PACKAGE_NAME
    cp -r dependencies/ $FOLLOWER_INSTALL_PACKAGE_NAME/
    cp fisco-bcos $FOLLOWER_INSTALL_PACKAGE_NAME/
    cp dependencies/install_normal_node.sh $FOLLOWER_INSTALL_PACKAGE_NAME/
    cp -r $buildPWD/followers_dependencies $FOLLOWER_INSTALL_PACKAGE_NAME/
    rm -f $FOLLOWER_INSTALL_PACKAGE_NAME/dependencies/install_normal_node.sh
    tar -czvf $FOLLOWER_INSTALL_PACKAGE_NAME".tar.gz" $FOLLOWER_INSTALL_PACKAGE_NAME/

    rm -rf $FOLLOWER_INSTALL_PACKAGE_NAME
}

function install()
{
    #chmod 777 $installPWD/* -R
    echo "    Installing temp fisco-bcos node start"
    request_sudo_permission
    ret=$?
    if [ $ret -ne 0 ]
    then
        return -1
    fi

    sudo chown -R $(whoami) $installPWD

    #install_dependencies

    ##install nodejs
    #type node >/dev/null 2>&1
    #ret=$?
    #if [ $ret -eq 0  ]
    #then
     #   ret=`node --version`
     #   print_install_result "nodejs"
     #   print_install_info "node already exist, nodejs version $ret"
    #else
    #    install_nodejs
    #fi

    #build_node_sh
    #source ~/.bashrc

    # install ethereum-console
    #if [ ! -d "$NODE_MODULES_DIR/ethereum-console" ]; then
    #    install_ethconsole
    #else
    #    print_install_result "ethconsole"
    #    print_install_info "ethereum-console already exist"
    #fi

    # install babel
    #if [ ! -d "$NODE_MODULES_DIR/babel-cli" ]; then
    #    install_babel
    #else
    #    print_install_result "babel.js"
    #    print_install_info "babel already exist"
    #fi

    #install_baseDeploy

    local current_host_rlp_dir=$installPWD/dependencies/rlp_dir
    mkdir -p $current_host_rlp_dir/

    node_index=0
    while [ $node_index -lt $nodecount ]
    do
        #index=$(($node_index-1))
        index=$node_index
        mkdir -p $buildPWD/nodedir${Idx[$index]}/
        mkdir -p $buildPWD/nodedir${Idx[$index]}/log
        mkdir -p $buildPWD/nodedir${Idx[$index]}/keystore
        mkdir -p $buildPWD/nodedir${Idx[$index]}/fisco-data
        cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/network.rlp $buildPWD/nodedir${Idx[$index]}/fisco-data/
        cp $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/network.rlp.pub $buildPWD/nodedir${Idx[$index]}/fisco-data/

        listenip1=${listenip[$index]}
        rpcport1=${rpcport[$index]}
        RPC_SSL_PORT_TPL=${rpcsslport[$index]}
        CHANNEL_PORT_VALUE_TPL=${channelPort[$index]}
        p2pport1=${p2pport[$index]}
        Nodedesc1=${Nodedesc[$index]}
        Agencyinfo1=${Agencyinfo[$index]}
        Peerip1=${Peerip[$index]}
        Identitytype1=${Identitytype[$index]}
        Port1=${Port[$index]}
        Idx1=${Idx[$index]}

        #port checkcheck
        check_port $rpcport1
        if [ $? -ne 0 ];then
            error_msg "temp node rpc port check, $rpcport1 is in use."
            #exit 1
        fi
        check_port $RPC_SSL_PORT_TPL
        if [ $? -ne 0 ];then
            error_msg "temp node ssl port check, $RPC_SSL_PORT_TPL is in use."
            #exit 1
        fi
        check_port $CHANNEL_PORT_VALUE_TPL
        if [ $? -ne 0 ];then
            error_msg "temp node channel port check, $CHANNEL_PORT_VALUE_TPL is in use."
            #exit 1
        fi
        check_port $p2pport1
        if [ $? -ne 0 ];then
            error_msg "temp node p2p port check, $p2pport1 is in use."
            #exit 1
        fi

        if [ $node_index -eq 0 ];
        then
            nodeid1=$(cat $buildPWD/nodedir${Idx[$index]}/fisco-data/network.rlp.pub)
            generate_genesisBlock ${nodeid1} ${god}
            #genesisKey_json=`generate_genesisBlock`
            #echo "${genesisKey_json}" > $buildPWD/genesis.json
            #cat $buildPWD/genesis.json

            node1Info=""
            generate_config_str=`generate_config_func`
            echo "${generate_config_str}" > $buildPWD/nodedir${Idx[$index]}/config.json
            generate_node1Json=`generate_node1Json`
            echo "${generate_node1Json}" > $buildPWD/node1info.json

            export JTOOL_CONFIG_PORT=${CHANNEL_PORT_VALUE_TPL}
            export JTOOL_SYSTEM_CONTRACT_ADDR="0x919868496524eedc26dbb81915fa1547a20f8998"
            MYVARS='${JTOOL_CONFIG_PORT}:${JTOOL_SYSTEM_CONTRACT_ADDR}'
            envsubst $MYVARS < $DEPENENCIES_DIR/tpl_dir/applicationContext.xml.tpl > $DEPENENCIES_DIR/jtool/conf/applicationContext.xml
            echo "${DEPENENCIES_DIR}/tpl_dir/applicationContext.xml.tpl > ${DEPENENCIES_DIR}/jtool/conf/applicationContext.xml"

        else
            nodeid1=$(cat $buildPWD/nodedir${Idx[$index]}/fisco-data/network.rlp.pub)
            node1Info=$(cat $buildPWD/node1info.json)
            generate_configFollow=`generate_config_func`
            echo "${generate_configFollow}" > $buildPWD/nodedir${Idx[$index]}/config.json
        fi

        generate_node_action_infoJson=`generate_node_action_infoJson`
        echo "${generate_node_action_infoJson}" > $buildPWD/nodeactioninfo${Idx[$index]}.json

        generate_startsh=`generate_startsh`
        echo "${generate_startsh}" > $installPWD/start_node${Idx[$index]}.sh
        generate_stopsh=`generate_stopsh`
        echo "${generate_stopsh}" > $installPWD/stop_node${Idx[$index]}.sh
        chmod +x $installPWD/fisco-bcos
        chmod +x $installPWD/start_node${Idx[$index]}.sh
        chmod +x $installPWD/stop_node${Idx[$index]}.sh

        # copy server.key and server.pem
        #/workspace/weth-package-build-tool/installation_dependencies/dependencies/info
        cp ${KEY_INFO_DIR_PATH}/server.key $buildPWD/nodedir${Idx[$index]}/fisco-data/
        cp ${KEY_INFO_DIR_PATH}/server.crt $buildPWD/nodedir${Idx[$index]}/fisco-data/
        cp ${KEY_INFO_DIR_PATH}/ca.crt $buildPWD/nodedir${Idx[$index]}/fisco-data/

        node_index=$(($node_index+1))
    done

    cd $installPWD
    ./start_node${Idx[0]}.sh

    echo "    Loading genesis file : "
    $DEPENENCIES_DIR/scripts/percent_num_progress_bar.sh 24 &
    sleep 24

    #ps -ef|grep fisco-bcos

    cd $installPWD/dependencies/web3lib/
    cp ../tpl_dir/config.js.tpl config.js
    sed -i "s/ip:port/${listenip[0]}:${rpcport[0]}/g"  $installPWD/dependencies/web3lib/config.js

    #deploy system contract
    cd $installPWD/dependencies/jtool/bin
    chmod a+x system_contract_tools.sh
    ./system_contract_tools.sh DeploySystemContract

    cp output/SystemProxy.address $buildPWD/syaddress.txt
    syaddress=$(cat $buildPWD/syaddress.txt)

    if [ -z $syaddress ];then
        error_msg "syaddress null"
    fi

    #替换系统合约地址 0x9198684965s24eedc26dbb81915fa1547a20f8998 
    sed -i "s/0x919868496524eedc26dbb81915fa1547a20f8998/$syaddress/g" ../conf/applicationContext.xml

    echo "system contract deployed ,SystemProxy.address is "${syaddress}
    echo "jtool conf = "$(cat ../conf/applicationContext.xml)

    cd $installPWD
    j=0
    #替换系统合约地址
    while [ $j -lt $nodecount ]
    do
        sed -i "s/$DEFAULT_SYSTEM_CONTRACT_ADDRESS/$syaddress/g" $buildPWD/nodedir${Idx[$j]}/config.json
        j=$(($j+1))
    done

    #$DEPENENCIES_DIR/scripts/percent_num_progress_bar.sh 6 &
    #sleep 6
    ./stop_node${Idx[0]}.sh

    cd $installPWD
    echo "    Installing temp node fisco-bcos success!"
    return 0
}

#   4、节点启动后,需要通过节点管理将节点动态添加入链（为了安全此步骤手动执行）
function info() {
echo "install Information:"
echo "****************************"
echo "Usage: $1 {install|info}"
echo "****************************"
}

case "$1" in
    'install')
        install
        ;;
    'info')
        info $0
        ;;
    *)
        echo "invalid option!"
        echo "Usage: $0 {install|info}"
esac

