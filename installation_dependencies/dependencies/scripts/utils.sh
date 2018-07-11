#!/bin/bash

#check ubuntu os or not
function is_ubuntu_os()
{
    if grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        return 1
    else
        return 0
    fi
}

#check if $1 install
function check_if_install()
{
    echo " ===>> $1 checking >>"
    type $1 >/dev/null 2>&1
    ret=$?
    if [ $ret -eq 0  ];then
        echo "       $1 installed."
        return 1
    else
        echo "      XXXXXXX $1 not installed."
        return 0
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

function request_sudo_permission() 
{
    echo "    checking permission..."
    sudo echo -n " "

    if [ $? -ne 0 ]
    then
        echo "no sudo permission, please add youself in the sudoers"
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