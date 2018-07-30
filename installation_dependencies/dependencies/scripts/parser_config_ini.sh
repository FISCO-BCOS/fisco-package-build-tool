#!/bin/bash

# init function , install crudini
function parser_ini_init() 
{
    local myname="parser config ini"
    # Check for 'uname' and abort if it is not available.
    uname -v > /dev/null 2>&1 || { echo >&2 "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }

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
            { echo >&2 "ERROR - Unsupported or unidentified Linux distro."; exit 1; }
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
                { echo >&2 "ERROR - Unsupported Linux distribution: $DISTRO_NAME."; exit 1; }
                ;;
        esac # case $DISTRO_NAME

        ;; #Linux)

    #------------------------------------------------------------------------------
    # Other platform (not Linux, FreeBSD or macOS).
    #------------------------------------------------------------------------------
    *)
        #other
        { echo >&2 "ERROR - Unsupported or unidentified operating system."; exit 1; }
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
        else
            { echo >&2 "ERROR - ini config get failed, section is $section param is $param."; exit 1; }
        fi
    fi

    echo "$value"
}

#env set
function env_set()
{
    local env=$1
    local value=$2
    export $env=$value
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
    echo "===>>> github_url is"${github_url}
    env_set "FISCO_BCOS_GIT" ${github_url}

    local param="fisco_bcos_src_local"
    local fisco_bcos_src_local=$(ini_get $file $section $param)
    echo "===>>> fisco_bcos_src_local is"${fisco_bcos_src_local}
    env_set "FISCO_BCOS_LOCAL_PATH" ${fisco_bcos_src_local}

    local param="fisco_bcos_version"
    local fisco_bcos_version=$(ini_get $file $section $param)
    echo "===>>> fisco_bcos_version is"${fisco_bcos_version}
    env_set "FISCO_BCOS_VERSION" ${fisco_bcos_version}

# [docker]
# docker_toggle=1
# docker_repository=fiscoorg/fisco-octo
# docker_version=v1.3.1

# [docker] section parser
    local section="docker"

    local param="docker_toggle"
    local docker_toggle=$(ini_get $file $section $param)
    echo "===>>> docker_toggle is"${docker_toggle}
    env_set "DOCKER_TOGGLE" ${docker_toggle}

    local param="docker_repository"
    local docker_repository=$(ini_get $file $section $param)
    echo "===>>> docker_repository is"${docker_repository}
    env_set "DOCKER_REPOSITORY" ${docker_repository}

    local param="docker_version"
    local docker_version=$(ini_get $file $section $param)
    echo "===>>> docker_version is"${docker_version}
    env_set "DOCKER_VERSION" ${docker_version}

# [web3sdk]
# ca_pwd=123456
# jks_pwd=123456

# [web3sdk] section
    local section="web3sdk"
   
    local param="ca_pwd"
    local ca_pwd=$(ini_get $file $section $param)
    echo "===>>> ca_pwd is"${ca_pwd}
    env_set "CA_PWD" ${ca_pwd}

    local param="jks_pwd"
    local jks_pwd=$(ini_get $file $section $param)
    echo "===>>> jks_pwd is"${jks_pwd}
    env_set "JKS_PWD" ${jks_pwd}

# [other]
# ca_ext=1
# [other] section
    local section="other"
   
    local param="ca_ext"
    local ca_ext=$(ini_get $file $section $param)
    echo "===>>> ca_ext is"${ca_ext}
    env_set "CA_EXT_MODE" ${ca_ext}

# [ports]
# p2p_port=30303
# rpc_port=8545
# channel_port=8821
# [ports] section
    local section="ports"

    local param="p2p_port"
    local p2p_port=$(ini_get $file $section $param)
    echo "===>>> p2p_port is"${p2p_port}
    env_set "P2P_PORT_NODE" ${p2p_port}

    local param="rpc_port"
    local rpc_port=$(ini_get $file $section $param)
    echo "===>>> rpc_port is"${rpc_port}
    env_set "RPC_PORT_NODE" ${rpc_port}

    local param="channel_port"
    local channel_port=$(ini_get $file $section $param)
    echo "===>>> channel_port is"${channel_port}
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

        env_set "NODE_INFO_"$node_index ${node_info}

        node_index=$(($node_index+1))
    done

    env_set "NODE_COUNT" ${node_index}
}

# is node valid
function valid_node()
{
    local node="$1"
    local arr=($node)

    # node0= 127.0.0.1  0.0.0.0  4  agent
    local p2pip=$arr[0]
    local listenip=$arr[1]
    local count=$arr[2]
    local agent=$arr[3]

    is_p2pip_valid=$(is_valid_ip $p2pip)
    is_listenip_ip_valid=$(is_valid_ip $listenip)

    if [ "$is_p2pip_valid" = "false" ];then
        { echo >&2 "ERROR - [nodes] p2pip invalid, node => ${node} ."; exit 1; }
    elif [ "$is_listenip_ip_valid" = "false" ]
        { echo >&2 "ERROR - [nodes] listenip invalid, node => ${node} ."; exit 1; }
    fi

    if [ $count -le 0 ];then
         { echo >&2 "ERROR - [nodes] count invalid, node => ${node} ."; exit 1; }
    fi

    if [ -z $agent ];then
         { echo >&2 "ERROR - [nodes] agent invalid, node => ${node} ."; exit 1; }
    fi
}

# check all env
function ini_param_check()
{
    # env FISCO_BCOS_GIT 
    local github_url=${FISCO_BCOS_GIT}
    if [ -z ${github_url} ];then
        { echo >&2 "ERROR - FISCO_BCOS_GIT cannot find ,[common] github_url may not set ."; exit 1; }
    fi

    # env FISCO_BCOS_LOCAL_PATH 
    local fisco_bcos_src_local=${FISCO_BCOS_LOCAL_PATH}
    if [ -z ${fisco_bcos_src_local} ];then
        { echo >&2 "ERROR - FISCO_BCOS_LOCAL_PATH cannot find ,[common] fisco_bcos_src_local may not set ."; exit 1; }
    fi

    # env FISCO_BCOS_VERSION 
    local fisco_bcos_version=${FISCO_BCOS_VERSION}
    if [ -z ${fisco_bcos_version} ];then
        { echo >&2 "ERROR - FISCO_BCOS_VERSION cannot find ,[common] fisco_bcos_version may not set ."; exit 1; }
    fi

    # env DOCKER_TOGGLE 
    local docker_toggle=${DOCKER_TOGGLE}
    if [ -z ${docker_toggle} ];then
        { echo >&2 "ERROR - DOCKER_TOGGLE cannot find ,[docker] docker_toggle may not set ."; exit 1; }
    fi

    # env DOCKER_REPOSITORY 
    local docker_repository=${DOCKER_REPOSITORY}
    if [ -z ${docker_repository} ];then
        { echo >&2 "ERROR - DOCKER_REPOSITORY cannot find ,[docker] docker_repository may not set ."; exit 1; }
    fi

    # env DOCKER_VERSION 
    local docker_version=${DOCKER_VERSION}
    if [ -z ${docker_version} ];then
        { echo >&2 "ERROR - DOCKER_VERSION cannot find ,[docker] docker_version may not set ."; exit 1; }
    fi

    # env CA_EXT_MODE 
    local ca_ext=${CA_EXT_MODE}
    if [ -z ${ca_ext} ];then
        { echo >&2 "ERROR - CA_EXT_MODE cannot find ,[other] ca_ext may not set ."; exit 1; }
    fi

    # env P2P_PORT_NODE 
    local p2p_port=${P2P_PORT_NODE}
    if [ -z ${p2p_port} ];then
        { echo >&2 "ERROR - P2P_PORT_NODE cannot find ,[port] p2p_port may not set ."; exit 1; }
    fi
    if [ ${p2p_port} -le 0 ] || [ ${p2p_port} -ge 65536 ];then
        { echo >&2 "ERROR - P2P_PORT_NODE invalid ,[port] p2p_port invalid => ${P2P_PORT_NODE} ."; exit 1; }
    fi

    # env P2P_PORT_NODE 
    local rpc_port=${RPC_PORT_NODE}
    if [ -z ${rpc_port} ];then
        { echo >&2 "ERROR - RPC_PORT_NODE cannot find ,[port] rpc_port may not set ."; exit 1; }
    fi
    if [ ${rpc_port} -le 0 ] || [ ${rpc_port} -ge 65536 ];then
        { echo >&2 "ERROR - RPC_PORT_NODE invalid ,[ports] rpc_port invalid => ${RPC_PORT_NODE} ."; exit 1; }
    fi

    # env CHANNEL_PORT_NODE 
    local channel_port=${CHANNEL_PORT_NODE}
    if [ -z ${channel_port} ];then
        { echo >&2 "ERROR - CHANNEL_PORT_NODE cannot find ,[ports] channel_port may not set ."; exit 1; }
    fi
    if [ ${channel_port} -le 0 ] || [ ${channel_port} -ge 65536 ];then
        { echo >&2 "ERROR - CHANNEL_PORT_NODE invalid ,[ports] channel_port invalid => ${CHANNEL_PORT_NODE} ."; exit 1; }
    fi

    local node_count=${NODE_COUNT}
    if [ -z "$node_count" ];then
        { echo >&2 "ERROR - node_count invalid ,[nodes] invalid ."; exit 1; }
    fi

    if [ $node_count -le 0 ];then
        { echo >&2 "ERROR - node_count invalid ,[nodes] invalid ."; exit 1; }
    fi

    local node_index=0
    while [ $node_index -lt $node_count ]
    do
        local node_info=${"NODE_INFO_$node_index"}
        
        valid_node $node_info

        env_set "NODE_INFO_"$node_index (${node_info})

        node_index=$(($node_index+1))
    done
}