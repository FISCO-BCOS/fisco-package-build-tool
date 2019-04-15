#!/bin/bash
dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath
# set -e

# 
function toggle_debug()
{
    mkdir -p build/
    sudo chown -R $(whoami) build
    # exec 1>>build/stdout.log
    exec 2>>build/stderr.log
    # exec 3>>build/stdinfo.log
}

installPWD=$PWD

source $installPWD/installation_dependencies/dependencies/scripts/utils.sh
source $installPWD/installation_dependencies/dependencies/scripts/public_config.sh
source $installPWD/installation_dependencies/dependencies/scripts/os_version_check.sh
source $installPWD/installation_dependencies/dependencies/scripts/dependencies_install.sh
source $installPWD/installation_dependencies/dependencies/scripts/dependencies_check.sh
source $installPWD/installation_dependencies/dependencies/scripts/parser_config_ini.sh

#fisco-bcos version check, At least 1.3.0 is required
function fisco_bcos_version_check()
{
    local version=$1;
    local fisco_path=$2
    local exit_flag=$3
    
    # config fisco-bcos version check

    if [ ! -f ${fisco_path} ];then
        error_message " fisco-bcos not exist, fisco path is ${fisco_path}"
    fi

    FISCO_VERSION=$(${fisco_path} --version 2>&1 | egrep "FISCO-BCOS *version" | awk '{print $3}')
    # FISCO BCOS gm version not support
    if  echo "$FISCO_VERSION" | egrep "gm" ; then
        error_message "FISCO BCOS gm version not support yet, now ${fisco_path} is ${FISCO_VERSION}"
    fi 

        # fisco bcos 1.3.0+
    ver=$(echo "$FISCO_VERSION" | awk -F . '{print $1$2}')
    if [ $ver -lt 13 ];then
        error_message "At least FISCO-BCOS 1.3.0 is required, now ${fisco_path} is ${FISCO_VERSION}"
    fi

    # do not need specified version
    if [ -z "$version" ];then
        return 0
    fi

    # version compare
    v=$(echo "$FISCO_VERSION" | awk -F . '{print $1"."$2"."$3}')
    if [ "v$v" = "$version" ] || [ "V$v" = "$version" ];then
        return 0
    fi

    if [ "true" == "${exit_flag}" ];then
        error_message "Required version is $version, now ${fisco_path} version is $v"
    else
        echo "Required version is $version, now ${fisco_path} version is $v"
    fi

    return 1
}

function get_node_dir_name()
{
    local host_type_local=$1
    local public_ip_underline_local=$2
    local private_ip_underline_local=$3
    local agency=$4

    if [ $host_type_local -eq $TYPE_TEMP_HOST ]
    then
        node_dir_name_local=$TEMP_NODE_NAME
    elif [ $host_type_local -eq $TYPE_GENESIS_HOST ]
    then
        node_dir_name_local=$public_ip_underline_local"_"$agency"_genesis"
    else
        node_dir_name_local=$public_ip_underline_local"_$agency"
    fi
    echo $node_dir_name_local
}

function copy_genesis_related_info()
{
    local public_ip=$1
    local private_ip=$2
    local agency=$3
    local host_type=$4

    public_ip_underline=$(replace_dot_with_underline $public_ip)
    private_ip_underline=$(replace_dot_with_underline $private_ip)

    #create node dir
    node_dir_name=$(get_node_dir_name $host_type $public_ip $private_ip $agency)
    current_node_path=$installation_build_dir/$node_dir_name

    #copy genesis json file to node dir
    build_base_info_dir $current_node_path

    #copy all ca info to genesis node
    if [ $host_type -eq $TYPE_GENESIS_HOST ];then
        cp -r $g_genesis_cert_dir_path  $current_node_path/dependencies/follow
    fi
}

#build node for node of the server
function build_node_ca()
{
    agency=$1
    node=$2
    src=$3
    dst=$4

    echo "Build ca, agency=$agency, node=$node, dst=$dst"

    local ext_dir=${INSTALLATION_DEPENENCIES_EXT_DIR}/cert/
    bash $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies/cert/ext.sh $agency $node ${ext_dir}
    cd $ext_dir
    if [ ! -f ${ext_dir}/$agency/$node/node.nodeid ];then
        error_message "node.nodeid is not exist, agency => $agency, node => $node"
    fi

    mkdir -p $dst/node
    cp ${ext_dir}/ca.crt $dst/node 2>/dev/null
    cp ${ext_dir}/$agency/agency.crt $dst/node 2>/dev/null

    cp ${ext_dir}/$agency/$node/node* $dst/node/

    return 0
}

#create node for node of the server
function create_node_ca()
{
    agency=$1
    node=$2
    src=$3
    dst=$4

    echo "Create ca, agency=$agency, node=$node, src=$src, dst=$dst"

    cd $src

    bash chain.sh 1>/dev/null #ca for chain
    if [ ! -f "ca.key" ]; then
        error_message "ca.key is not exist, maybe \" bash chain.sh \" failed."
    elif [ ! -f "ca.crt" ]; then
        error_message "ca.crt is not exist, maybe \" bash chain.sh \" failed."
    fi

    bash agency.sh $agency 1>/dev/null #ca for agent
    if [ ! -d $agency ]; then
        error_message "$agency dir is not exist, maybe \" bash agency.sh $agency\" failed."
    fi

    bash node.sh $agency $node 1>/dev/null #ca for node
    if [ ! -d $agency/$node ]; then
        error_message "$agency/$node dir is not exist, maybe \" bash node.sh $agency $node \" failed."
    fi

    bash sdk.sh $agency "sdk" 1>/dev/null #ca for sdk
    if [ ! -d $agency/sdk ]; then
        error_message "$agency/sdk dir is not exist, maybe \" bash sdk.sh $agency sdk \" failed."
    fi

    mkdir -p $dst
    mv $agency/$node $dst/node
    mv $agency/sdk $dst

    return 0
}


function build_bootstrapnodes()
{
    # generate bootstrapnodes.json for all node
    local delim_str=""
    local nodes_str=""
    for ((i=0; i<g_host_config_num; i++))
    do
        declare sub_arr=(`eval echo '$'"NODE_INFO_${i}"`)
        local p2p_ip=${sub_arr[0]}
        local node_num_per_host=${sub_arr[2]}

        local node_index=0
        while [ $node_index -lt $node_num_per_host ]
        do 
            if [[ $i == $(($g_host_config_num-1)) && $node_index -eq $(($node_num_per_host-1)) ]]
            then
                delim_str=""
            else
                delim_str=","
            fi
            local p2p_port=$(($P2P_PORT_NODE+$node_index))
            # echo " build bootstrapnodes.json, p2p_ip is $p2p_ip, port is $p2p_port"
            nodes_str=$nodes_str"{\"host\":\"${p2p_ip}\",\"p2pport\":\"${p2p_port}\"}"$delim_str
            node_index=$(($node_index+1))
        done
    done

    echo ${nodes_str}
}

#create install packag for every node of the server
function build_node_installation_package()
{
    local public_ip=$1
    local private_ip=$2
    local node_num_per_host=$3
    local host_type=$4
    local agent_info=$5

    echo "Building package => p2p_ip=$public_ip ,listen_ip=$private_ip ,node_num=$node_num_per_host ,host_type=$host_type ,agent=$agent_info"

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

    node_dir_name=$(get_node_dir_name $host_type $public_ip $private_ip $agent_info)
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

    cp $fisco_path $current_node_path/dependencies/fisco-bcos/
    cp -r $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies $current_node_path/

    if [ $host_type -eq $TYPE_TEMP_HOST ]
    then
        cp $INSTALLATION_DEPENENCIES_LIB_DIR/install_temp_node.sh $current_node_path/
        chmod +x $current_node_path/install_temp_node.sh
    elif [ $host_type -eq $TYPE_GENESIS_HOST ]
    then
        export IS_GENESIS_HOST_TPL=1
        if [ ! -z "${DOCKER_TOGGLE}" ] && [ ${DOCKER_TOGGLE} -eq 1 ];then
            cp $INSTALLATION_DEPENENCIES_LIB_DIR/install_docker_node.sh $current_node_path/install_node.sh
            chmod +x $current_node_path/install_node.sh
        else
            cp $INSTALLATION_DEPENENCIES_LIB_DIR/install_node.sh $current_node_path/install_node.sh
            chmod +x $current_node_path/install_node.sh
        fi

        #g_genesis_node_action_container_dir_path=$current_node_path/node_action_info_dir
        #mkdir -p ${g_genesis_node_action_container_dir_path}/

        g_genesis_cert_dir_path=$current_node_path/dependencies/cert

        #copy god info to address
        if [ -f $TEMP_BUILD_DIR/godInfo.txt ];then
            mv $TEMP_BUILD_DIR/godInfo.txt ${g_genesis_cert_dir_path} >/dev/null 2>&1
        fi
    else 
        export IS_GENESIS_HOST_TPL=0
       
        if [ ! -z "${DOCKER_TOGGLE}" ] && [ ${DOCKER_TOGGLE} -eq 1 ];then
            cp $INSTALLATION_DEPENENCIES_LIB_DIR/install_docker_node.sh $current_node_path/install_node.sh
            chmod +x $current_node_path/install_node.sh
        else
            cp $INSTALLATION_DEPENENCIES_LIB_DIR/install_node.sh $current_node_path/install_node.sh
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
        else
            node_cert_path=${g_genesis_cert_dir_path}
            node_ca_path=$current_node_rlp_dir/ca/
            if [ ! -z "${CA_EXT_MODE}" ] && [ ${CA_EXT_MODE} -eq 1 ];then
                build_node_ca $agent_info $node_name ${node_cert_path} ${node_ca_path}
            else
                create_node_ca $agent_info $node_name ${node_cert_path} ${node_ca_path}
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
            rpc_port=$RPC_PORT_NODE
            channel_port=$CHANNEL_PORT_NODE
            p2p_port=$P2P_PORT_NODE
            node_desc="$public_ip""_temp"

            export HOST_IP=$public_ip
            export HOST_PORT=$p2p_port

            MYVARS='${HOST_IP}:${HOST_PORT}'
            envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/bootstrapnodes.json.tpl > $installation_build_dir/$node_dir_name/dependencies/rlp_dir/bootstrapnodes.json

        else
            rpc_port=$(($RPC_PORT_NODE+$node_index))
            channel_port=$(($CHANNEL_PORT_NODE+$node_index))
            p2p_port=$(($P2P_PORT_NODE+$node_index))
            node_desc="$public_ip""_""$node_index"

            mkdir -p $installation_build_dir/$node_dir_name/dependencies/node_action_info_dir/
            current_node_action_info_file_path=$installation_build_dir/$node_dir_name/dependencies/node_action_info_dir/nodeactioninfo_"$public_ip_underline"_"$node_index".json
            cp $node_ca_path/node/node.json $current_node_action_info_file_path

            # copy all node action info files to the container dir which owned by genesis node
            #if [ ${g_status_process} -eq ${PROCESS_INITIALIZATION} ] || [ ${g_status_process} -eq ${PROCESS_EXPAND_NODE} ]
            #then
            #    cp $current_node_action_info_file_path ${g_genesis_node_action_container_dir_path}
            #fi
        fi

        if [ $host_type -eq $TYPE_GENESIS_HOST ] && [ $node_index -eq 0 ]
        then
            g_genesis_node_info_path=$installation_build_dir/$node_dir_name/dependencies/rlp_dir/bootstrapnodes.json

            nodes_str=$(build_bootstrapnodes)
            export BOOTSTRAPNODES_P2P_NODES_LIST=$nodes_str
            MYVARS='${BOOTSTRAPNODES_P2P_NODES_LIST}'
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

    MYVARS='${KEYSTORE_PWD}:${CLIENTCERT_PWD}:${IS_GENESIS_HOST_TPL}:${DOCKER_REPOSITORY_TPL}:${DOCKER_VERSION_TPL}:${NODE_NUM_TPL}:${GOD_ADDRESS_TPL}:${LISTEN_IP_TPL}:${RPC_PORT_TPL}:${CHANNEL_PORT_VALUE_TPL}:${P2P_PORT_TPL}:${NODE_DESC_TPL}:${AGENCY_INFO_TPL}:${IDX_TPL}'
    envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/config.sh.tpl > $installation_build_dir/$node_dir_name/dependencies/config.sh
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
    #port checkcheck
    check_port $RPC_PORT_NODE
    if [ $? -ne 0 ];then
        error_message "temp node rpc port check, $RPC_PORT_NODE is in use."
    fi

    check_port $CHANNEL_PORT_NODE
    if [ $? -ne 0 ];then
        error_message "temp node channel port check, $CHANNEL_PORT_NODE is in use."
    fi

    check_port $P2P_PORT_NODE
    if [ $? -ne 0 ];then
        error_message "temp node p2p port check, $P2P_PORT_NODE is in use."
    fi

    #build temp node, in order to generate the genesis json file
    local temp_node_num=1
    local temp_agent_info="temp"
    build_node_installation_package "127.0.0.1" "127.0.0.1" $temp_node_num $TYPE_TEMP_HOST $temp_agent_info

    if [ $? -eq 0 ];then
        cd $installation_build_dir/$TEMP_NODE_NAME/
        bash install_temp_node.sh install
    else
        return 2
    fi

    cd $installPWD

    return 0
}

#deploy system contract
function deploy_system_contract_for_initialization()
{
    cd $installation_build_dir/$TEMP_NODE_NAME/build/
    bash node0/start_godminer.sh
    sleep 5
    # check if temp node is running
    check_port $CHANNEL_PORT_NODE 60
    if [ $? -eq 0 ];then
        bash node0/stop.sh 1>/dev/null
        error_message "channel port $CHANNEL_PORT_NODE is not listening, maybe temp node god mode start failed."
    fi

    cd $installation_build_dir/$TEMP_NODE_NAME/build/web3sdk/bin
    chmod a+x system_contract_tools.sh

    ## register all node to the system contract
    for ((i=0; i<g_host_config_num; i++))
    do
	    local sub_arr=(`eval echo '$'"NODE_INFO_${i}"`)
        local public_ip=${sub_arr[0]}
        local private_ip=${sub_arr[1]}
        local node_num_per_host=${sub_arr[2]}
        local agency_info=${sub_arr[3]}
        local host_type=$(get_host_type $i)
        local node_dir_name=$(get_node_dir_name $host_type $public_ip $private_ip $agency_info)
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
    cd $installation_build_dir/$TEMP_NODE_NAME/build/
    bash node0/stop.sh 1>/dev/null

    ./fisco-bcos  --genesis $installation_build_dir/$TEMP_NODE_NAME/build/node0/genesis.json  --config $installation_build_dir/$TEMP_NODE_NAME/build/node0/config.json --export-genesis $TEMP_BUILD_DIR/genesis.json  >$installation_build_dir/$TEMP_NODE_NAME/build/node0/fisco-bcos.log 2>&1

    echo "    exporting genesis file : "
    $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies/scripts/percent_num_progress_bar.sh 2 &
    sleep 3

    cd $installPWD

    return 0
}

function get_host_type()
{
    local node_index_local=$1
    local build_host_type_local=0

    if [ $g_status_process -eq ${PROCESS_EXPAND_NODE} ]
    then
        build_host_type_local=$TYPE_FOLLOWER_HOST
        echo $build_host_type_local
    else
        if [ $node_index_local -eq 0 ]
        then
            build_host_type_local=$TYPE_GENESIS_HOST
        else
            build_host_type_local=$TYPE_FOLLOWER_HOST
        fi

        echo $build_host_type_local
    fi
}

function build_fisco_bcos()
{
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

function version()
{
    VERSION=$(cat release_note.txt 2>/dev/null)
    echo "                                                     "
    echo "##### fisco-package-build-tool VERSION=$VERSION #####"
    echo "                                                     "
}

# initial 
function initial()
{
    # version print.
    version

    #check if build dir is exist. 
    if [ -d $buildPWD ];then
        error_message "build directory already exist, please remove it first."
    fi

    # sudo permission check
    request_sudo_permission

    # operating system check => CentOS 7.2+ || Ubuntu 16.04 || Oracle Linux Server 7.4+
    os_version_check

    # dependensies install
    dependencies_install
    # check if dependensies install success
    build_dependencies_check

    #debug message
    toggle_debug

    # parser config.ini file
    parser_ini config.ini

    # config.ini param check
    ini_param_check

    init_fisco

    print_dash

    #global varible init
    g_host_config_num=${NODE_COUNT}

    echo "host_config_num = "$g_host_config_num
    
    g_genesis_node_info_path=""
    g_genesis_cert_dir_path=""
}

function build()
{
    # init opr
    initial

    # set g_status_process to PROCESS_INITIALIZATION
    g_status_process=${PROCESS_INITIALIZATION}

    # build temp node , then deploy system contract 
    build_temp_node
    local syaddress=$(cat $TEMP_BUILD_DIR/syaddress.txt  2>/dev/null)
    if [ -z $syaddress ];then
        error_message "" 
    fi

    # build install package for every server
    for ((i=0; i<g_host_config_num; i++))
    do
	    local sub_arr=(`eval echo '$'"NODE_INFO_${i}"`)
        local public_ip=${sub_arr[0]}
        local private_ip=${sub_arr[1]}
        local node_num_per_host=${sub_arr[2]}
        local agency_info=${sub_arr[3]}

        build_host_type=$(get_host_type $i)

        build_node_installation_package $public_ip $private_ip $node_num_per_host $build_host_type $agency_info

    done

    # register all node to systemcontract and export the genesis file
    deploy_system_contract_for_initialization

    # copy genesis.json syaddress.txt bootstrapnodes.json to all node
    for ((i=0; i<g_host_config_num; i++))
    do
        declare sub_arr=(`eval echo '$'"NODE_INFO_${i}"`)
        local public_ip=${sub_arr[0]}
        local private_ip=${sub_arr[1]}
        local node_num_per_host=${sub_arr[2]}
        local build_host_type=$(get_host_type $i)
        local agency_info=${sub_arr[3]}

        copy_genesis_related_info $public_ip $private_ip $agency_info $build_host_type

    done

    echo
    print_dash

    echo " "
    echo "    Building end!"
    return 0
}

function expand()
{
    dir=$PWD
     # init opr
    initial

    cd $dir
    # load expand special config
    parser_expand_ini config.ini

    # check expand config invalid
    expand_param_check

    # set g_status_process to PROCESS_EXPAND_NODE
    g_status_process=${PROCESS_EXPAND_NODE}

    g_genesis_cert_dir_path=${EXPAND_GENESIS_FOLLOW_DIR}/cert/

    local genesis_file=${EXPAND_GENESIS_FOLLOW_DIR}/genesis.json
    local system_address_file=${EXPAND_GENESIS_FOLLOW_DIR}/syaddress.txt 
    local bootstrapnodes_file=${EXPAND_GENESIS_FOLLOW_DIR}/bootstrapnodes.json

    # get all p2p connect nodes already exist.
    old_nodes=$(cat ${bootstrapnodes_file}  | awk -F[ '{ print $2  }' | awk -F] '{ print $1  }')
    if [ -z ${old_nodes} ];then
        error_message ' invalid bootstrapnodes.json file, get null p2p nodes.'
    fi

    # expand nodes p2p connect info.
    expand_nodes=$(build_bootstrapnodes)

    # build install package for every server
    for ((i=0; i<g_host_config_num; i++))
    do
	    local sub_arr=(`eval echo '$'"NODE_INFO_${i}"`)
        local public_ip=${sub_arr[0]}
        local private_ip=${sub_arr[1]}
        local node_num_per_host=${sub_arr[2]}
        local agency_info=${sub_arr[3]}

        local build_host_type=$(get_host_type $i)

        build_node_installation_package $public_ip $private_ip $node_num_per_host $build_host_type $agency_info

        local node_dir_name_local=$(get_node_dir_name $build_host_type $public_ip $private_ip $agency_info)
        local current_node_path_local=$installation_build_dir/$node_dir_name_local

        local node_base_info_dir=$current_node_path_local/dependencies/follow/
        mkdir -p $node_base_info_dir/

        # copy genesis.json
        cp ${genesis_file} $node_base_info_dir/
        # copy syaddress.txt
        cp ${system_address_file} $node_base_info_dir/
        # generate new bootstapnodes.json
        export BOOTSTRAPNODES_P2P_NODES_LIST=$old_nodes","$expand_nodes
        MYVARS='${BOOTSTRAPNODES_P2P_NODES_LIST}'
        envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/bootstrapnodes.json.tpl > $node_base_info_dir/bootstrapnodes.json
    done

    echo
    print_dash

    echo " "
    echo "    Expanding end!"
    return 0
}

#clone and download fisco-bcos
function clone_and_build_fisco()
{
    #require_version=${FISCO_BCOS_VERSION}
    local version=$1
    local fisco=$2

    #fisco-bcos already exist
    if [ -f ${fisco} ]; then
        #check fisco version
        fisco_bcos_version_check ${version} ${fisco}
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
        error_message "git clone FISCO-BCOS failed."
    fi

    cd FISCO-BCOS
    git pull origin
    git checkout ${version}
    if [ $? -ne 0 ];then
        error_message "git checkout ${version} failed, maybe ${version} not exist."
    fi

    build_fisco_bcos

    # maybe compile failed
    if [ ! -f ${fisco} ]; then
        error_message "${fisco} not exsit, maybe compile failed."
    else
        #check fisco version
        fisco_bcos_version_check ${version} ${fisco} "true"
    fi
}

function download_fisco()
{
    # https://codeload.github.com/FISCO-BCOS/FISCO-BCOS/tar.gz/v1.3.8
    local version=$1
    local package_name="fisco-bcos.tar.gz"
    local dst="build/${package_name}"
    #https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/v1.3.8/fisco-bcos.tar.gz
    curl -L "https://github.com/FISCO-BCOS/FISCO-BCOS/releases/download/${version}/fisco-bcos.tar.gz" -o ${dst}

    tar -zxf ${dst} -C build
    if [ ! -f build/fisco-bcos ];then
        error_message " download fisco-bcos $version failed."
    fi

    fisco_path=$dirpath'/build/fisco-bcos'

    fisco_bcos_version_check ${version} ${fisco_path} "true"
}

fisco_path='/usr/local/bin/fisco-bcos'
specified_path="false"
download="false"
clone_and_build="true"
build_opr="false"
expand_opr="false"

function init_fisco()
{
    local version=${FISCO_BCOS_VERSION}

    if [ "true" == ${specified_path} ];then
        # fisco-bcos specified path
        fisco_bcos_version_check ${version} ${fisco_path} "true"
    elif [ "true" == ${download} ];then
        # download fisco from github
        download_fisco ${version}
    else
        # clone FISCO-BCOS source and build fisco-bcos
        clone_and_build_fisco ${version} ${fisco_path}
    fi
}

function help() 
{
    echo "Usage:"
    echo "Optional:"
    echo "    -p  <path>          The fisco-bcos path. "
    echo "    -d                  Download the specified fisco-bcos version from github. "
    echo "    -c                  Clone and build fisco-bcos if /usr/local/bin/fisco-bcos is not exist or not the specified version. "
    echo "    -b/build            Build opration. "            
    echo "    -e/expand           Expand operation. "
    echo "    -v                  Version info. "
    echo "    -h                  Help."
    echo "Example:"
    echo "    bash generate_installation_packages.sh build "
    echo "    bash generate_installation_packages.sh -p ../../fisco-bcos "
    echo "    bash generate_installation_packages.sh -d -e "
    exit 0
}

while getopts "p:dcbevh" option;do
    case $option in
    p) specified_path="true"; fisco_path=$OPTARG;;
    d) download="true";;
    c) clone_and_build="true";;
    b) build_opr="true";;
    e) expand_opr="true";;
    v) version;;
    h) help;;
    esac
done

if [ "expand" == "$1" ];then
    expand_opr="true";
elif [ "build" == "$1" ];then
    build_opr="true";
elif [ "version" == "$1" ];then
    version;
fi

if [ "true" == ${build_opr} ];then
    build
elif [ "true" == ${expand_opr} ];then
    expand
else
    help
fi



