#!/bin/bash

#check if the port is used
function check_port() 
{
     echo "    check port is "$1
     if ! sudo lsof -i:$1 | egrep LISTEN
    then
        #echo "checking port , $1 is free"
        return 0
    else
        #echo "checking port , $1 is occupied"
        return 1
    fi
}

#print error message
function error_msg() 
{
    echo $1 >> $BUILD_ERROR_LOG
}

function request_sudo_permission() 
{
    echo "    checking permission..."
    sudo echo -n " "

    if [ $? -ne 0 ]
    then
        error_msg "no sudo permission, please add youself in the sudoers"
        #exit
        return 2
    fi

    return 0
}

function is_valid_ip()
{
    if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function print_dash()
{
    local columns=$(tput cols)
    for((j=0;j<${columns};j++))
    do
        echo -n "-";
    done
}

function print_install_result()
{
    local output_message=$1
    echo "    Installing : ${output_message}"
    return 0
}

function print_install_info()
{
    local output_message=$1
    echo "          info : ${output_message}"
    return 0
}

# how to use:
# spinner $! "Installing..."
spinner()
{
    local pid=$1
    local info=$2
    local delay=0.1
    local spinstr='|/-\'
    echo -n $info
    while [ "$(ps a | awk '{print $1}' | grep $pid)"  ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo
}

function build_crypto_mode_json_file()
{
    local current_host_rlp_dir=$1
    local crypto_mode=$2
    local key_center_url=""
    if [ "$3" == "null" ]
    then
        key_center_url=""
    else
        key_center_url="https://$3"
    fi
    local current_node_rlp_dir=$4
    local super_key=$5

    local crypto_mode_json_file_path=$current_host_rlp_dir/cryptomod.json
    echo $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies/tpl_dir/cryptomod.json.tpl
    echo $current_host_rlp_dir/cryptomod.json

    export CRYPTO_MODE_TPL=$crypto_mode
    export RLP_CREATE_PATH_TPL=$current_node_rlp_dir/network.rlp
    export DATA_KEY_CREATE_PATH_TPL=$current_node_rlp_dir/datakey
    export KEY_CENTER_URL_TPL=$key_center_url
    export SUPER_KEY_TPL=${super_key}
    MYVARS='${CRYPTO_MODE_TPL}:${RLP_CREATE_PATH_TPL}:${DATA_KEY_CREATE_PATH_TPL}:${KEY_CENTER_URL_TPL}:${SUPER_KEY_TPL}'
    envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies/tpl_dir/cryptomod.json.tpl > $current_host_rlp_dir/cryptomod.json

    cat $current_host_rlp_dir/cryptomod.json
    echo "envsubst $MYVARS < $INSTALLATION_DEPENENCIES_LIB_DIR/dependencies/tpl_dir/cryptomod.json.tpl > $current_host_rlp_dir/cryptomod.json"
}
