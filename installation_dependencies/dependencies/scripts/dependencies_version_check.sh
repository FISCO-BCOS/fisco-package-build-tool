#!/bin/bash

#set -e

#Oracle JDK 1.8 be requied.
function java_version_check()
{
    type java >/dev/null 2>&1
    if [ $? -ne 0 ];then
        { echo >&2 "ERROR - java is not installed, Oracle JDK 1.8 be requied."; exit 1; }
    fi

    type keytool >/dev/null 2>&1
    if [ $? -ne 0 ];then
        { echo >&2 "ERROR - keytool is not installed, Oracle JDK 1.8 be requied."; exit 1; }
    fi

    #JAVA version
    JAVA_VER=$(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*".*/\1\2/p;')
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
    type openssl >/dev/null 2>&1
    if [ $? -ne 0 ];then
        { echo >&2 "ERROR - OpenSSL is not installed, OpenSSL 1.0.2 be requied."; exit 1; }
    fi

    #openssl version
    OPENSSL_VER=$(openssl version 2>&1 | sed -n ';s/.*OpenSSL \(.*\)\.\(.*\)\.\([0-9]*\).*/\1\2\3/p;')

    #openssl 1.0.2
    if [ $OPENSSL_VER -eq 102 ];then
        return 
    fi

    { echo >&2 "ERROR - OpenSSL 1.0.2 be requied , now OpenSSL version is "`openssl version`; exit 1; }
}