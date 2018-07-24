#!/bin/bash

#set -e

#Oracle JDK 1.8 be requied.
function java_version_check()
{
    type java >/dev/null 2>&1
    if [ $? -ne 0 ];then
        { echo >&2 "ERROR - java is not installed, Oracle JDK 1.8 be requied."; exit 1; }
    fi

    #JAVA version
    JAVA_VER=$(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*".*/\1\2/p;')
    #Oracle JDK 1.8
    if [ $JAVA_VER -eq 18 ] && [[ $(java -version 2>&1 | grep "TM") ]];then
        return 
    fi

    { echo >&2 "ERROR - Oracle JDK 1.8 be requied, now JDK is "`java -version`; exit 1; }
} 

#openssl 1.0.2 be requied.
function openssl_version_check()
{
    type openssl >/dev/null 2>&1
    if [ $? -ne 0 ];then
        { echo >&2 "OpenSSL is not installed, OpenSSL 1.0.2 be requied."; exit 1; }
    fi

    #openssl version
    OPENSSL_VER=$(openssl version 2>&1 | sed -n ';s/.*OpenSSL \(.*\)\.\(.*\)\.\([0-9]*\).*/\1\2\3/p;')

    #openssl 1.0.2
    if [ $OPENSSL_VER -eq 102 ];then
        return 
    fi

    { echo >&2 "OpenSSL 1.0.2 be requied , now OpenSSL version is "`openssl version`; exit 1; }
}