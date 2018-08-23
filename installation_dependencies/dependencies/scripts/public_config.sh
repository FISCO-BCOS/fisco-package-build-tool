#!/bin/bash

TARGET_FISCO_BCOS_PATH=/usr/local/bin/fisco-bcos

DEFAULT_SYSTEM_CONTRACT_ADDRESS="0x919868496524eedc26dbb81915fa1547a20f8998"

buildPWD=$installPWD/build
installation_build_dir=$installPWD/build

TEMP_NODE_NAME="temp"
TEMP_BUILD_DIR=$installation_build_dir/$TEMP_NODE_NAME/build

NODE_INSTALL_DIR=$buildPWD
WEB3SDK_INSTALL_DIR=$buildPWD/web3sdk
NODEJS_INSTALL_DIR=$buildPWD/nodejs

NODE_MODULES_DIR=$buildPWD/nodejs/lib/node_modules

DEPENENCIES_DIR=$installPWD/dependencies
DEPENENCIES_WEB3SDK_DIR=$installPWD/dependencies/web3sdk
DEPENENCIES_WEB3LIB_DIR=$installPWD/dependencies/web3lib
DEPENENCIES_FOLLOW_DIR=$installPWD/dependencies/follow
DEPENENCIES_SO_DIR=$installPWD/dependencies/so
DEPENENCIES_SCRIPTES_DIR=$installPWD/dependencies/scripts
DEPENENCIES_FISCO_DIR=$installPWD/dependencies/fisco-bcos
DEPENENCIES_SC_DIR=$installPWD/dependencies/systemcontract
DEPENENCIES_TOOL_DIR=$installPWD/dependencies/tool
DEPENENCIES_NODEJS_DIR=$installPWD/dependencies/nodejs
DEPENDENCIES_RLP_DIR=$installPWD/dependencies/rlp_dir
DEPENDENCIES_TPL_DIR=$installPWD/dependencies/tpl_dir

INSTALLATION_DEPENENCIES_LIB_DIR=$installPWD/installation_dependencies
INSTALLATION_DEPENENCIES_EXT_DIR=$installPWD/ext

TYPE_GENESIS_HOST=1
TYPE_FOLLOWER_HOST=2
TYPE_TEMP_HOST=3

PROCESS_INITIALIZATION=0
PROCESS_EXPAND_NODE=1
PROCESS_SPECIFIC_EXPAND_NODE=2
