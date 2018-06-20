#!/bin/bash

#github path for FISCO BCOS
FISCO_BCOS_GIT="https://github.com/FISCO-BCOS/FISCO-BCOS.git"
#local FISCO BCOS path, if FICSO BSOC is not exist in the path, pull it from the github.
FISCO_BCOS_LOCAL_PATH="../"

# default config for temp block node, if the port already exist, please change the following config.
P2P_PORT_FOR_TEMP_NODE=30303
RPC_PORT_FOR_TEMP_NODE=8545
CHANNEL_PORT_FOR_TEMP_NODE=8821

# config for the blockchain node
# the first node is the genesis node
# field 0 : p2pnetworkip
# field 1 : listennetworkip
# field 2 : node number on this host
# field 3 : identity type
# field 4 : crypto mode
# field 5 : super key
# filed 6 : agency info
weth_host_0=("127.0.0.1" "127.0.0.1" "1" "1" "1" "d4f2ba36f0434c0a8c1d01b9df1c2bce" "agent_0")

MAIN_ARRAY=(
weth_host_0[@]
)
