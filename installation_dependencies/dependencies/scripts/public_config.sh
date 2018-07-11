#!/bin/bash

DEFAULT_NETWORK_ID="12345"
buildPWD=$installPWD/build
installation_build_dir=$installPWD/build

NODE_INSTALL_DIR=$buildPWD/node
WEB3SDK_INSTALL_DIR=$buildPWD/web3sdk
NODEJS_INSTALL_DIR=$buildPWD/nodejs

NODE_MODULES_DIR=$buildPWD/nodejs/lib/node_modules

DEPENENCIES_DIR=$installPWD/dependencies
DEPENENCIES_WEB3SDK_DIR=$installPWD/dependencies/web3sdk
DEPENENCIES_WEB3LIB_DIR=$installPWD/dependencies/web3lib
DEPENENCIES_FOLLOW_DIR=$installPWD/dependencies/follow
DEPENENCIES_FISCO_DIR=$installPWD/dependencies/fisco-bcos
DEPENENCIES_SC_DIR=$installPWD/dependencies/systemcontract
DEPENENCIES_TOOL_DIR=$installPWD/dependencies/tool
DEPENENCIES_NODEJS_DIR=$installPWD/dependencies/nodejs
DEPENDENCIES_RLP_DIR=$installPWD/dependencies/rlp_dir
DEPENDENCIES_TPL_DIR=$installPWD/dependencies/tpl_dir

TYPE_GENESIS_HOST=1
TYPE_FOLLOWER_HOST=2
TYPE_TEMP_HOST=3

PROCESS_INITIALIZATION=0
PROCESS_EXPAND_NODE=1
PROCESS_SPECIFIC_EXPAND_NODE=2
