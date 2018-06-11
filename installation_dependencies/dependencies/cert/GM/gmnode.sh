#!/bin/bash

function LOG_ERROR()
{
    local content=${1}
    echo -e "\033[31m"${content}"\033[0m"
}

function LOG_INFO()
{
    local content=${1}
    echo -e "\033[34m"${content}"\033[0m"
}

function execute_cmd()
{
    local command="${1}"
    eval ${command}
    local ret=$?
    if [ $ret -ne 0 ];then
        LOG_ERROR "execute command ${command} FAILED"
        exit 1
    else
        LOG_INFO "execute command ${command} SUCCESS"
    fi
}

CUR_DIR=`pwd`
TARGET_DIR="${HOME}/TASSL"
function need_install()
{
    if [ ! -f "${TARGET_DIR}/bin/openssl" ];then
	LOG_INFO "== TASSL HAS NOT BEEN INSTALLED, INSTALL NOW =="
	return 1
    fi
    LOG_INFO "== TASSL HAS BEEN INSTALLED, NO NEED TO INSTALL ==="
    return 0
}

function download_and_install()
{
    need_install
    local required=$?
    if [ $required -eq 1 ];then
        local url=${1}
        local pkg_name=${2}
        local install_cmd=${3}

        local PKG_PATH=${CUR_DIR}/${pkg_name}
        git clone ${url}/${pkg_name}
        execute_cmd "cd ${pkg_name}"
        local shell_list=`find . -name *.sh`
        execute_cmd "chmod a+x ${shell_list}"
        execute_cmd "chmod a+x ./util/pod2mantest"
        #cd ${PKG_PATH}
        execute_cmd "${install_cmd}"

        #execute_cmd "rm -rf ${PKG_PATH}"
        cd "${CUR_DIR}"
    fi
}


function install_deps_centos()
{
    execute_cmd "sudo yum -y install flex"
    execute_cmd "sudo yum -y install bison"
    execute_cmd "sudo yum -y install gcc"
    execute_cmd "sudo yum -y install gcc-c++"
}


function install_deps_ubuntu()
{
    execute_cmd "sudo apt-get install -y flex"
    execute_cmd "sudo apt-get install -y bison"
    execute_cmd "sudo apt-get install -y gcc"
    execute_cmd "sudo apt-get install -y g++"
}

###install pre-packages
if grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
    install_deps_ubuntu
else
    install_deps_centos
fi
##install tassl
tassl_name="TASSL"
tassl_url=" https://github.com/jntass"
tassl_install_cmd="bash config --prefix=${TARGET_DIR} no-shared && make -j2 && make install"
download_and_install "${tassl_url}" "${tassl_name}" "${tassl_install_cmd}"


OPENSSL_CMD=${TARGET_DIR}/bin/openssl
if [ "" = "`$OPENSSL_CMD ecparam -list_curves | grep SM2`" ];
then
    echo "Current Openssl Don't Support SM2 ! Please Upgrade tassl"
    exit;
fi


agency=$1
node=$2

if [ -z "$agency" ];  then
    echo "Usage:gmnode.sh agency_name node_name "
elif [ -z "$node" ];  then
    echo "Usage:gmnode.sh   agency_name node_name "
elif [ ! -d "$agency" ]; then
    echo "$agency DIR Don't exist! please Check DIR!"
elif [ ! -f "$agency/gmagency.key" ]; then
    echo "$agency/gmagency.key  Don't exist! please Check DIR!"
elif [  -d "$agency/$node" ]; then
    echo "$agency/$node DIR exist! please clean all old DIR!"
else
    mkdir -p $agency/$node
	echo "---------------------------生成国密签名证书---------------------------------------------"
    $OPENSSL_CMD genpkey -paramfile gmsm2.param -out gmnode.key
    $OPENSSL_CMD req -new -key gmnode.key -out gmnode.csr
	$OPENSSL_CMD x509 -req -CA $agency/gmagency.crt -CAkey $agency/gmagency.key -days 3650 -CAcreateserial -in gmnode.csr -out gmnode.crt -extfile cert.cnf -extensions v3_req
	echo "---------------------------生成国密加密证书---------------------------------------------"
	$OPENSSL_CMD genpkey -paramfile gmsm2.param -out gmennode.key
    $OPENSSL_CMD req -new -key gmennode.key -out gmennode.csr
	$OPENSSL_CMD x509 -req -CA $agency/gmagency.crt -CAkey $agency/gmagency.key -days 3650 -CAcreateserial -in gmennode.csr -out gmennode.crt -extfile cert.cnf -extensions v3enc_req
	
    $OPENSSL_CMD ec -in gmnode.key -outform DER |tail -c +8 | head -c 32 | xxd -p -c 32 | cat >gmnode.private
    $OPENSSL_CMD ec -in gmnode.key -text -noout | sed -n '7,11p' | sed 's/://g' | tr "\n" " " | sed 's/ //g' | awk '{print substr($0,3);}'  | cat >gmnode.nodeid

    if [ "" != "`$OPENSSL_CMD version | grep 1.0.2`" ];
    then
        $OPENSSL_CMD x509  -text -in gmnode.crt | sed -n '5p' |  sed 's/://g' | tr "\n" " " | sed 's/ //g' | sed 's/[a-z]/\u&/g' | cat >gmnode.serial
    else
        $OPENSSL_CMD x509  -text -in gmnode.crt | sed -n '4p' |  sed 's/ //g' | sed 's/.*(0x//g' | sed 's/)//g' |sed 's/[a-z]/\u&/g' | cat >gmnode.serial
    fi

    

    cp $agency/gmca.crt $agency/gmagency.crt $agency/$node
	rm -rf gmnode.csr gmennode.csr $agency/gmagency.srl
    mv gmnode.key gmnode.crt gmnode.private gmnode.nodeid gmnode.serial gmennode.key gmennode.crt $agency/$node
	
    cd $agency/$node
    

    nodeid=`cat gmnode.nodeid | head`
    serial=`cat gmnode.serial | head`
    
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
    echo "Build  $node Crt suc!!!"
fi