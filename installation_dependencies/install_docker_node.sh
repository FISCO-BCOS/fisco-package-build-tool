#!/bin/bash

#set -x
#set -e

#public config
installPWD=$PWD
dockerPWD=$installPWD/docker/
DEPENENCIES_DIR=$installPWD/dependencies
source $DEPENENCIES_DIR/scripts/utils.sh
source $DEPENENCIES_DIR/scripts/public_config.sh
source $DEPENENCIES_DIR/scripts/dependencies_install.sh
source $DEPENENCIES_DIR/scripts/dependencies_check.sh

source $DEPENENCIES_DIR/config.sh
g_is_genesis_host=${is_genesis_host}

g_docker_repository=${docker_repository}

g_docker_ver=${docker_version}

g_docker_fisco_path="/fisco-bcos/node/"

echo "docker repository => "${g_docker_repository}
echo "docker version => "${g_docker_ver}

# build register_node*.sh
function generate_registersh_func()
{
    registersh="#!/bin/bash
    sudo docker exec fisco-node$index"_"${rpcport[$index]} bash -c \"source /etc/profile && cd /fisco-bcos && bash node_manager.sh registerNode /fisco-bcos/node/data/node.json\"
    "
    echo "$registersh"
    return 0
}

# build unregister_node*.sh
function generate_unregistersh_func()
{
    registersh="#!/bin/bash
    sudo docker exec fisco-node$index"_"${rpcport[$index]} bash -c \"source /etc/profile && cd /fisco-bcos && bash node_manager.sh cancelNode /fisco-bcos/node/data/node.json\"
    "
    echo "$registersh"
    return 0
}

# build start_node*.sh
function generate_startsh_func()
{
    startsh="#!/bin/bash
    fisco-bcos   --genesis /fisco-bcos/node/genesis.json --config /fisco-bcos/node/config.json 2>&1 
    echo \"waiting...\"
    sleep 5
    "
    echo "$startsh"
    return 0
}

# build stop_docker_node*.sh
function generate_stopsh_docker_func()
{
    stopsh="#!/bin/bash
    container_id=\`sudo docker ps -a --filter name=fisco-node$index"_"${rpcport[$index]} | egrep -v \"CONTAINER ID\" | awk '{print \$1}'\`
    if [ -z \${container_id} ];then
        echo \"cannot find container, container name is fisco-node\"$index"_"${rpcport[$index]}
    else
        sudo docker stop \${container_id}
    fi"
    echo "$stopsh"
    return 0
}

# build start_docker_node*.sh
function generate_startsh_docker_func()
{
    startsh="#!/bin/bash
    container_id=\`sudo docker ps -a --filter name=fisco-node$index"_"${rpcport[$index]} | egrep -v \"CONTAINER ID\" | awk '{print \$1}'\`
    echo \"start node${Idx[$index]} ...\"
    if [ -z \${container_id} ];then
        sudo docker run -d -v \`pwd\`/node$index:/fisco-bcos/node --name=fisco-node$index"_"${rpcport[$index]} --net=host -i ${g_docker_repository}:${g_docker_ver} /fisco-bcos/start_node.sh
    else
        sudo docker start \${container_id}
    fi"
    echo "$startsh"
    return 0
}

# build start_all.sh
function generate_startallsh_func()
{
    startallsh="#!/bin/bash
    i=0
    while [ \$i -lt $nodecount ]
    do
        bash start\$i.sh
        sleep 3
        i=\$((\$i+1))
    done"
    echo "$startallsh"
    return 0
}

# build stop_all.sh
function generate_stopallsh_func()
{
    stoptallsh="#!/bin/bash
    i=0
    while [ \$i -lt $nodecount ]
    do
        bash stop\$i.sh
        i=\$((\$i+1))
    done"
    echo "$stoptallsh"
    return 0
}

function install()
{
    echo "    Installing fisco-bcos docker environment start"
    request_sudo_permission

    sudo chown -R $(whoami) $installPWD

    if [ -d $dockerPWD ];then
        error_message "docker dictionary already exist, remove it first."
    fi

    # check if docker install
    check_if_install docker

    sudo docker pull $g_docker_repository:$g_docker_ver
    if [ $? -ne 0 ];then
        error_message "docker pull failed , docker service not start or repository、version info error,repository : $g_docker_repository ,version : $g_docker_ver"
    fi

    if [ -z $nodecount ] ||[ $nodecount -le 0 ]; then
        error_message "there has no node on this server, count is "$nodecount
    fi

    print_dash

    simple_dependencies_install

    i=0
    while [ $i -lt $nodecount ]
    do
	    index=$i
        container_id=`sudo docker ps -a --filter name=fisco-node$index"_"${rpcport[$index]} | egrep -v "CONTAINER ID" | awk '{print $1}'`
        # echo "check if fisco-node$index"_"${rpcport[$index]} exist."
        if [ -z ${container_id} ];then
	    i=$(($i+1))
            continue
        else
            error_message "there is already fisco-bcos docker named fisco-node"$index"_"${rpcport[$index]}" ,container_id is "$container_id
        fi
	    i=$(($i+1))
    done

    i=0
    while [ $i -lt $nodecount ]
    do
        index=$i
        mkdir -p $dockerPWD/node${Idx[$index]}/
        mkdir -p $dockerPWD/node${Idx[$index]}/log/
        mkdir -p $dockerPWD/node${Idx[$index]}/keystore/
        mkdir -p $dockerPWD/node${Idx[$index]}/data/
        mkdir -p $dockerPWD/node${Idx[$index]}/ext/
        mkdir -p $dockerPWD/node${Idx[$index]}/ext/conf
        mkdir -p $dockerPWD/node${Idx[$index]}/ext/script

        if [ $i -eq 0 ];then
            if [ $g_is_genesis_host -eq 1 ];then
                cp $DEPENDENCIES_TPL_DIR/empty_bootstrapnodes.json $dockerPWD/node${Idx[$index]}/data/bootstrapnodes.json >/dev/null 2>&1
            else
                cp $DEPENENCIES_FOLLOW_DIR/bootstrapnodes.json $dockerPWD/node${Idx[$index]}/data/ >/dev/null 2>&1
            fi
        else    
            cp $DEPENENCIES_FOLLOW_DIR/bootstrapnodes.json $dockerPWD/node${Idx[$index]}/data/ >/dev/null 2>&1
        fi


        cp -r $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/sdk $dockerPWD/node${Idx[$index]}/ext/
        cp -r $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/node/ $dockerPWD/node${Idx[$index]}/ext/
        cp $DEPENENCIES_FOLLOW_DIR/genesis.json $dockerPWD/node${Idx[$index]}/ >/dev/null 2>&1
        cp $DEPENENCIES_FOLLOW_DIR/syaddress.txt $dockerPWD/node${Idx[$index]}/ext/conf/ >/dev/null 2>&1
        cp $DEPENENCIES_DIR/scripts/docker_init.sh $dockerPWD/node${Idx[$index]}/ext/script/ >/dev/null 2>&1

        cp $DEPENENCIES_DIR/scripts/node_manager.sh $dockerPWD/node${Idx[$index]}/
        sudo chmod a+x $dockerPWD/node${Idx[$index]}/node_manager.sh

        cd $DEPENDENCIES_RLP_DIR/node_rlp_${Idx[$index]}/ca/node/
        nodeid=$(cat node.nodeid)
        echo "node id is "$nodeid

        #web3sdk config
        export WEB3SDK_CONFIG_IP=${listenip[$index]}
        export WEB3SDK_CONFIG_PORT=${channelPort[$index]}
        export WEB3SDK_SYSTEM_CONTRACT_ADDR=$(cat $DEPENENCIES_FOLLOW_DIR/syaddress.txt)
        export KEYSTORE_PWD=${keystore_pwd}
        export CLIENTCERT_PWD=${clientcert_pwd}
        MYVARS='${CLIENTCERT_PWD}:${KEYSTORE_PWD}:${WEB3SDK_CONFIG_IP}:${WEB3SDK_CONFIG_PORT}:${WEB3SDK_SYSTEM_CONTRACT_ADDR}'
        echo "WEB3SDK_CONFIG_PORT=${channelPort[$index]}"
        echo "WEB3SDK_SYSTEM_CONTRACT_ADDR=$(cat $DEPENENCIES_FOLLOW_DIR/syaddress.txt)"
        echo "KEYSTORE_PWD="${KEYSTORE_PWD}
        echo "CLIENTCERT_PWD="${CLIENTCERT_PWD}
        envsubst $MYVARS < $DEPENENCIES_DIR/tpl_dir/applicationContext.xml.tpl > $dockerPWD/node${Idx[$index]}/ext/conf/applicationContext.xml

        # generate log.conf from tpl
        export OUTPUT_LOG_FILE_PATH_TPL=${g_docker_fisco_path}"log"
        MYVARS='${OUTPUT_LOG_FILE_PATH_TPL}'
        envsubst $MYVARS < ${DEPENDENCIES_TPL_DIR}/log.conf.tpl > $dockerPWD/node${Idx[$index]}/log.conf

        export CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL=$(cat $DEPENENCIES_FOLLOW_DIR/syaddress.txt)
        export CONFIG_JSON_LISTENIP_TPL=${listenip[$index]}
        export CRYPTO_MODE_TPL=${crypto_mode}
        export CONFIG_JSON_RPC_PORT_TPL=${rpcport[$index]}
        export CONFIG_JSON_P2P_PORT_TPL=${p2pport[$index]}
        export CHANNEL_PORT_VALUE_TPL=${channelPort[$index]}

        export CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL=${g_docker_fisco_path}"keys.info"
        export CONFIG_JSON_KEYSTORE_DIR_PATH_TPL=${g_docker_fisco_path}"keystore/"
        export CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL=${g_docker_fisco_path}"data/"
        export CONFIG_JSON_FISCO_LOGCONF_DIR_PATH_TPL=${g_docker_fisco_path}log.conf

        MYVARS='${CHANNEL_PORT_VALUE_TPL}:${CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL}:${CONFIG_JSON_LISTENIP_TPL}:${CRYPTO_MODE_TPL}:${CONFIG_JSON_RPC_PORT_TPL}:${CONFIG_JSON_P2P_PORT_TPL}:${CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL}:${CONFIG_JSON_KEYSTORE_DIR_PATH_TPL}:${CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL}:${CONFIG_JSON_FISCO_LOGCONF_DIR_PATH_TPL}'
        envsubst $MYVARS < ${DEPENDENCIES_TPL_DIR}/config.json.tpl > $dockerPWD/node${Idx[$index]}/config.json

        #config.js
        cp $installPWD/dependencies/tpl_dir/config.js.tpl $dockerPWD/node${Idx[$index]}/ext/conf/config.js
        sed -i.bu "s/ip:port/${listenip[$index]}:${rpcport[$index]}/g"  $dockerPWD/node${Idx[$index]}/ext/conf/config.js

        generate_startsh=`generate_startsh_docker_func`
        echo "${generate_startsh}" > $dockerPWD/start${Idx[$index]}.sh
        generate_stopsh=`generate_stopsh_docker_func`
        echo "${generate_stopsh}" > $dockerPWD/stop${Idx[$index]}.sh

        sudo chmod +x $dockerPWD/start${Idx[$index]}.sh
        sudo chmod +x $dockerPWD/stop${Idx[$index]}.sh

        generate_sh=`generate_startsh_func`
        echo "${generate_sh}" > $dockerPWD/node${Idx[$index]}/start.sh
        sudo chmod +x $dockerPWD/node${Idx[$index]}/start.sh
	
	    register_sh=`generate_registersh_func`
        echo "${register_sh}" > $dockerPWD/register${Idx[$index]}.sh
	    sudo chmod +x $dockerPWD/register${Idx[$index]}.sh

        unregister_sh=`generate_unregistersh_func`
        echo "${unregister_sh}" > $dockerPWD/unregister${Idx[$index]}.sh
	    sudo chmod +x $dockerPWD/unregister${Idx[$index]}.sh

        i=$(($i+1))
    done

    generate_startallsh=`generate_startallsh_func`
    echo "${generate_startallsh}" > $dockerPWD/start.sh
    sudo chmod a+x $dockerPWD/start.sh

    generate_stopallsh=`generate_stopallsh_func`
    echo "${generate_stopallsh}" > $dockerPWD/stop.sh
    sudo chmod a+x $dockerPWD/stop.sh

    cd $installPWD

    print_dash

    echo "  Installing docker fisco-bcos end!"

    return 0
}

function info()
{
    echo "install Information:"
    echo "****************************"
    echo "If can not start the fisco-bcos process, check your genesis.json, config.sh config.json, syaddress.txt and genesis_node_info.json file."
    echo "****************************"
}

install
