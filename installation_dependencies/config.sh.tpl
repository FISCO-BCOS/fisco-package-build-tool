#!/bin/bash

#node num
nodecount=${NODE_NUM_TPL}

#admin user address
god="${GOD_ADDRESS_TPL}"

sealEngine="PBFT"
networkid="12345"
crypto_mode=${CRYPTO_MODE_TPL}

#node config
listenip=(${LISTEN_IP_TPL})
rpcport=($RPC_PORT_TPL)
p2pport=($P2P_PORT_TPL)
channelPort=(${CHANNEL_PORT_VALUE_TPL})
Nodedesc=($NODE_DESC_TPL)
Agencyinfo=($AGENCY_INFO_TPL)
Identitytype=($IDENTITY_TYPE_TPL)
Idx=($IDX_TPL)

