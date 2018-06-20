#!/bin/bash

#set -e

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
INSTALLATION_DEPENENCIES_LIB_DIR_NAME=installation_dependencies
INSTALLATION_DEPENENCIES_LIB_DIR=$installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME
source $installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME/dependencies/scripts/utils.sh
source $installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME/dependencies/scripts/public_config.sh

#private config
source $PWD/$DEPENDENCIES_CONFIG_FILE_NAME
CACHE_DIR_PATH=$installation_build_dir/.cache_dir
INITIALIZATION_DONE_FILE_PATH=$CACHE_DIR_PATH/initialization_done
GOD_ADDRESS_DEFAULT_VALUE="0x00855942dbd63353d9dac56abe17d818e6779c42"
RPC_PORT_DEFAULT_VALUE=$(($RPC_PORT_FOR_TEMP_NODE+1))
P2P_PORT_DEFAULT_VALUE=$(($P2P_PORT_FOR_TEMP_NODE+1))
CHANNEL_PORT_DEFAULT_VALUE=$(($CHANNEL_PORT_FOR_TEMP_NODE+1))
PORT_DEFAULT_VALUE=$(($P2P_PORT_FOR_TEMP_NODE+1))
IDENTITY_TYPE_DEFAULT_VALUE="1"
TEMP_NODE_NAME="temp"
TEMP_BUILD_DIR=$installation_build_dir/$TEMP_NODE_NAME/build
GENESIS_RLP_DIR=$installation_build_dir/$TEMP_NODE_NAME/build/genesis_rlp_dir
TARGET_ETH_PATH=/usr/local/bin/fisco-bcos

#Oracle JDK 1.8+ be requied.
function check_java_env()
{
    type java >/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "java is not installed, Oracle JDK 1.8+ be requied."
        return 1
    fi

    #JAVA version
    JAVA_VER=$(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*"/\1\2/p;')
    #Oracle JDK 1.8+
    if [ $JAVA_VER -ge 18 ] && [[ $(java -version 2>&1 | grep "TM") ]];then
        return 0
    fi

    echo "Oracle JDK 1.8+ be requied."
    echo "now JDK is "
    echo `java -version`
    return 2
} 

# global variable
function init_global_variable()
{
    g_host_config_num=${#MAIN_ARRAY[@]}

    echo "host_config_num = "$g_host_config_num

    g_genesis_node_action_info_json_path=""
    g_genesis_new_json_path=$TEMP_BUILD_DIR/genesis.json
    g_status_process=${PROCESS_INITIALIZATION}
    if [ -f $CACHE_DIR_PATH/g_genesis_node_action_container_dir_path ]
    then
        g_genesis_node_action_container_dir_path=$(cat $CACHE_DIR_PATH/g_genesis_node_action_container_dir_path)
    else
        g_genesis_node_action_container_dir_path=""
    fi

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

#create node for node of the server
function build_node_ca()
{
    agency=$1
    node=$2
    src=$3
    dst=$4

    echo "agency is => "$agency
    echo "node is => "$node
    echo "cert is => "$src
    echo "ca is => "$dst

    cd $src
    bash chain.sh >/dev/null 2>&1 #ca for chain
    bash agency.sh $agency >/dev/null 2>&1  #ca for agent
    bash node.sh $agency $node >/dev/null 2>&1 #ca for node
    bash sdk.sh $agency "sdk" >/dev/null 2>&1 #ca for sdk
    
    cd $agency && mv $node $dst/node && mv sdk $dst
}

#create install packag for every node of the server
function build_node_installation_package()
{
    local public_ip=$1
    local private_ip=$2
    local node_num_per_host=$3
    local host_type=$4
    local crypto_mode=$5
    local super_key=$6
    local identity_type=$7
    local agent_info=$8
    local key_center_url="null"

    echo "build_node_installation_package =>"
    echo "host_type = "$host_type
    echo "public_ip = "$public_ip
    echo "private_ip = "$private_ip
    echo "node_num = "$node_num_per_host
    echo "crypto_mode = "$crypto_mode
    echo "super_key = "$super_key
    echo "identity_type = "$identity_type
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
    mkdir -p $current_node_path/dependencies/rlp_dir/

    cp $TARGET_ETH_PATH $current_node_path/
    cp -r $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies $current_node_path/

    if [ $host_type -eq $TYPE_TEMP_HOST ]
    then
        cp $INSTALLATION_DEPENENCIES_LIB_DIR/install_temp_node.sh $current_node_path/
        chmod +x $current_node_path/install_temp_node.sh
    elif [ $host_type -eq $TYPE_GENESIS_HOST ]
    then
        export IS_GENESIS_HOST_TPL=1
        envsubst '${IS_GENESIS_HOST_TPL}' < $INSTALLATION_DEPENENCIES_LIB_DIR/install_node.sh.tpl > $current_node_path/install_node.sh
        chmod +x $current_node_path/install_node.sh

        # copy node_manager.sh
        cp $INSTALLATION_DEPENENCIES_LIB_DIR/node_manager.sh $current_node_path/

        # create "i am genesis node" file, the genesis node will contain this file in his root dir.
        touch $current_node_path/.i_am_genesis_host

        g_genesis_node_action_container_dir_path=$current_node_path/node_action_info_dir
        mkdir -p ${g_genesis_node_action_container_dir_path}/
        echo ${g_genesis_node_action_container_dir_path} > $CACHE_DIR_PATH/g_genesis_node_action_container_dir_path

        g_genesis_cert_dir_path=$current_node_path/dependencies/cert
        echo ${g_genesis_cert_dir_path} > $CACHE_DIR_PATH/g_genesis_cert_dir_path

        #copy god info to address
        if [ -f $TEMP_BUILD_DIR/godInfo.txt ];then
            mv $TEMP_BUILD_DIR/godInfo.txt ${g_genesis_cert_dir_path} >/dev/null 2>&1
        fi
    else 
        export IS_GENESIS_HOST_TPL=0
        envsubst '${IS_GENESIS_HOST_TPL}' < $INSTALLATION_DEPENENCIES_LIB_DIR/install_node.sh.tpl > $current_node_path/install_node.sh
        chmod +x $current_node_path/install_node.sh
    fi

    listen_ip_list_str=""
    rpc_port_list_str=""
    channel_port_list_str=""
    p2p_port_list_str=""
    node_desc_list_str=""
    agent_info_list_str=""
    identity_type_list_str=""
    idx_list_str=""

    local current_host_rlp_dir=$current_node_path/dependencies/rlp_dir
    mkdir -p $current_host_rlp_dir/

    node_index=0
    while [ $node_index -lt $node_num_per_host ]
    do
        current_node_rlp_dir=$current_node_path/dependencies/rlp_dir/node_rlp_$node_index
        mkdir -p $current_node_rlp_dir/
        mkdir -p $current_node_rlp_dir/ca/
        
        build_crypto_mode_json_file $current_host_rlp_dir $crypto_mode $key_center_url $current_node_rlp_dir $super_key
        
        node_name=$public_ip_underline"_"$node_index
        if [ $host_type -eq $TYPE_TEMP_HOST ];then
            node_cert_path=$current_node_path/dependencies/cert/
        else
            node_cert_path=${g_genesis_cert_dir_path}
        fi
        node_ca_path=$current_node_rlp_dir/ca/
        build_node_ca $agent_info $node_name ${node_cert_path} ${node_ca_path}

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

            if [ $host_type -eq $TYPE_GENESIS_HOST ] && [ $node_index -eq 0 ]
            then
                g_genesis_node_action_info_json_path=$current_node_action_info_file_path
            fi

            # copy all node action info files to the container dir which owned by genesis node
            if [ ${g_status_process} -eq ${PROCESS_INITIALIZATION} ] || [ ${g_status_process} -eq ${PROCESS_EXPAND_NODE} ]
            then
                cp $current_node_action_info_file_path ${g_genesis_node_action_container_dir_path}
            fi
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

        identity_type_list_str=$identity_type_list_str"$identity_type"$delim_str
        idx_list_str=$idx_list_str"$node_index"$delim_str

        node_index=$(($node_index+1))
    done

    local god_addr=""
    if [ -f $g_genesis_cert_dir_path/godInfo.txt ];then
        god_addr=$(cat $g_genesis_cert_dir_path/godInfo.txt | grep address | awk -F ':' '{print $2}' 2>/dev/null)
    fi

    if [ -z ${god_addr} ];then
            god_addr=$GOD_ADDRESS_DEFAULT_VALUE
    fi

    export NODE_NUM_TPL=$node_num_per_host
    export GOD_ADDRESS_TPL=${god_addr}
    export LISTEN_IP_TPL=$listen_ip_list_str
    export RPC_PORT_TPL=$rpc_port_list_str
    export CHANNEL_PORT_VALUE_TPL=$channel_port_list_str
    export P2P_PORT_TPL=$p2p_port_list_str
    export NODE_DESC_TPL=$node_desc_list_str
    export AGENCY_INFO_TPL=$agent_info_list_str
    export IDENTITY_TYPE_TPL=$identity_type_list_str
    export IDX_TPL=$idx_list_str
    export CRYPTO_MODE_TPL=$crypto_mode
    MYVARS='${NODE_NUM_TPL}:${GOD_ADDRESS_TPL}:${LISTEN_IP_TPL}:${CRYPTO_MODE_TPL}:${RPC_PORT_TPL}:${CHANNEL_PORT_VALUE_TPL}:${P2P_PORT_TPL}:${NODE_DESC_TPL}:${AGENCY_INFO_TPL}:${IDENTITY_TYPE_TPL}:${IDX_TPL}'
    envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/config.sh.tpl > $installation_build_dir/$node_dir_name/dependencies/config.sh
    echo "envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/config.sh.tpl > $installation_build_dir/$node_dir_name/dependencies/config.sh"
    return 0
}

# copy files: genesis.json, genesis_node_info.json, syaddress.txt
function build_base_info_dir()
{
    node_base_info_dir=$1/dependencies
    mkdir -p $node_base_info_dir/

    if [ ! -f ${g_genesis_new_json_path} ];then
        echo "WARNING : g_genesis_new_json_path not exist."
    fi

    if [ ! -f ${g_genesis_node_info_path} ];then
        echo "WARNING : g_genesis_node_info_path not exist."
    fi
    
    if [ ! -f $TEMP_BUILD_DIR/syaddress.txt ];then
        echo "WARNING : syaddress.txt not exist."
    fi

    # genesis.json
    cp $g_genesis_new_json_path $node_base_info_dir/
    # bootstrapnodes.json
    cp $g_genesis_node_info_path $node_base_info_dir/
    # system contract address
    cp $TEMP_BUILD_DIR/syaddress.txt $node_base_info_dir/

    return 0
}

function build_temp_node()
{
    # it means the temp node have already build if the $TEMP_BUILD_DIR is exist, so no need build again.
    if ! [ -d $TEMP_BUILD_DIR ]
    then
        #build temp node, in order to generate the genesis json file
        temp_node_num=1
        local crypto_mode=0
        local key_center_url="null"
        local super_key="null"
        local identity_type=$IDENTITY_TYPE_DEFAULT_VALUE
        local temp_agenct_info="temp"
        build_node_installation_package "127.0.0.1" "127.0.0.1" $temp_node_num $TYPE_TEMP_HOST $crypto_mode $super_key $identity_type $temp_agenct_info

        cd $installation_build_dir/$TEMP_NODE_NAME/
        ./install_temp_node.sh install
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
    cd $installation_build_dir/$TEMP_NODE_NAME/
    ./start_node0.sh
    sleep 24
    # check if temp node is running
    check_port $CHANNEL_PORT_FOR_TEMP_NODE
    if [ $? -eq 0 ];then
        echo "channel port $CHANNEL_PORT_FOR_TEMP_NODE is not listening, maybe temp node start failed."
        return 1
    fi

    cd $installation_build_dir/$TEMP_NODE_NAME/dependencies/jtool/bin
    chmod a+x system_contract_tools.sh
    ./system_contract_tools.sh NodeAction registerNode file:$g_genesis_node_action_info_json_path

    # export the genesis file
    cd $installation_build_dir/$TEMP_NODE_NAME/
    ./stop_node0.sh 1>/dev/null
    if [ ${IS_DEBUG} -eq 1 ]
    then
        nohup ./fisco-bcos  --genesis $installation_build_dir/$TEMP_NODE_NAME/build/genesis.json  --config $installation_build_dir/$TEMP_NODE_NAME/build/nodedir0/config.json --export-genesis $g_genesis_new_json_path  >$installation_build_dir/$TEMP_NODE_NAME/build/nodedir0/fisco-bcos.log 2>&1 &
    else
        nohup ./fisco-bcos  --genesis $installation_build_dir/$TEMP_NODE_NAME/build/genesis.json  --config $installation_build_dir/$TEMP_NODE_NAME/build/nodedir0/config.json --export-genesis $g_genesis_new_json_path  >$installation_build_dir/$TEMP_NODE_NAME/build/nodedir0/.log 1>/dev/null 2>&1 &
    fi
    echo "    exporting genesis file : "
    $installPWD/$INSTALLATION_DEPENENCIES_LIB_DIR_NAME/dependencies/scripts/percent_num_progress_bar.sh 3 &
    sleep 4

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
    for ((i=0; i<$g_host_config_num; i++))
    do
        declare sub_arr=(${!MAIN_ARRAY[i]})
        public_ip=${sub_arr[0]}
        private_ip=${sub_arr[1]}
        node_num_per_host=${sub_arr[2]}
        if [ -z "$public_ip" ] || [ -z "$private_ip" ] || [ -z "$node_num_per_host" ]
        then
            echo "config invalid, public_ip: ""$public_ip, private_ip: $private_ip, node_num_per_host: $node_num_per_host"
            return 2
        fi

        local identity_type=${sub_arr[3]}
        #echo $identity_type
        if ! [ -z "$identity_type" ]
        then
            if [ "$identity_type" -eq 0 ] || [ "$identity_type" -eq 1 ]
            then
                echo -ne
            else
                echo "identity_type is invalid, only 0、1 is valid value!"
                return 3
            fi
        else 
            echo "invalid identify_type, identify_type is null"
            return 3
        fi

        local encryption_mode=${sub_arr[4]}
        #echo $encryption_mode
        if ! [ -z "$encryption_mode" ]
        then
            if [ "$encryption_mode" -eq 0 ] || [ "$encryption_mode" -eq 1 ]
            then
                echo -ne
            else
                echo "encryption_mode is invalid, only 0, 1 is valid value!"
                return 3
            fi
        else
            echo "invalid encryption_mode, encryption_mode is null"
            return 3
        fi

        local agent=${sub_arr[6]}
        if [ -z "$agent" ]; then
            echo "agent info cannot be null empty"
            return 4
        fi
    done

    #port checkcheck
    check_port $RPC_PORT_FOR_TEMP_NODE
    if [ $? -ne 0 ];then
        echo "temp node rpc port check, $RPC_PORT_FOR_TEMP_NODE is in use."
        return 4
    fi

    check_port $CHANNEL_PORT_FOR_TEMP_NODE
    if [ $? -ne 0 ];then
        echo "temp node channel port check, $CHANNEL_PORT_FOR_TEMP_NODE is in use."
        return 4
    fi

    check_port $P2P_PORT_FOR_TEMP_NODE
    if [ $? -ne 0 ];then
        echo "temp node p2p port check, $P2P_PORT_FOR_TEMP_NODE is in use."
        return 4
    fi

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
    cd FISCO-BCOS

    #install deps
    sudo chmod +x scripts/install_deps.sh
    ./scripts/install_deps.sh

    #build bcos
    mkdir -p build
    cd build/

    if grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
    cmake -DEVMJIT=OFF -DTESTS=OFF -DMINIUPNPC=OFF .. 
    else
    cmake3 -DEVMJIT=OFF -DTESTS=OFF -DMINIUPNPC=OFF .. 
    fi

    sudo make

    sudo make install
}

#clone and download fisco-bcos
function clone_and_build_fisco()
{
    #fisco-bcos already exist
    if [ -f "/usr/local/bin/fisco-bcos" ]; then
        return 0
    fi

    git_path=$FISCO_BCOS_GIT
    if [ -z  $FISCO_BCOS_GIT ];then
        git_path="https://github.com/FISCO-BCOS/FISCO-BCOS.git"
    fi

    echo "git clone path = "$git_path

    fisco_local_path=$FISCO_BCOS_LOCAL_PATH
    if [ -z $fisco_local_path ];then
        fisco_local_path=$installPWD/../  #Parent Directory
    fi

    echo "fisco local path = "$fisco_local_path
    cd $installPWD
    cd $fisco_local_path
    #git clone FISCO-BCOS
    if [ ! -d FISCO-BCOS  ];then
        git clone $git_path
    fi

    if [ ! -d FISCO-BCOS ];then
        echo "FISCO-BCOS directory is not exist, maybe git clone failed, unable to compile and will exit!"
        return 1
    fi

    install_dependencies
    build_fisco_bcos

    if [ ! -f "/usr/local/bin/fisco-bcos" ]; then
	    return 1
	else
	    return 0
    fi
}

function main()
{
    #sudo permission check
    request_sudo_permission
    ret=$?
    if [ $ret -ne 0 ]
    then
        return $ret
    fi

    #check java enviroment
    check_java_env
    ret=$?
    if [  $ret -ne 0 ] ; then
        return 2
    fi
    
    #init all global variable
    init_global_variable

    #check config valid
    check_config_validation
    ret=$?
    if [ $ret -ne 0 ]
    then
        return $ret
    fi

    print_dash

    if [ -f ${INITIALIZATION_DONE_FILE_PATH} ]
    then
        # expand mode
        g_status_process=${PROCESS_EXPAND_NODE}
    else
        g_status_process=${PROCESS_INITIALIZATION}
        mkdir -p $CACHE_DIR_PATH
    fi

    clone_and_build_fisco
    if [ $? -ne 0 ];then
       echo "fisco-bcos file is not exist! please check your clone and build process."
       return 2
    fi

    build_temp_node
    syaddress=$(cat $TEMP_BUILD_DIR/syaddress.txt  2>/dev/null)
    if [ -z $syaddress ];then
        echo "WARNING : system contract address null, maybe deploy system contract failed."
        return 2  
    fi

    # load config from installation_config.sh
    # Loop and print it. Using offset and length to extract values
    for ((i=0; i<$g_host_config_num; i++))
    do
        declare sub_arr=(${!MAIN_ARRAY[i]})
        public_ip=${sub_arr[0]}
        private_ip=${sub_arr[1]}
        node_num_per_host=${sub_arr[2]}
        identity_type=${sub_arr[3]}
        local crypto_mode=${sub_arr[4]}
        local super_key=${sub_arr[5]}
        local agency_info=${sub_arr[6]}

        build_host_type=$(get_host_type $i)

        build_node_installation_package $public_ip $private_ip $node_num_per_host $build_host_type $crypto_mode $super_key $identity_type $agency_info
    done

    # there is no need deploy system contract again when expand the chain.
    if [ $g_status_process -eq ${PROCESS_INITIALIZATION} ]
    then
        deploy_system_contract_for_initialization
    fi

    expand_node_num=0

    ## the first node, it will be the genesis node
    for ((i=0; i<$g_host_config_num; i++))
    do
        declare sub_arr=(${!MAIN_ARRAY[i]})
        public_ip=${sub_arr[0]}
        private_ip=${sub_arr[1]}
        node_num_per_host=${sub_arr[2]}

        public_ip_underline=$(replace_dot_with_underline $public_ip)

        build_host_type=$(get_host_type $i)

        copy_genesis_related_info $public_ip $private_ip $node_num_per_host $build_host_type
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
    local identity_type_local=${identity_type}
    local node_num_per_host_local=${node_number}
    local crypto_mode=${crypto_mode}
    local super_key=${super_key}
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

    build_node_installation_package $p2p_network_ip_local $listen_network_ip_local $node_num_per_host_local $build_host_type_local $crypto_mode $super_key $identity_type_local $agency_info

    local node_dir_name_local=$(get_node_dir_name $build_host_type_local $p2p_network_ip_local $listen_network_ip_local)
    local current_node_path_local=$installation_build_dir/$node_dir_name_local

    local node_base_info_dir=$current_node_path_local/dependencies
    mkdir -p $node_base_info_dir/

    cp ${genesis_json_file_path} $node_base_info_dir/
    cp ${genesis_node_info_file_path} $node_base_info_dir/
    cp ${genesis_system_address_file_path} $node_base_info_dir/
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
