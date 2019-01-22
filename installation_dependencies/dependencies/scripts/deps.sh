#!/bin/bash

OS_CENTOS='centos'
OS_UBUNTU='ubuntu'
OS_REDHAT='redhat'
OS_ORACLE='oracle'

function alarm()
{
    { echo 1>&2  "ERROR - $1"; exit 1; }
}

function os_check() 
{
    local os_version=''
    # Check for 'uname' and abort if it is not available.
    uname -v > /dev/null 2>&1 || { alarm " cannot use 'uname' to identify the platform."; }

    case $(uname -s) in
    #------------------------------------------------------------------------------
    # Linux
    #------------------------------------------------------------------------------
    Linux)

        if [ ! -f "/etc/os-release" ];then
             alarm "Unkown Linux distro, file /etc/os-release not exist"
        fi
        DISTRO_NAME=$(. /etc/os-release; echo $NAME)

        case $DISTRO_NAME in
    #------------------------------------------------------------------------------
    # Ubuntu  # At least 16.04
    #------------------------------------------------------------------------------
            Ubuntu*)

                UBUNTU_VERSION=""
                type lsb_release >/dev/null 2>&1
                if [ $? -eq 0 ];then
                    UBUNTU_VERSION=$(lsb_release -r | awk '{print $2}')
                else
                    UBUNTU_VERSION=$(. /etc/os-release; echo $VERSION | awk '{print $1}')
                fi

                ver=$(echo "$UBUNTU_VERSION" | awk -F . '{print $1$2}')
                #Ubuntu 16.04 or Ubuntu 16.04+
                if [ $ver -ne 1604 ];then
                    alarm "Unsupported Ubuntu Version. 16.04 is required, now is $UBUNTU_VERSION"
                fi

                os_version=$OS_UBUNTU

                ;;
    #------------------------------------------------------------------------------
    # CentOS  # At least 7.2
    #------------------------------------------------------------------------------
            CentOS*)
                CENTOS_VERSION=""
                if [ -f /etc/centos-release ];then
                    CENTOS_VERSION=$(cat /etc/centos-release)
                elif [ -f /etc/redhat-release ];then
                    CENTOS_VERSION=$(cat /etc/redhat-release)
                elif [ -f /etc/system-release ];then
                    CENTOS_VERSION=$(cat /etc/system-release)
                fi

                if [ -z "$CENTOS_VERSION" ];then
                    alarm "Unable to determine CentOS Version."
                fi

                ver=$(echo "$CENTOS_VERSION" | awk '{print $4}' | awk -F . '{print $1$2}')
                # CentOS 7.2 or CentOS 7.2+
                if [ $ver -lt 72 ];then
                    alarm "Unsupported CentOS Version, At least 7.2 is required, now is $CENTOS_VERSION"
                fi

                os_version=$OS_CENTOS
                ;;
    #------------------------------------------------------------------------------
    # Red Hat Enterprise Linux Server
    #------------------------------------------------------------------------------
            Red*) 
                REDHAT_LINUX_VERSION=""
                 if [ -f /etc/redhat-release ];then
                    REDHAT_LINUX_VERSION=$(cat /etc/redhat-release)
                elif [ -f /etc/system-release ];then
                    REDHAT_LINUX_VERSION=$(cat /etc/system-release)
                fi

                if [ -z "$REDHAT_LINUX_VERSION" ];then
                    alarm "Unable to determine Red Hat Enterprise Linux Server."
                fi

                ver=$(echo "$REDHAT_LINUX_VERSION" | awk '{print $7}' | awk -F . '{print $1$2}')

                #Red Hat Enterprise Linux Server+
                if [ $ver -lt 74 ];then
                    alarm "Unsupported Red Hat Version, At least 7.4 Red Hat is required, now is $REDHAT_LINUX_VERSION"
                fi

                os_version=$OS_REDHAT

                ;;           
    #------------------------------------------------------------------------------
    # Oracle Linux Server # At least 7.4
    #------------------------------------------------------------------------------
            Oracle*) 
                ORACLE_LINUX_VERSION=""
                if [ -f /etc/oracle-release ];then
                    ORACLE_LINUX_VERSION=$(cat /etc/oracle-release)
                elif [ -f /etc/system-release ];then
                    ORACLE_LINUX_VERSION=$(cat /etc/system-release)
                fi

                if [ -z "$ORACLE_LINUX_VERSION" ];then
                    alarm "Unable to determine Oracle Linux version."
                fi

                ver=$(echo "$ORACLE_LINUX_VERSION" | awk '{print $5}' | awk -F . '{print $1$2}')
                #Oracle Linux 7.4 or Oracle Linux 7.4+
                if [ $ver -lt 74 ];then
                    alarm "Unsupported Oracle Linux, At least 7.4 is required, now is $ORACLE_LINUX_VERSION"
                fi

                os_version=$OS_ORACLE

                ;;
    #------------------------------------------------------------------------------
    # Other Linux
    #------------------------------------------------------------------------------
            *)
                alarm "Unsupported Linux distribution: $DISTRO_NAME."
                ;;
        esac # case $DISTRO_NAME

        ;; #Linux)

    #------------------------------------------------------------------------------
    # Other platform (not Linux, FreeBSD or macOS).
    #------------------------------------------------------------------------------
    *)
        #other
        alarm "Unsupported or Unidentified OS."
        ;;
    esac

    echo ${os_version}
}


REDHAT_DEPS="nmap openssl openssl-devel leveldb-devel libcurl-devel libmicrohttpd-devel gmp-devel libuuid-devel python-pip"
UBUNTU_DEPS="nmap openssl build-essential libcurl4-openssl-dev libgmp-dev libleveldb-dev  libmicrohttpd-dev libminiupnpc-dev libssl-dev libkrb5-dev uuid-dev python-pip"

#check if $1 is install
function check_install()
{
    type $1 >/dev/null 2>&1
    if [ $? -ne 0 ];then
        return 1
    fi

    return 0
}

function yum_is_install()
{
    if yum list installed "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function apt_is_install()
{
    if sudo dpkg -s $1 | egrep -i Status >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function deps_install() 
{
    # sudo permission check
    sudo echo -n " "
    if [ $? -ne 0 ]; then
        alarm " no sudo permission, please add youself in the sudoers."
    fi

    # os_check
    os_version=$(os_check)

    case ${os_version} in
    $OS_CENTOS|$OS_REDHAT|$OS_ORACLE)
        echo " yum install deps => ${REDHAT_DEPS}"
        sudo yum -y install ${REDHAT_DEPS} >/dev/null 2>&1
        # for dep in ${REDHAT_DEPS}
        # do
        #     sudo yum -y install ${dep} >/dev/null 2>&1
        # done
    ;;
    $OS_UBUNTU)
        echo " apt-get install deps => ${UBUNTU_DEPS}"
        sudo apt-get -y install ${UBUNTU_DEPS} >/dev/null 2>&1
        # for dep in ${UBUNTU_DEPS}
        # do
        #     sudo apt-get install ${dep} >/dev/null 2>&1
        # done
    ;;
    esac
}

function deps_check()
{
     # sudo permission check
    sudo echo -n " "
    if [ $? -ne 0 ]; then
        alarm " no sudo permission, please add youself in the sudoers."
    fi

    # os_check
    os_version=$(os_check)
    deps=''
    case ${os_version} in
    $OS_CENTOS|$OS_REDHAT|$OS_ORACLE)
        for i in ${REDHAT_DEPS}
        do
            if $(yum_is_install $i);then
                echo " $i is installed."
            else
                alarm " $i is not installed."
            fi
        done
    ;;
    $OS_UBUNTU)
        for i in ${UBUNTU_DEPS}
        do
            if $(apt_is_install $i);then
                echo " $i is installed."
            else
                alarm " $i is not installed."
            fi
        done
    ;;
    esac
}

#openssl 1.0.2 be requied.
function openssl_check()
{
    if $(check_install openssl);then
       echo " " >/dev/null 2>&1
    else
        alarm " openssl is not installed."
    fi

    #openssl version
    OPENSSL_VER=$(openssl version 2>&1 | sed -n ';s/.*OpenSSL \(.*\)\.\(.*\)\.\([0-9]*\).*/\1\2\3/p;')
    if [ -z "$OPENSSL_VER" ];then
        alarm " OpenSSL unkown version, now is `openssl version`"
    fi

    #openssl 1.0.2
    if [ $OPENSSL_VER -ne 102 ];then
        alarm " OpenSSL 1.0.2 be requied , now is `openssl version`"
    fi

    echo " openssl version is ${OPENSSL_VER}. "
}

# OracleJDK 1.8 + or OpenJDK 1.9 +
function java_check()
{
    if $(check_install java);then
        echo " " >/dev/null 2>&1
    else
        alarm " java is not installed."
    fi

    #JAVA version
    JAVA_VER=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | awk -F . '{print $1$2}')
    if [ -z "$JAVA_VER" ];then
        alarm "java unkown version, now is `java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}'`."
    fi 

    if  java -version 2>&1 | egrep -i openjdk >/dev/null 2>&1;then
    #openjdk
        if [ ${JAVA_VER} -le 18 ];then
            alarm "OpenJDK need 1.9 or above, now is OpenJDK - ${JAVA_VER}. "
        fi
    else
        if [ ${JAVA_VER} -lt 18 ];then
            alarm "OracleJDK need 1.8 or above, now is OracleJDK - ${JAVA_VER}. "
        fi
    fi 

    echo " java version is ${JAVA_VER}. "
}

for opt in $@
do
    echo " opt is $opt"
    case $opt in
        'os_check') os_check ;;
        'deps_check') deps_check ;;
        'deps_install') deps_install ;;
        'java_check') java_check ;;
        'openssl_check') openssl_check ;;
        'all') deps_install; deps_check; openssl_check; java_check ;;
    esac
done
