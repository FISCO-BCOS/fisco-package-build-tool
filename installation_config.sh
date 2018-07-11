#!/bin/bash

#github path for FISCO BCOS
FISCO_BCOS_GIT="https://github.com/FISCO-BCOS/FISCO-BCOS.git"
#local FISCO BCOS path, if FICSO BSOC is not exist in the path, pull it from the github.
FISCO_BCOS_LOCAL_PATH="../"

# default config for temp block node, if the port already exist, please change the following config.
P2P_PORT_FOR_TEMP_NODE=30313
RPC_PORT_FOR_TEMP_NODE=8555
CHANNEL_PORT_FOR_TEMP_NODE=8831

##config for docker generation
#if build docker install
IS_BUILD_FOR_DOCKER=0
#fisco-bcos docker repository, default "docker.io/fiscoorg/fiscobcos"
DOCKER_REPOSITORY="fiscoorg/fisco-octo"
#fisco-bcos docker version, default "latest"
DOCKER_VERSION="v1.3.1"

# config for ca
IS_CA_EXT_MODE=0

# config for the blockchain node
# the first node is the genesis node
# field 0 : p2pnetworkip
# field 1 : listennetworkip
# field 2 : node number on this host
# filed 3 : agency info
weth_host_0=("127.0.0.1" "0.0.0.0" "5" "agent_0")

MAIN_ARRAY=(
weth_host_0[@]
)
