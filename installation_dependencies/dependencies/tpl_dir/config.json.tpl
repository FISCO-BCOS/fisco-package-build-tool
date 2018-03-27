{
    "sealEngine":"PBFT",
    "systemproxyaddress":"${CONFIG_JSON_SYSTEM_CONTRACT_ADDRESS_TPL}",
    "listenip":"${CONFIG_JSON_LISTENIP_TPL}",
    "cryptomod":"${CRYPTO_MODE_TPL}",
    "ssl":"${CONFIG_SSL_TPL}",
    "rpcport":"${CONFIG_JSON_RPC_PORT_TPL}",
    "p2pport":"${CONFIG_JSON_P2P_PORT_TPL}",
    "rpcsslport":"${RPC_SSL_PORT_VALUE_TPL}",
    "channelPort":"${CHANNEL_PORT_VALUE_TPL}",
    "wallet":"${CONFIG_JSON_KEYS_INFO_FILE_PATH_TPL}",
    "keystoredir":"${CONFIG_JSON_KEYSTORE_DIR_PATH_TPL}",
    "datadir":"${CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL}",
    "networkid":"${CONFIG_JSON_NETWORK_ID_TPL}",
    "vm":"interpreter",
    "logverbosity":"4",
    "coverlog":"OFF",
    "eventlog":"ON",
    "statlog":"ON",
    "logconf":"${CONFIG_JSON_FISCO_DATA_DIR_PATH_TPL}/log.conf",
    "params": {
        "accountStartNonce": "0x00",
        "maximumExtraDataSize": "0x0400",
        "tieBreakingGas": false,
        "blockReward": "0x14D1120D7B160000",
        "networkID" : "0x0"
     },
    "NodeextraInfo":[
        ${CONFIG_JSON_GENESIS_NODE_INFO_TPL}
    {
        "Nodeid":"${CONFIG_JSON_PUBLIC_NODE_ID_TPL}",
        "Nodedesc": "${CONFIG_JSON_NODE_DESC_TPL}",
        "Agencyinfo": "${CONFIG_JSON_AGENCY_INFO_TPL}",
        "Peerip": "${CONFIG_JSON_PEER_IP_TPL}",
        "Identitytype": ${CONFIG_JSON_IDENTITY_TYPE_TPL},
        "Port":${CONFIG_JSON_PORT_TPL},
        "Idx":${CONFIG_JSON_IDX_TPL}
    }
    ]
}





