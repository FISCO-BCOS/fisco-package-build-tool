#!/bin/bash

# print message to stderr , if need and will exit
function error_message()
{
    local message=$1
    local is_exit=$2
#    echo "ERROR - ${message}" >&2 
    echo "ERROR - ${message}"
    if [ -z "$is_exit" ] || [ "$is_exit" != "false" ];then
        exit 1
    fi
}


#check if the port is used
function check_port() 
{
    echo "    check port is "$1
    if ! sudo lsof -i:$1 | egrep LISTEN
    then
        return 0
    else
        return 1
    fi
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

function replace_dot_with_underline()
{
    echo $1 | sed -e "s/\./_/g"
}

#check if file exist
function check_file_exist()
{
    local file_name=$1
    if ! [ -f ${file_name} ]
    then
        return 1
    fi
    return 0
}

#check if file empty
function check_file_empty()
{
    local file_name=$1
    if [ -s ${file_name} ];then
        return 1
    fi

    return 0
}

#tar file or dictionary
function tar_tool()
{
    local file=$1
    if [ -f $current_node_path".tgz" ];then
        echo $current_node_path".tgz already exist ~"
    else
        tar -zcvf $current_node_path".tgz" $current_node_path
    fi
}
