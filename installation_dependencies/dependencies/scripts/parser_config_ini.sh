#!/bin/bash

#set -e
# init function , install crudini
function parser_ini_init() 
{
    local myname="parser config ini"
    # Check for 'uname' and abort if it is not available.
    uname -v > /dev/null 2>&1 || { echo "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }

    case $(uname -s) in 

    #------------------------------------------------------------------------------
    # macOS
    #------------------------------------------------------------------------------
    Darwin)
        case $(sw_vers -productVersion | awk -F . '{print $1"."$2}') in
            *)

            ;;
        esac #case $(sw_vers

        ;; #Darwin)
        
    #------------------------------------------------------------------------------
    # Linux
    #------------------------------------------------------------------------------
    Linux)

        if [ ! -f "/etc/os-release" ];then
            error_message "ERROR - Unsupported or unidentified Linux distro."
        fi

        DISTRO_NAME=$(. /etc/os-release; echo $NAME)
        # echo "Linux distribution: $DISTRO_NAME."

        case $DISTRO_NAME in
    #------------------------------------------------------------------------------
    # Ubuntu  # At least 16.04
    #------------------------------------------------------------------------------
            Ubuntu*)

                    sudo apt-get -y install crudini

                ;;
    #------------------------------------------------------------------------------
    # CentOS  # At least 7.2
    #------------------------------------------------------------------------------
            CentOS*)

                    sudo yum -y install crudini

                ;;
    #------------------------------------------------------------------------------
    # Oracle Linux Server # At least 7.4
    #------------------------------------------------------------------------------
            Oracle*) 
                   
                    sudo yum -y install crudini

                ;;
    #------------------------------------------------------------------------------
    # Other Linux
    #------------------------------------------------------------------------------
            *)
                error_message "ERROR - Unsupported Linux distribution: $DISTRO_NAME."
                ;;
        esac # case $DISTRO_NAME

        ;; #Linux)

    #------------------------------------------------------------------------------
    # Other platform (not Linux, FreeBSD or macOS).
    #------------------------------------------------------------------------------
    *)
        #other
        error_message "ERROR - Unsupported or unidentified operating system."
        ;;
    esac
}

#check if ip valid
function is_valid_ip()
{
    if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "true"
    else
        echo "false"
    fi
}

#ini file get opr
function ini_get()
{
    local file=$1
    local section=$2
    local param=$3
    local no_exit=$4

    local value=$(crudini --get $file $section $param)
    if [ $? -ne 0 ];then
        if [ "${no_exit}" = "true" ];then
            #{ echo >&2 "ERROR - ini config get failed, section is $section param is $param."; exit 1; }
	    echo ""
        else
            error_message "ERROR - ini config get failed, section is $section param is $param."
        fi
    fi

    echo "$value"
}

#env set
function env_set()
{
    local env="$1"
    local value="$2"
    export $env="$value"
}

#parser config.ini file
function parser_ini()
{
    local file=$1

# [common]
# github_url=https://github.com/FISCO-BCOS/FISCO-BCOS.git
# fisco_bcos_src_local=../fisco_bcos_version
# fisco_bcos_version=1.3.1

# [common] section parser
    local section="common"

    local param="github_url"
    local github_url=$(ini_get $file $section $param)
    echo "===>>> github_url = "${github_url}
    env_set "FISCO_BCOS_GIT" ${github_url}

    local param="fisco_bcos_src_local"
    local fisco_bcos_src_local=$(ini_get $file $section $param)
    echo "===>>> fisco_bcos_src_local = "${fisco_bcos_src_local}
    env_set "FISCO_BCOS_LOCAL_PATH" ${fisco_bcos_src_local}

    local param="fisco_bcos_version"
    local fisco_bcos_version=$(ini_get $file $section $param)
    echo "===>>> fisco_bcos_version = "${fisco_bcos_version}
    env_set "FISCO_BCOS_VERSION" ${fisco_bcos_version}

# [docker]
# docker_toggle=1
# docker_repository=fiscoorg/fisco-octo
# docker_version=v1.3.1

# [docker] section parser
    local section="docker"

    local param="docker_toggle"
    local docker_toggle=$(ini_get $file $section $param)
    echo "===>>> docker_toggle = "${docker_toggle}
    env_set "DOCKER_TOGGLE" ${docker_toggle}

    local param="docker_repository"
    local docker_repository=$(ini_get $file $section $param)
    echo "===>>> docker_repository = "${docker_repository}
    env_set "DOCKER_REPOSITORY" ${docker_repository}

    local param="docker_version"
    local docker_version=$(ini_get $file $section $param)
    echo "===>>> docker_version = "${docker_version}
    env_set "DOCKER_VERSION" ${docker_version}

# [web3sdk]
# keystore_pwd=123456
# clientcert_pwd=123456

# [web3sdk] section
    local section="web3sdk"
   
    local param="keystore_pwd"
    local keystore_pwd=$(ini_get $file $section $param)
    echo "===>>> keystore_pwd = "${keystore_pwd}
    env_set "KEYSTORE_PWD" ${keystore_pwd}

    local param="clientcert_pwd"
    local clientcert_pwd=$(ini_get $file $section $param)
    echo "===>>> clientcert_pwd = "${clientcert_pwd}
    env_set "CLIENTCERT_PWD" ${clientcert_pwd}

# [other]
# ca_ext=1
# [other] section
    local section="other"
   
    local param="ca_ext"
    local ca_ext=$(ini_get $file $section $param)
    echo "===>>> ca_ext = "${ca_ext}
    env_set "CA_EXT_MODE" ${ca_ext}

# [ports]
# p2p_port=30303
# rpc_port=8545
# channel_port=8821
# [ports] section
    local section="ports"

    local param="p2p_port"
    local p2p_port=$(ini_get $file $section $param)
    echo "===>>> p2p_port = "${p2p_port}
    env_set "P2P_PORT_NODE" ${p2p_port}

    local param="rpc_port"
    local rpc_port=$(ini_get $file $section $param)
    echo "===>>> rpc_port = "${rpc_port}
    env_set "RPC_PORT_NODE" ${rpc_port}

    local param="channel_port"
    local channel_port=$(ini_get $file $section $param)
    echo "===>>> channel_port = "${channel_port}
    env_set "CHANNEL_PORT_NODE" ${channel_port}

# [nodes]
# node0= 127.0.0.1  0.0.0.0  4  agent
# [nodes] section
    local section="nodes"
    local max_node=9999999
    local node_index=0
    while [ $node_index -lt $max_node ]
    do
        local param="node"$node_index
        local node_info=$(ini_get $file $section $param "true")
        if [ -z "${node_info}" ];then
            break
        fi

        env_set "NODE_INFO_"$node_index "${node_info}"

        node_index=$(($node_index+1))
    done

    env_set "NODE_COUNT" ${node_index}

}

# is node valid
function valid_node()
{
    local node=($1)

    # node0= 127.0.0.1  0.0.0.0  4  agent
    local p2pip=${node[0]}
    local listenip=${node[1]}
    local count=${node[2]}
    local agent=${node[3]}

    if [ -z "${p2pip}" ];then
        error_message "ERROR - [nodes] p2pip null . node => "$1
    fi

    if [ -z "${listenip}" ];then
        error_message "ERROR - [nodes] listenip null . node => "$1
    fi

    if [ -z "${count}" ];then
        error_message "ERROR - [nodes] count null . node => "$1
    fi

    if [ -z "${agent}" ];then
        error_message "ERROR - [nodes] agent null . node => "$1
    fi

    is_p2pip_valid=$(is_valid_ip $p2pip)
    is_listenip_ip_valid=$(is_valid_ip $listenip)

    if [ "$is_p2pip_valid" = "false" ];then
        error_message "ERROR - [nodes] p2pip invalid, p2pip => ${p2pip} ."
    elif [ "$is_listenip_ip_valid" = "false" ];then
        error_message "ERROR - [nodes] listenip invalid, listenip => ${listenip} ."
    fi

    if [ $count -le 0 ];then
         error_message "ERROR - [nodes] count invalid, count => ${count} ."
    fi

    echo "${p2pip}"
}

# check all env
function ini_param_check()
{
    # env FISCO_BCOS_GIT 
    local github_url=${FISCO_BCOS_GIT}
    if [ -z "${github_url}" ];then
        error_message "ERROR - [common] github_url not set."
    fi

    # env FISCO_BCOS_LOCAL_PATH 
    local fisco_bcos_src_local=${FISCO_BCOS_LOCAL_PATH}
    if [ -z "${fisco_bcos_src_local}" ];then
        error_message "ERROR - [common] fisco_bcos_src_local not set ."
    fi

    # env FISCO_BCOS_VERSION 
    local fisco_bcos_version=${FISCO_BCOS_VERSION}
    if [ -z "${fisco_bcos_version}" ];then
        error_message "ERROR - [common] fisco_bcos_version not set ."
    fi

    echo "$fisco_bcos_version" | egrep "^[[:space:]]*v1.3.([0-9]+)"
    if [ $? -ne 0 ];then
        error_message "ERROR - [common] fisco_bcos_version format invalid, only v1.3.x is support."
    fi

    # env DOCKER_TOGGLE 
    local docker_toggle=${DOCKER_TOGGLE}
    if [ -z "${docker_toggle}" ];then
        error_message "ERROR - [docker] docker_toggle not set ." 
    fi

    # env DOCKER_REPOSITORY 
    local docker_repository=${DOCKER_REPOSITORY}
    if [ -z "${docker_repository}" ];then
        error_message "ERROR - [docker] docker_repository not set ."
    fi

    # env DOCKER_VERSION 
    local docker_version=${DOCKER_VERSION}
    if [ -z "${docker_version}" ];then
        error_message "ERROR - [docker] docker_version not set ."
    fi

    # env CA_EXT_MODE 
    local ca_ext=${CA_EXT_MODE}
    if [ -z "${ca_ext}" ];then
        error_message "ERROR - [other] ca_ext not set ."
    fi

    # env KEYSTORE_PWD
    local keystore_pwd=${KEYSTORE_PWD}
    if [ -z "${keystore_pwd}" ];then
        error_message "ERROR - [web3sdk] keystore_pwd not set ."
    fi

    # env CLIENTCERT_PWD
    local clientcert_pwd=${CLIENTCERT_PWD}
    if [ -z "${clientcert_pwd}" ];then
        error_message "ERROR - [web3sdk] clientcert_pwd not set ."
    fi

    # env P2P_PORT_NODE 
    local p2p_port=${P2P_PORT_NODE}
    if [ -z "${p2p_port}" ];then
        error_message "ERROR - [port] p2p_port not set ."}
    fi
    if [ ${p2p_port} -le 0 ] || [ ${p2p_port} -ge 65536 ];then
        error_message "ERROR - [port] p2p_port invalid => ${P2P_PORT_NODE} ."
    fi

    # env P2P_PORT_NODE 
    local rpc_port=${RPC_PORT_NODE}
    if [ -z "${rpc_port}" ];then
        error_message "ERROR - [port] rpc_port may not set ."
    fi
    if [ ${rpc_port} -le 0 ] || [ ${rpc_port} -ge 65536 ];then
        error_message "ERROR - [ports] rpc_port invalid => ${RPC_PORT_NODE} ."
    fi

    # env CHANNEL_PORT_NODE 
    local channel_port=${CHANNEL_PORT_NODE}
    if [ -z "${channel_port}" ];then
        error_message "ERROR - [ports] channel_port not set ."
    fi
    if [ ${channel_port} -le 0 ] || [ ${channel_port} -ge 65536 ];then
        error_message "ERROR - [ports] channel_port invalid => ${CHANNEL_PORT_NODE} ."
    fi

    local node_count=${NODE_COUNT}
    if [ -z "$node_count" ];then
        error_message "ERROR - node_count null ,[nodes] invalid ."
    fi

    if [ $node_count -le 0 ];then
        error_message "ERROR - node_count invalid ,[nodes] invalid ."
    fi

    declare -A map=()

    local node_index=0
    while [ $node_index -lt $node_count ]
    do
        local node_name=NODE_INFO_${node_index}
        local node_info=`eval echo '$'"$node_name"` 
        local rel=valid_node $"$node_info"        if [ ! -z ${map["$rel"]} ];then
            error_message "ERROR - server repeat , server is "$rel
        fi
        map["$rel"]="exist"

        env_set "NODE_INFO_"$node_index "${node_info}"

        node_index=$(($node_index+1))
    done
}

#load expand config in config.ini
function parser_expand_ini()
{
    local file=$1

# [expand]
# genesis_follow_dir=/follow/

    local section="expand"

    local param="genesis_follow_dir"
    local genesis_follow_dir=$(ini_get $file $section $param)

    env_set "EXPAND_GENESIS_FOLLOW_DIR" ${genesis_follow_dir}
}

# check all env
function expand_param_check()
{
    local section="expand"
   
    local genesis_follow_dir=${EXPAND_GENESIS_FOLLOW_DIR}
    if [ -z "${genesis_follow_dir}" ];then
        error_message "ERROR - [expand] genesis_follow_dir not set ."
    fi
    
    if [ ! -d "${genesis_follow_dir}" ];then
        error_message "ERROR - [expand] genesis_follow_dir is not dir, genesis_ca_dir is "${genesis_ca_dir}
    fi

    local genesis_file=$genesis_ca_dir/genesis.json
    if [ -z "${genesis_file}" ];then
        error_message "ERROR - [expand] genesis_follow_dir genesis.json is not exist , genesis.json is $genesis_file."
    fi

    local system_address_file=$genesis_ca_dir/syaddress.txt
    if [ -z "${system_address_file}" ];then
        error_message "ERROR - [expand] genesis_follow_dir syaddress.txt is not exist , syaddress.txt is ${system_address_file}."
    fi

    local bootstrapnodes_file=$genesis_ca_dir/bootstrapnodes.json
    if [ -z "${bootstrapnodes_file}" ];then
        error_message "ERROR - [expand] genesis_follow_dir bootstrapnodes.json is not exist ,bootstrapnodes.json is ${bootstrapnodes_file}."
    fi
}
