#!/bin/bash

COMMAND_SHOW_ALL_NODE='all'
COMMAND_REGISTER_NODE='registerNode'
COMMAND_DELETE_NODE='cancelNode'

dirpath="$(cd "$(dirname "$0")" && pwd)"
source $dirpath/../dependencies/scripts/dependencies_check.sh
cd $dirpath/web3sdk/bin

java_version_check

chmod a+x system_contract_tools.sh

function redirect_request_to() 
{
    command_name=$1
    node_action_info_path=$2
    if ! [ -f $node_action_info_path ]
    then
        echo "$node_action_info_path is not a file"
    else
        ./system_contract_tools.sh NodeAction $command_name file:$node_action_info_path
    fi

    return 0
}

case "$1" in
    $COMMAND_SHOW_ALL_NODE)
        ./system_contract_tools.sh NodeAction all
        ;;
    $COMMAND_REGISTER_NODE)
        redirect_request_to $1 $2
        ;;
    $COMMAND_DELETE_NODE)
        redirect_request_to $1 $2
        ;;
    *)
        echo "Usage: $0 NodeAction {$COMMAND_SHOW_ALL_NODE|$COMMAND_REGISTER_NODE|$COMMAND_DELETE_NODE}"
        #exit 1
esac
