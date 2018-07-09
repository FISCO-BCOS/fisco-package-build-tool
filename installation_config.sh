#!/bin/bash

#github path for FISCO BCOS
FISCO_BCOS_GIT="https://github.com/FISCO-BCOS/FISCO-BCOS.git"
#local FISCO BCOS path, if FICSO BSOC is not exist in the path, pull it from the github.
FISCO_BCOS_LOCAL_PATH="../"

# default config for temp block node, if the port already exist, please change the following config.
P2P_PORT_FOR_TEMP_NODE=30303
RPC_PORT_FOR_TEMP_NODE=8545
CHANNEL_PORT_FOR_TEMP_NODE=8821

##config for docker generation
#if build docker install
IS_BUILD_FOR_DOCKER=0
#fisco-bcos docker repository, default "docker.io/fiscoorg/fiscobcos"
DOCKER_REPOSITORY="docker.io/fiscoorg/fiscobcos"
#fisco-bcos docker version, default "latest"
DOCKER_VERSION="docker-beta-v1.0.0703"

# config for ca
IS_CA_EXT_MODE=0

# config for the blockchain node
# the first node is the genesis node
# field 0 : p2pnetworkip
# field 1 : listennetworkip
# field 2 : node number on this host
# filed 3 : agency info
weth_host_0=("127.0.0.1" "127.0.0.1" "3" "agent_0")

MAIN_ARRAY=(
weth_host_0[@]
)
