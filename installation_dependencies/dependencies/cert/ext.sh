#!/bin/bash

rootsrc=$3
node=$2
agency=$1

if [ -z $rootsrc ];then
    rootsrc=$PWD
fi

if [ -f $rootsrc/$agency/$node/node.crt ];then

    cd $rootsrc/$agency/$node
    
    openssl x509  -text -in node.crt | sed -n '16,20p' |  sed 's/://g' | tr "\n" " " | sed 's/ //g' | cut -c 3-130 | cat >node.nodeid
    
    if [ "" != "`openssl version | grep 1.0.2k`" ];
    then
        openssl x509  -text -in node.crt | sed -n '5p' |  sed 's/://g' | tr "\n" " " | sed 's/ //g' | sed 's/[a-z]/\u&/g' | cat >node.serial
    else
        openssl x509  -text -in node.crt | sed -n '4p' | sed 's/ //g' | sed 's/.*(0x//g' | sed 's/)//g' |sed 's/[a-z]/\u&/g' | cat >node.serial
    fi

    nodeid=`cat node.nodeid | head`
    serial=`cat node.serial | head`
    
    cat>node.json <<EOF
 {
 "id":"$nodeid",
 "name":"$node",
 "agency":"$agency",
 "caHash":"$serial"
}
EOF

	cat>node.ca <<EOF
	{
	"serial":"$serial",
	"pubkey":"$nodeid",
	"name":"$node"
	}
EOF

else
    echo "$rootsrc/$agency/$node/node.crt is not exist."
fi
