#!/bin/bash

source ./openssl_conf.sh

agency=$1
sdk=$2

if [ -z "$agency" ];  then
    echo "Usage:sdk.sh   agency_name sdk_name "
elif [ -z "$sdk" ];  then
    echo "Usage:sdk.sh   agency_name sdk_name "
elif [ ! -d "$agency" ]; then
    echo "$agency DIR Don't exist! please Check DIR!"
elif [ ! -f "$agency/agency.key" ]; then
    echo "$agency/agency.key  Don't exist! please Check DIR!"
elif [  -d "$agency/$sdk" ]; then
    echo "$agency/$sdk DIR exist! please clean all old DIR!"
else
    cd  $agency
    mkdir -p $sdk
    
    openssl ecparam -out sdk.param -name secp256k1
    openssl genpkey -paramfile sdk.param -out sdk.key
    openssl pkey -in sdk.key -pubout -out sdk.pubkey
    openssl req -new -key sdk.key -config cert.cnf  -out sdk.csr -subj $OPENSSLSUBJECT
    openssl x509 -req -days 3650 -in sdk.csr -CAkey agency.key -CA agency.crt -force_pubkey sdk.pubkey -out sdk.crt -CAcreateserial -extensions v3_req -extfile cert.cnf
    openssl ec -in sdk.key -outform DER |tail -c +8 | head -c 32 | xxd -p -c 32 | cat >sdk.private
   
    cp ca.crt ca-agency.crt
    more agency.crt | cat >>ca-agency.crt
    cp ca-agency.crt $sdk
    mv sdk.key sdk.csr sdk.crt sdk.param sdk.private sdk.pubkey  $sdk

    cd $sdk
    mv ca-agency.crt ca.crt
    echo ${CLIENTCERT_PWD} > pwd.conf
    openssl pkcs12 -export -name client -in sdk.crt -inkey sdk.key -out keystore.p12 -password file:pwd.conf 
    keytool -importkeystore -destkeystore client.keystore -srckeystore keystore.p12 -srcstoretype pkcs12 -alias client -srcstorepass ${CLIENTCERT_PWD} -deststorepass ${KEYSTORE_PWD}

    echo "Build  $sdk Crt suc!!!"
fi
