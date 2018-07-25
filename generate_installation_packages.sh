#!/bin/bash

set -e

IS_DEBUG=0
function toggle_debug()
{
    IS_DEBUG=1
    mkdir -p build/
    #exec 1>>build/stdout.txt
    exec 2>>build/stderr.log
    #BASH_XTRACEFD="5"s
    PS4='$LINENO: '
    #set -x
}

#toggle_debug

#public config
UNDER_LINE_STR="_"
installPWD=$PWD
INSTALLATION_DEPENENCIES_LIB_DIR_NAME=installation_dependencies
INSTALLATION_DEPENENCIES_EXT_DIR_NAME=ext
INSTALLATION_DEPENENCIES_LIB_DIR=$installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME
INSTALLATION_DEPENENCIES_EXT_DIR=$installPWD/$INSTALLATION_DEPENENCIES_EXT_DIR_NAME

source $installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME/dependencies/scripts/utils.sh
source $installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME/dependencies/scripts/public_config.sh
source $installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME/dependencies/scripts/os_version_check.sh
source $installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME/dependencies/scripts/dependencies_version_check.sh

#private config
source $PWD/installation_config.sh
CACHE_DIR_PATH=$installation_build_dir/.cache_dir
INITIALIZATION_DONE_FILE_PATH=$CACHE_DIR_PATH/initialization_done
RPC_PORT_DEFAULT_VALUE=$(($RPC_PORT_FOR_TEMP_NODE+1))
P2P_PORT_DEFAULT_VALUE=$(($P2P_PORT_FOR_TEMP_NODE+1))
CHANNEL_PORT_DEFAULT_VALUE=$(($CHANNEL_PORT_FOR_TEMP_NODE+1))
PORT_DEFAULT_VALUE=$(($P2P_PORT_FOR_TEMP_NODE+1))
TEMP_NODE_NAME="temp"
TEMP_BUILD_DIR=$installation_build_dir/$TEMP_NODE_NAME/build
TARGET_ETH_PATH=/usr/local/bin/fisco-bcos

#openssl 1.0.2+ be requied.
function check_openssl()
{
    type openssl >/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "openssl is not installed, OpenSSL 1.0.2+ be requied."
        return 1
    fi

    #openssl version
    OPENSSL_VER=$(openssl version 2>&1 | sed -n ';s/.*OpenSSL \(.*\)\.\(.*\)\.\([0-9]*\).*/\1\2\3/p;')

    #openssl 1.0.2+
    if [ $OPENSSL_VER -ge 102 ];then
        return 0
    fi

    echo "openssl 1.0.2 be requied."
    echo "now openssl is "
    echo `openssl version`
    return 2
}

#fisco-bcos version check, At least 1.3.0 is required
function fisco_bcos_version_check()
{
    REQUIRE_VERSION=$1;
    # config fisco-bcos version check

    FISCO_VERSION=$(${TARGET_ETH_PATH} --version 2>&1 | egrep "FISCO-BCOS *version" | awk '{print $3}')
    # FISCO BCOS gm version not support
    if  echo "$FISCO_VERSION" | egrep "gm" ; then
        echo "FISCO BCOS gm version not support yet."
        return 1
    fi 

    # fisco bcos 1.3.0+
    ver=$(echo "$FISCO_VERSION" | awk -F . '{print $1$2}')
    if [ $ver -lt 13 ];then
        echo "At least FISCO-BCOS 1.3.0 is required."
        echo "now fisco-bcos is $FISCO_VERSION"
        return 2
    fi

    #do not need specified version
    if [ -z "$REQUIRE_VERSION" ];then
        return 0
    fi

    # version compare
    ver0=$(echo "$FISCO_VERSION" | awk -F . '{print $1"."$2"."$3}')
    if [ "v$ver0" = "$REQUIRE_VERSION" ] || [ "V$ver0" = "$REQUIRE_VERSION" ];then
        return 0
    fi

    echo "REQUIRE_VERSION is $REQUIRE_VERSION"
    echo "now fisco bcos version is $FISCO_VERSION"

    return 3
}

#Oracle JDK 1.8 be requied.
function check_java_env()
{
    type java >/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "java is not installed, Oracle JDK 1.8 be requied."
        return 1
    fi

    #JAVA version
    JAVA_VER=$(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*".*/\1\2/p;')
    #Oracle JDK 1.8
    if [ $JAVA_VER -ge 18 ] && [[ $(java -version 2>&1 | grep "TM") ]];then
        return 0
    fi

    echo "Oracle JDK 1.8 be requied."
    echo "now JDK is "
    echo `java -version`
    return 2
} 

# global variable
function init_global_variable()
{
    g_host_config_num=${#MAIN_ARRAY[@]}

    echo "host_config_num = "$g_host_config_num

    g_status_process=${PROCESS_INITIALIZATION}

    if [ -f $CACHE_DIR_PATH/g_genesis_node_info_path ]
    then
        g_genesis_node_info_path=$(cat $CACHE_DIR_PATH/g_genesis_node_info_path)
    else
        g_genesis_node_info_path=""
    fi

    #cert dictionary
    g_genesis_cert_dir_path=""
    if [ -f $CACHE_DIR_PATH/g_genesis_cert_dir_path ]
    then
        g_genesis_cert_dir_path=$(cat $CACHE_DIR_PATH/g_genesis_cert_dir_path)
    else
        g_genesis_cert_dir_path=""
    fi
}

function replace_dot_with_underline()
{
    echo $1 | sed -e "s/\./_/g"
}

function get_node_dir_name()
{
    local host_type_local=$1
    local public_ip_underline_local=$2
    local private_ip_underline_local=$3

    if [ $host_type_local -eq $TYPE_TEMP_HOST ]
    then
        node_dir_name_local=$TEMP_NODE_NAME
    elif [ $host_type_local -eq $TYPE_GENESIS_HOST ]
    then
        node_dir_name_local=$public_ip_underline_local"_with_"$private_ip_underline_local"_genesis_installation_package"
    else
        node_dir_name_local=$public_ip_underline_local"_with_"$private_ip_underline_local"_installation_package"
    fi
    echo $node_dir_name_local
}

function copy_genesis_related_info()
{
    local public_ip=$1
    local private_ip=$2
    #local node_num_per_host=$3
    local host_type=$4

    public_ip_underline=$(replace_dot_with_underline $public_ip)
    private_ip_underline=$(replace_dot_with_underline $private_ip)

    # do nothing if the node installation package is already created
    if [ -f $CACHE_DIR_PATH/$public_ip_underline ]
    then
        echo "$CACHE_DIR_PATH/$public_ip_underline exist, it means the installation package is already created!"
        echo "if you insist on, you can force remove this file, and try again!"
        return 2
    else
        expand_node_num=$(($expand_node_num+1))
        touch $CACHE_DIR_PATH/$public_ip_underline
    fi

    #create node dir
    #node_dir_name=$public_ip_underline"_with_"$private_ip_underline"_installation_package"
    node_dir_name=$(get_node_dir_name $host_type $public_ip $private_ip)
    current_node_path=$installation_build_dir/$node_dir_name

    if [ $host_type -ne $TYPE_TEMP_HOST ]
    then
        #copy genesis json file to node dir
        build_base_info_dir $current_node_path
    fi
}

#build node for node of the server
function build_node_ca()
{
    agency=$1
    node=$2
    src=$3
    dst=$4

    echo "agency => "$agency
    echo "node => "$node
    echo "dst => "$dst

    local ext_dir=${INSTALLATION_DEPENENCIES_EXT_DIR}/cert/
    bash $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies/cert/ext.sh $agency $node ${ext_dir}
    cd $ext_dir
    if [ ! -f ${ext_dir}/$agency/$node/node.nodeid ];then
        echo "node.nodeid is not exist, agency => $agency, node => $node"
        return 2
    fi

    cp ${ext_dir}/ca.crt $dst/node 2>/dev/null
    cp ${ext_dir}/$agency/agency.crt $dst/node 2>/dev/null

    mkdir -p $dst/node
    cp ${ext_dir}/$agency/$node/node* $dst/node

    return 0
}

#create node for node of the server
function create_node_ca()
{
    agency=$1
    node=$2
    src=$3
    dst=$4

    echo "agency => "$agency
    echo "node => "$node
    echo "src => "$src
    echo "dst => "$dst

    cd $src

    bash chain.sh 1>/dev/null #ca for chain
    if [ ! -f "ca.key" ]; then
        echo "ca.key is not exist, maybe \" bash chain.sh \" failed."
        return 2
    elif [ ! -f "ca.crt" ]; then
        echo "ca.crt is not exist, maybe \" bash chain.sh \" failed."
        return 2
    fi

    bash agency.sh $agency 1>/dev/null #ca for agent
    if [ ! -d $agency ]; then
        echo "$agency dir is not exist, maybe \" bash agency.sh $agency\" failed."
        return 2
    fi

    bash node.sh $agency $node 1>/dev/null #ca for node
    if [ ! -d $agency/$node ]; then
        echo "$agency/$node dir is not exist, maybe \" bash node.sh $agency $node \" failed."
        return 2
    fi

    bash sdk.sh $agency "sdk" 1>/dev/null #ca for sdk
    if [ ! -d $agency/sdk ]; then
        echo "$agency/sdk dir is not exist, maybe \" bash sdk.sh $agency sdk \" failed."
        return 2
    fi

    mkdir -p $dst/node
    cp $agency/$node/* $dst/node
    mv $agency/sdk $dst

    return 0
}

#create install packag for every node of the server
function build_node_installation_package()
{
    local public_ip=$1
    local private_ip=$2
    local node_num_per_host=$3
    local host_type=$4
    local agent_info=$5

    echo "build_node_installation_package =>"
    echo "p2p_ip = "$public_ip
    echo "listen_ip = "$private_ip
    echo "node_num = "$node_num_per_host
    echo "host_type = "$host_type
    echo "agent_info = "$agent_info

    public_ip_underline=$(replace_dot_with_underline $public_ip)
    private_ip_underline=$(replace_dot_with_underline $private_ip)

    #create node dir
    if [ $host_type -eq $TYPE_TEMP_HOST ]
    then
        alert_msg="temp node is already exist."
    elif [ $host_type -eq $TYPE_GENESIS_HOST ]
    then
        alert_msg="$current_node_path is already exist, it means the installation package for ip($public_ip with $private_ip) have already build. "
    else
        alert_msg="$current_node_path is already exist, it means the installation package for ip($public_ip with $private_ip) have already build. "
    fi

    node_dir_name=$(get_node_dir_name $host_type $public_ip $private_ip)
    current_node_path=$installation_build_dir/$node_dir_name

    if [ -d $current_node_path ]
    then
        echo $alert_msg
        return 0
    fi

    mkdir -p $current_node_path/
    mkdir -p $current_node_path/dependencies/
    mkdir -p $current_node_path/dependencies/fisco-bcos
    mkdir -p $current_node_path/dependencies/follow/
    mkdir -p $current_node_path/dependencies/rlp_dir/

    cp $TARGET_ETH_PATH $current_node_path/dependencies/fisco-bcos/
    cp -r $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies $current_node_path/

    if [ $host_type -eq $TYPE_TEMP_HOST ]
    then
        cp $INSTALLATION_DEPENENCIES_LIB_DIR/install_temp_node.sh $current_node_path/
        chmod +x $current_node_path/install_temp_node.sh
    elif [ $host_type -eq $TYPE_GENESIS_HOST ]
    then
        export IS_GENESIS_HOST_TPL=1
        if [ ! -z ${IS_BUILD_FOR_DOCKER} ] && [ ${IS_BUILD_FOR_DOCKER} -eq 1 ];then
            envsubst '${IS_GENESIS_HOST_TPL}' < $INSTALLATION_DEPENENCIES_LIB_DIR/install_docker_node.sh.tpl > $current_node_path/install_node.sh
            chmod +x $current_node_path/install_node.sh
        else
            envsubst '${IS_GENESIS_HOST_TPL}' < $INSTALLATION_DEPENENCIES_LIB_DIR/install_node.sh.tpl > $current_node_path/install_node.sh
            chmod +x $current_node_path/install_node.sh
        fi

        # copy node_manager.sh
        cp $INSTALLATION_DEPENENCIES_LIB_DIR/node_manager.sh -p $current_node_path/dependencies/follow/

        # create "i am genesis node" file, the genesis node will contain this file in his root dir.
        touch $current_node_path/.i_am_genesis_host

        #g_genesis_node_action_container_dir_path=$current_node_path/node_action_info_dir
        #mkdir -p ${g_genesis_node_action_container_dir_path}/
        #echo ${g_genesis_node_action_container_dir_path} > $CACHE_DIR_PATH/g_genesis_node_action_container_dir_path

        g_genesis_cert_dir_path=$current_node_path/dependencies/cert
        echo ${g_genesis_cert_dir_path} > $CACHE_DIR_PATH/g_genesis_cert_dir_path

        #copy god info to address
        if [ -f $TEMP_BUILD_DIR/godInfo.txt ];then
            mv $TEMP_BUILD_DIR/godInfo.txt ${g_genesis_cert_dir_path} >/dev/null 2>&1
        fi
    else 
        # copy node_manager.sh
        cp $INSTALLATION_DEPENENCIES_LIB_DIR/node_manager.sh -p $current_node_path/dependencies/follow/
        if [ ! -z ${IS_BUILD_FOR_DOCKER} ] && [ ${IS_BUILD_FOR_DOCKER} -eq 1 ];then
            envsubst '${IS_GENESIS_HOST_TPL}' < $INSTALLATION_DEPENENCIES_LIB_DIR/install_docker_node.sh.tpl > $current_node_path/install_node.sh
            chmod +x $current_node_path/install_node.sh
        else
            envsubst '${IS_GENESIS_HOST_TPL}' < $INSTALLATION_DEPENENCIES_LIB_DIR/install_node.sh.tpl > $current_node_path/install_node.sh
            chmod +x $current_node_path/install_node.sh
        fi
    fi

    listen_ip_list_str=""
    rpc_port_list_str=""
    channel_port_list_str=""
    p2p_port_list_str=""
    node_desc_list_str=""
    agent_info_list_str=""
    idx_list_str=""

    local current_host_rlp_dir=$current_node_path/dependencies/rlp_dir
    mkdir -p $current_host_rlp_dir/

    node_index=0
    while [ $node_index -lt $node_num_per_host ]
    do
        current_node_rlp_dir=$current_node_path/dependencies/rlp_dir/node_rlp_$node_index
        mkdir -p $current_node_rlp_dir/
        mkdir -p $current_node_rlp_dir/ca/
        
        node_name=$public_ip_underline"_"$node_index
        if [ $host_type -eq $TYPE_TEMP_HOST ];then
            node_cert_path=$current_node_path/dependencies/cert/
            node_ca_path=$current_node_rlp_dir/ca/
            create_node_ca $agent_info $node_name ${node_cert_path} ${node_ca_path}
            if [ $? -ne 0 ];then
                return 2;
            fi
        else
            node_cert_path=${g_genesis_cert_dir_path}
            node_ca_path=$current_node_rlp_dir/ca/
            if [ ! -z ${IS_CA_EXT_MODE} ] && [ ${IS_CA_EXT_MODE} -eq 1 ];then
                build_node_ca $agent_info $node_name ${node_cert_path} ${node_ca_path}
                if [ $? -ne 0 ];then
                    return 2;
                fi
            else
                create_node_ca $agent_info $node_name ${node_cert_path} ${node_ca_path}
                if [ $? -ne 0 ];then
                    return 2;
                fi
            fi
        fi

        if [ $node_index -eq $(($node_num_per_host-1)) ]
        then
            delim_str=""
        else
            delim_str=" "
        fi

        listen_ip_list_str=$listen_ip_list_str"$private_ip"$delim_str

        if [ $host_type -eq $TYPE_TEMP_HOST ]
        then
            rpc_port=$RPC_PORT_FOR_TEMP_NODE
            channel_port=$CHANNEL_PORT_FOR_TEMP_NODE
            p2p_port=$P2P_PORT_FOR_TEMP_NODE
            node_desc="$public_ip"$UNDER_LINE_STR"temp"

            export HOST_IP=$public_ip
            export HOST_PORT=$p2p_port

            MYVARS='${HOST_IP}:${HOST_PORT}'
            envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/bootstrapnodes.json.tpl > $installation_build_dir/$node_dir_name/dependencies/rlp_dir/bootstrapnodes.json

        else
            rpc_port=$(($RPC_PORT_DEFAULT_VALUE+$node_index))
            channel_port=$(($CHANNEL_PORT_DEFAULT_VALUE+$node_index))
            p2p_port=$(($P2P_PORT_DEFAULT_VALUE+$node_index))
            node_desc="$public_ip"$UNDER_LINE_STR"$node_index"

            mkdir -p $installation_build_dir/$node_dir_name/dependencies/node_action_info_dir/
            current_node_action_info_file_path=$installation_build_dir/$node_dir_name/dependencies/node_action_info_dir/nodeactioninfo_"$public_ip_underline"_"$node_index".json
            cp $node_ca_path/node/node.json $current_node_action_info_file_path

            #if [ $host_type -eq $TYPE_GENESIS_HOST ] && [ $node_index -eq 0 ]
            #then
            #    g_genesis_node_action_info_json_path=$current_node_action_info_file_path
            #fi

            # copy all node action info files to the container dir which owned by genesis node
            #if [ ${g_status_process} -eq ${PROCESS_INITIALIZATION} ] || [ ${g_status_process} -eq ${PROCESS_EXPAND_NODE} ]
            #then
            #    cp $current_node_action_info_file_path ${g_genesis_node_action_container_dir_path}
            #fi
        fi

        if [ $host_type -eq $TYPE_GENESIS_HOST ] && [ $node_index -eq 0 ]
        then
            g_genesis_node_info_path=$installation_build_dir/$node_dir_name/dependencies/rlp_dir/bootstrapnodes.json
            echo $g_genesis_node_info_path > $CACHE_DIR_PATH/g_genesis_node_info_path

            export HOST_IP=$public_ip
            export HOST_PORT=$p2p_port

            MYVARS='${HOST_IP}:${HOST_PORT}'
            envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/bootstrapnodes.json.tpl > $g_genesis_node_info_path
        fi

        rpc_port_list_str=$rpc_port_list_str"$rpc_port"$delim_str
        channel_port_list_str=$channel_port_list_str"$channel_port"$delim_str
        p2p_port_list_str=$p2p_port_list_str"$p2p_port"$delim_str
        node_desc_list_str=$node_desc_list_str"$node_desc"$delim_str
        agent_info_list_str=$agent_info_list_str"$agent_info"$delim_str

        idx_list_str=$idx_list_str"$node_index"$delim_str

        node_index=$(($node_index+1))
    done

    local god_addr=$(cat $g_genesis_cert_dir_path/godInfo.txt 2>/dev/null | grep address | awk -F ':' '{print $2}')

    export NODE_NUM_TPL=$node_num_per_host
    export GOD_ADDRESS_TPL=${god_addr}
    export LISTEN_IP_TPL=$listen_ip_list_str
    export RPC_PORT_TPL=$rpc_port_list_str
    export CHANNEL_PORT_VALUE_TPL=$channel_port_list_str
    export P2P_PORT_TPL=$p2p_port_list_str
    export NODE_DESC_TPL=$node_desc_list_str
    export AGENCY_INFO_TPL=$agent_info_list_str
    export IDX_TPL=$idx_list_str
    export DOCKER_REPOSITORY_TPL=${DOCKER_REPOSITORY}
    export DOCKER_VERSION_TPL=${DOCKER_VERSION}

    MYVARS='${DOCKER_REPOSITORY_TPL}:${DOCKER_VERSION_TPL}:${NODE_NUM_TPL}:${GOD_ADDRESS_TPL}:${LISTEN_IP_TPL}:${RPC_PORT_TPL}:${CHANNEL_PORT_VALUE_TPL}:${P2P_PORT_TPL}:${NODE_DESC_TPL}:${AGENCY_INFO_TPL}:${IDX_TPL}'
    envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/config.sh.tpl > $installation_build_dir/$node_dir_name/dependencies/follow/config.sh
    # echo "envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/config.sh.tpl > $installation_build_dir/$node_dir_name/dependencies/config.sh"
    return 0
}

# copy files: genesis.json, genesis_node_info.json, syaddress.txt
function build_base_info_dir()
{
    node_base_info_dir=$1/dependencies
    mkdir -p $node_base_info_dir/follow/

    # genesis.json
    cp $TEMP_BUILD_DIR/genesis.json $node_base_info_dir/follow/
    # bootstrapnodes.json
    cp $g_genesis_node_info_path $node_base_info_dir/follow/
    # system contract address
    cp $TEMP_BUILD_DIR/syaddress.txt $node_base_info_dir/follow/

    return 0
}

function build_temp_node()
{
    # it means the temp node have already build if the $TEMP_BUILD_DIR is exist, so no need build again.
    if ! [ -d $TEMP_BUILD_DIR ]
    then
        #port checkcheck
        check_port $RPC_PORT_FOR_TEMP_NODE
        if [ $? -ne 0 ];then
            echo "temp node rpc port check, $RPC_PORT_FOR_TEMP_NODE is in use."
            return 1
        fi

        check_port $CHANNEL_PORT_FOR_TEMP_NODE
        if [ $? -ne 0 ];then
            echo "temp node channel port check, $CHANNEL_PORT_FOR_TEMP_NODE is in use."
            return 1
        fi

        check_port $P2P_PORT_FOR_TEMP_NODE
        if [ $? -ne 0 ];then
            echo "temp node p2p port check, $P2P_PORT_FOR_TEMP_NODE is in use."
            return 1
        fi
        #build temp node, in order to generate the genesis json file
        local temp_node_num=1
        local temp_agenct_info="temp"
        build_node_installation_package "127.0.0.1" "127.0.0.1" $temp_node_num $TYPE_TEMP_HOST $temp_agenct_info

        if [ $? -eq 0 ];then
            cd $installation_build_dir/$TEMP_NODE_NAME/
            bash install_temp_node.sh install
        else
            return 2
        fi
    else
        alert_msg="temp node is already exist."
        echo $alert_msg
    fi

    cd $installPWD

    return 0
}

#deploy system contract
function deploy_system_contract_for_initialization()
{
    cd $installation_build_dir/$TEMP_NODE_NAME/build/node/
    bash start_node0_godminer.sh
    sleep 8
    # check if temp node is running
    check_port $CHANNEL_PORT_FOR_TEMP_NODE
    if [ $? -eq 0 ];then
        echo "channel port $CHANNEL_PORT_FOR_TEMP_NODE is not listening, maybe temp node god mode start failed."
        return 1
    fi

    cd $installation_build_dir/$TEMP_NODE_NAME/build/web3sdk/bin
    chmod a+x system_contract_tools.sh

    ## register all node to the system contract
    for ((i=0; i<g_host_config_num; i++))
    do
        declare sub_arr=(${!MAIN_ARRAY[i]})
        public_ip=${sub_arr[0]}
        private_ip=${sub_arr[1]}
        node_num_per_host=${sub_arr[2]}
        local host_type=$(get_host_type $i)
        local node_dir_name=$(get_node_dir_name $host_type $public_ip $private_ip)
        local current_node_path=$installation_build_dir/$node_dir_name
        local public_ip_underline=$(replace_dot_with_underline $public_ip)
        for ((j=0; j<$node_num_per_host; j++))
        do
            local node_index=$j
            local node_path=$current_node_path/dependencies/node_action_info_dir/nodeactioninfo_"$public_ip_underline"_"$node_index".json
            echo " ==== register node json =>"${node_path}
            bash system_contract_tools.sh NodeAction registerNode file:${node_path}
        done
    done

    echo "all register node => "
    bash system_contract_tools.sh NodeAction all

    # export the genesis file
    cd $installation_build_dir/$TEMP_NODE_NAME/build/node/
    bash stop_node0.sh 1>/dev/null
    if [ ${IS_DEBUG} -eq 1 ]
    then
        ./fisco-bcos  --genesis $installation_build_dir/$TEMP_NODE_NAME/build/node/genesis.json  --config $installation_build_dir/$TEMP_NODE_NAME/build/node/nodedir0/config.json --export-genesis $TEMP_BUILD_DIR/genesis.json  >$installation_build_dir/$TEMP_NODE_NAME/build/node/nodedir0/fisco-bcos.log 2>&1
    else
        ./fisco-bcos  --genesis $installation_build_dir/$TEMP_NODE_NAME/build/node/genesis.json  --config $installation_build_dir/$TEMP_NODE_NAME/build/node/nodedir0/config.json --export-genesis $TEMP_BUILD_DIR/genesis.json  >$installation_build_dir/$TEMP_NODE_NAME/build/node/nodedir0/fisco-bcos.log 1>/dev/null 2>&1
    fi
    echo "    exporting genesis file : "
    $installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME/dependencies/scripts/percent_num_progress_bar.sh 2 &
    sleep 3

    cd $installPWD

    return 0
}

function get_host_type()
{
    local node_index_local=$1
    local build_host_type_local=0

    if [ $node_index_local -eq 0 ]
        then
            build_host_type_local=$TYPE_GENESIS_HOST
        else
            build_host_type_local=$TYPE_FOLLOWER_HOST
    fi

    echo $build_host_type_local
}

function check_config_validation()
{
    g_host_config_num=${#MAIN_ARRAY[@]}
    if [ -z "$g_host_config_num" ] || [ $g_host_config_num -le 0 ];then
        echo "invalid host_config_num = "$g_host_config_num
        return 1
    fi

    for ((i=0; i<g_host_config_num; i++))
    do
        declare sub_arr=(${!MAIN_ARRAY[i]})
        local p2pnetworkip=${sub_arr[0]}
        local listenip=${sub_arr[1]}
        local node_num_per_host=${sub_arr[2]}
        if [ -z "$p2pnetworkip" ] || [ -z "$listenip" ] || [ -z "$node_num_per_host" ]
        then
            echo "config invalid, p2pnetworkip: ""$p2pnetworkip, listenip: $listenip, node_num_per_host: $node_num_per_host"
            return 2
        fi

        local agent=${sub_arr[3]}
        if [ -z "$agent" ]; then
            echo "agent info cannot be null empty"
            return 3
        fi
    done

    return 0
}


#install dependency software
function install_dependencies() 
{
    if grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        sudo apt-get -y install gettext
        sudo apt-get -y install bc
        sudo apt-get -y install cmake
        sudo apt-get -y install git
        sudo apt-get -y install openssl
        sudo apt-get -y install build-essential libboost-all-dev
        sudo apt-get -y install libcurl4-openssl-dev libgmp-dev
        sudo apt-get -y install libleveldb-dev  libmicrohttpd-dev
        sudo apt-get -y install libminiupnpc-dev
        sudo apt-get -y install libssl-dev libkrb5-dev
        sudo apt-get -y install lsof
    else
        sudo yum -y install bc
        sudo yum -y install gettext
        sudo yum -y install cmake3
        sudo yum -y install git gcc-c++
        sudo yum -y install openssl openssl-devel
        sudo yum -y install boost-devel leveldb-devel curl-devel 
        sudo yum -y install libmicrohttpd-devel gmp-devel 
        sudo yum -y install lsof
    fi
}

function build_fisco_bcos()
{
    #cd FISCO-BCOS

    #install deps
    sudo bash scripts/install_deps.sh

    #build bcos
    sudo mkdir -p build
    cd build
    if grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
    sudo cmake -DEVMJIT=OFF -DTESTS=OFF -DMINIUPNPC=OFF .. 
    else
    sudo cmake3 -DEVMJIT=OFF -DTESTS=OFF -DMINIUPNPC=OFF .. 
    fi

    sudo make

    sudo make install
}

#clone and download fisco-bcos
function clone_and_build_fisco()
{
    install_dependencies
    
    require_version=${FISCO_BCOS_VERSION}

    #fisco-bcos already exist
    if [ -f ${TARGET_ETH_PATH} ]; then
        #check TARGET_ETH_PATH version
        fisco_bcos_version_check ${require_version}
        if [ $? -eq 0 ];then
            return 0
        fi
    fi

    github_path="https://github.com/FISCO-BCOS/FISCO-BCOS.git"
    fisco_local_path=$FISCO_BCOS_LOCAL_PATH
    if [ -z ${fisco_local_path} ];then
        fisco_local_path=$installPWD/../  #Parent Directory
    fi    

    cd $fisco_local_path
    git clone $github_path FISCO-BCOS
    if [ ! -d FISCO-BCOS ];then
        echo "git clone FISCO-BCOS failed."
        return 1
    fi

    cd FISCO-BCOS
    git pull origin
    git checkout ${require_version}
    if [ $? -ne 0 ];then
        echo "git checkout ${require_version} failed, maybe ${require_version} not exist."
        return 2
    fi

    build_fisco_bcos

    #maybe compile failed
    if [ ! -f ${TARGET_ETH_PATH} ]; then
	    return 1
    else
        #check TARGET_ETH_PATH version
        fisco_bcos_version_check ${require_version}
        return $?
    fi
}

function version()
{
    VERSION=$(cat release_note.txt 2>/dev/null)
    echo "                                                     "
    echo "##### fisco-package-build-tool VERSION=$VERSION #####"
    echo "                                                     "
}

# version check
function dependencies_check()
{
    # operating system check => CentOS 7.2+ || Ubuntu 16.04 || Oracle Linux Server 7.4+
    os_version_check
    # java => Oracle JDK 1.8
    java_version_check
    # openssl => OpenSSL 1.0.2
    openssl_version_check

    # add more check here
}

function main()
{
    # version print
    version

    # version check
    dependencies_check

    # sudo permission check
    request_sudo_permission
    if [ $? -ne 0 ]
    then
        return $?
    fi

    # check config valid
    check_config_validation
    if [ $? -ne 0 ]
    then
        return $?
    fi

    # init all global variable
    init_global_variable
    if [ $? -ne 0 ]
    then
        return $?
    fi

    #clone from github for fisco-bcos source
    #check if need compile fisco-bcos
    clone_and_build_fisco
    if [ $? -ne 0 ];then
       return $?
    fi

    print_dash

    #check if expand 
    if [ -f ${INITIALIZATION_DONE_FILE_PATH} ]
    then
        # expand mode
        g_status_process=${PROCESS_EXPAND_NODE}
    else
        g_status_process=${PROCESS_INITIALIZATION}
        mkdir -p $CACHE_DIR_PATH
    fi

    #build temp node 
    #deploy system contract
    #register all node to system contract
    build_temp_node
    syaddress=$(cat $TEMP_BUILD_DIR/syaddress.txt  2>/dev/null)
    if [ -z $syaddress ];then
        #echo "WARNING : system contract address null, maybe deploy system contract failed."
        return 2  
    fi

    # load config from installation_config.sh
    for ((i=0; i<g_host_config_num; i++))
    do
        declare sub_arr=(${!MAIN_ARRAY[i]})
        public_ip=${sub_arr[0]}
        private_ip=${sub_arr[1]}
        node_num_per_host=${sub_arr[2]}
        local agency_info=${sub_arr[3]}

        build_host_type=$(get_host_type $i)

        build_node_installation_package $public_ip $private_ip $node_num_per_host $build_host_type $agency_info
        if [ $? -ne 0 ];then
            return $?
        fi
    done

    # there is no need deploy system contract again when expand the chain.
    if [ $g_status_process -eq ${PROCESS_INITIALIZATION} ]
    then
        deploy_system_contract_for_initialization
        if [ $? -ne 0 ];then
            return $?
        fi
    fi

    expand_node_num=0
    ## register all node to system contract
    for ((i=0; i<g_host_config_num; i++))
    do
        declare sub_arr=(${!MAIN_ARRAY[i]})
        public_ip=${sub_arr[0]}
        private_ip=${sub_arr[1]}
        node_num_per_host=${sub_arr[2]}

        public_ip_underline=$(replace_dot_with_underline $public_ip)

        build_host_type=$(get_host_type $i)

        copy_genesis_related_info $public_ip $private_ip $node_num_per_host $build_host_type
        expand_node_num=$((${expand_node_num}+1))
    done

    if [ $expand_node_num -eq 0 ]
    then
        echo "all node has already build! nothing to be done!"
    elif [ $g_status_process -eq ${PROCESS_INITIALIZATION} ]
    then
        # done the initilization job
        touch ${INITIALIZATION_DONE_FILE_PATH}
    fi

    echo
    print_dash

    echo "    Building end!"
    return 0
}

function check_file_exist()
{
    local file_name=$1
    if ! [ -f ${file_name} ]
    then
        echo "${file_name} file is not exist"
        return 2
    fi
    return 0
}

function add_eth_node_by_specific_genesis_node()
{
    source ./specific_genesis_node_scale_config.sh

    g_status_process=${PROCESS_SPECIFIC_EXPAND_NODE}

    local p2p_network_ip_local=${p2p_network_ip}
    local listen_network_ip_local=${listen_network_ip}
    local node_num_per_host_local=${node_number}
    local agency_info=${agency_info}
    local build_host_type_local=$TYPE_FOLLOWER_HOST

    g_genesis_cert_dir_path=${genesis_ca_dir_path}

    check_file_exist ${genesis_json_file_path}
    ret=$?
    if [ $ret -ne 0 ]
    then
        return $ret
    fi

    check_file_exist ${genesis_node_info_file_path}
    ret=$?
    if [ $ret -ne 0 ]
    then
        return $ret
    fi

    check_file_exist ${genesis_system_address_file_path}
    ret=$?
    if [ $ret -ne 0 ]
    then
        return $ret
    fi

    build_node_installation_package $p2p_network_ip_local $listen_network_ip_local $node_num_per_host_local $build_host_type_local $agency_info
    if [ $? -ne 0 ];then
        return $?
    fi

    local node_dir_name_local=$(get_node_dir_name $build_host_type_local $p2p_network_ip_local $listen_network_ip_local)
    local current_node_path_local=$installation_build_dir/$node_dir_name_local

    local node_base_info_dir=$current_node_path_local/dependencies/follow/
    mkdir -p $node_base_info_dir/

    # copy node_manager.sh
    cp $INSTALLATION_DEPENENCIES_LIB_DIR/node_manager.sh -p $node_base_info_dir/
    cp ${genesis_json_file_path} $node_base_info_dir/
    cp ${genesis_node_info_file_path} $node_base_info_dir/
    cp ${genesis_system_address_file_path} $node_base_info_dir/
    echo "expand end."
}

case "$1" in
    'expand')
        add_eth_node_by_specific_genesis_node
        ;;
    'build')
        main
        ;;
    *)
        echo "invalid option!"
        echo "Usage: $0 {build|expand}"
        #exit 1
esac
