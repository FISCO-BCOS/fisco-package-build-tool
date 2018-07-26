#!/bin/bash

# set -e

#check user has sudo permission
function request_sudo_permission() 
{
    sudo echo -n " "

    if [ $? -ne 0 ]; then
        { echo >&2 "ERROR - no sudo permission, please add youself in the sudoers"; exit 1; }
    fi
}

#check if $1 is install
function check_if_install()
{
    type $1 >/dev/null 2>&1
    if [ $? -ne 0 ];then
        { echo >&2 "ERROR - $1 is not installed."; exit 1; }
    fi
}

#Oracle JDK 1.8 be requied.
function java_version_check()
{
    check_if_install java

    check_if_install keytool

    #JAVA version
    JAVA_VER=$(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*".*/\1\2/p;')

    if [ -z "$JAVA_VER" ];then
        { echo >&2 "ERROR - failed to get java version, version is "`java -version`; exit 1; }
    fi    

    #Oracle JDK 1.8
    if [ $JAVA_VER -eq 18 ] && [[ $(java -version 2>&1 | grep "TM") ]];then
        #is java and keytool match ?
        JAVA_PATH=$(dirname `which java`)
        KEYTOOL_PATH=$(dirname `which keytool`)
        if [ "$JAVA_PATH" = "$KEYTOOL_PATH" ];then
            echo " java path => "${JAVA_PATH}
            echo " keytool path => "${KEYTOOL_PATH}
            return
        fi

        { echo >&2 "ERROR - java and keytool is not match, java is ${JAVA_PATH} , keytool is ${KEYTOOL_PATH}"; exit 1; }
    fi

    { echo >&2 "ERROR - Oracle JDK 1.8 be requied, now JDK is "`java -version`; exit 1; }
} 

#openssl 1.0.2 be requied.
function openssl_version_check()
{
    check_if_install openssl

    #openssl version
    OPENSSL_VER=$(openssl version 2>&1 | sed -n ';s/.*OpenSSL \(.*\)\.\(.*\)\.\([0-9]*\).*/\1\2\3/p;')

    if [ -z "$OPENSSL_VER" ];then
        { echo >&2 "ERROR - failed to get openssl version, version is "`openssl version`; exit 1; }
    fi

    #openssl 1.0.2
    if [ $OPENSSL_VER -eq 102 ];then
        return 
    fi

    { echo >&2 "ERROR - OpenSSL 1.0.2 be requied , now OpenSSL version is "`openssl version`; exit 1; }
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

    # git
    check_if_install git
    # lsof
    check_if_install lsof
    # envsubst
    check_if_install envsubst
    # xxd
    check_if_install xxd
    # bc
    check_if_install bc
    # crudini
    check_if_install crudini

    # add more check here
}
