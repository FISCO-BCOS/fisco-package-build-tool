#!/bin/bash

DEFAULT_NETWORK_ID="12345"
DEFAULT_SUPER_KEY="d4f2ba36f0434c0a8c1d01b9df1c2bce"
buildPWD=$installPWD/build
installation_build_dir=$installPWD/build
LOCAL_DIR=/usr/local
#NODE_MODULES_DIR=$LOCAL_DIR/lib/node_modules
NODE_MODULES_DIR=$buildPWD/nodejs/lib/node_modules
DEPENENCIES_DIR=$installPWD/dependencies
DEPENENCIES_LIB_DIR=$installPWD/dependencies/lib
DEPENENCIES_LIB64_DIR=$installPWD/dependencies/lib64
JTOOL_DIR=$installPWD/dependencies/jtool
NODEJS_DIR=$installPWD/dependencies/nodejs
DEPENDENCIES_RLP_DIR=$installPWD/dependencies/rlp_dir
BASE_INFO_DIR_NAME=followers_dependencies
FOLLOWER_DEPENENCIES_DIR=$buildPWD/$BASE_INFO_DIR_NAME
FOLLOWER_INSTALL_PACKAGE_NAME=follower_install_package
DEPENDENCIES_CONFIG_FILE_NAME=installation_config.sh
UNDER_LINE_STR="_"
TPL_DIR_PATH=$DEPENENCIES_DIR/tpl_dir
KEY_INFO_DIR_PATH=$DEPENENCIES_DIR/ca
KEYSTORE_FILE_DIR=$DEPENENCIES_DIR/keystore_files

TYPE_GENESIS_HOST=1
TYPE_FOLLOWER_HOST=2
TYPE_TEMP_HOST=3

PROCESS_INITIALIZATION=0
PROCESS_EXPAND_NODE=1
PROCESS_SPECIFIC_EXPAND_NODE=2

BUILD_ERROR_LOG="$installPWD/error.log"


