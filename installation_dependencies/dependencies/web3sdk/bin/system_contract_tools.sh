#!/bin/bash

#system contract command
COMMAND_DDEPOY_SYSTEM_CONTACT='DeploySystemContract'
COMMAND_SYSTEM_PROXY='SystemProxy'
COMMAND_AUTH_FILTER='AuthorityFilter'
COMMAND_NODE_ACTION='NodeAction'
COMMAND_CA_ACTION='CAAction'
COMMAND_CONFIG_ACTION='ConfigAction'

#NodeAction Sub Command
COMMAND_NODE_ACTION_SHOW_ALL_NODE='all'
COMMAND_NODE_ACTION_REGISTER_NODE='registerNode'
COMMAND_NODE_ACTION_DELETE_NODE='cancelNode'

#CAAction Sub Command
COMMAND_CA_ACTION_ALL='all'
COMMAND_CA_ACTION_UPDATE='update'
COMMAND_CA_ACTION_UPDATE_STATUS='updateStatus'

#ConfigAction Sub Command
COMMAND_CONFIG_ACTION_GET='get'
COMMAND_CONFIG_ACTION_SET='set'

#usage 
function Usage()
{
	echo "Usage: $0 {$COMMAND_DDEPOY_SYSTEM_CONTACT}"
	echo "Usage: $0 {$COMMAND_SYSTEM_PROXY}"
	echo "Usage: $0 {$COMMAND_AUTH_FILTER}"
	echo "Usage: $0 {$COMMAND_NODE_ACTION} {$COMMAND_NODE_ACTION_SHOW_ALL_NODE|$COMMAND_NODE_ACTION_REGISTER_NODE|$COMMAND_NODE_ACTION_DELETE_NODE}"
	echo "Usage: $0 {$COMMAND_CA_ACTION} {$COMMAND_CA_ACTION_SHOW_ALL|$COMMAND_CA_ACTION_UPDATE|$COMMAND_CA_ACTION_UPDATE_STATUS}"
	echo "Usage: $0 {$COMMAND_CONFIG_ACTION} {$COMMAND_CONFIG_ACTION_GET|$COMMAND_CONFIG_ACTION_SET}"
	exit 1
}

#params count check
if [ $# -lt 1 ];then
	Usage
fi

case "$1" in
	#deploy system contract
	$COMMAND_DDEPOY_SYSTEM_CONTACT)
        java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.InitSystemContract
        ;;
		#print system contract proxy info
    $COMMAND_SYSTEM_PROXY)
        java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $COMMAND_SYSTEM_PROXY
        ;;
    $COMMAND_AUTH_FILTER)
        java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $COMMAND_AUTH_FILTER 
        ;;
	#node manager
    $COMMAND_NODE_ACTION)
		case "$2" in
			$COMMAND_NODE_ACTION_SHOW_ALL_NODE)
				if [ $# -lt 2 ];then
					Usage
				fi
				java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $1 $2
				;;
			$COMMAND_NODE_ACTION_REGISTER_NODE)
				if [ $# -lt 3 ];then
					Usage
				fi
				java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $1 $2 $3
				;;
			$COMMAND_NODE_ACTION_DELETE_NODE)
				if [ $# -lt 3 ];then
					Usage
				fi
				java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $1 $2 $3
				;;
			*)
				Usage
				esac
        ;;
		#ca manager
		$COMMAND_CA_ACTION)
		case "$2" in
			$COMMAND_CA_ACTION_ALL)
				if [ $# -lt 2 ];then
					Usage
				fi
				java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $1 $2
				;;
			$COMMAND_CA_ACTION_UPDATE)
				if [ $# -lt 3 ];then
					Usage
				fi
				java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $1 $2 $3
				;;
			$COMMAND_CA_ACTION_UPDATE_STATUS)
				if [ $# -lt 3 ];then
					Usage
				fi
				java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $1 $2 $3
				;;
			*)
				Usage
				esac
        ;;
		#ca manager
		$COMMAND_CONFIG_ACTION)
		case "$2" in
			$COMMAND_CONFIG_ACTION_GET)
				if [ $# -lt 3 ];then
					Usage
				fi
				java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $1 $2 $3
				;;
			$COMMAND_CONFIG_ACTION_SET)
				if [ $# -lt 3 ];then
					Usage
				fi
				java -cp '../conf/:../apps/*:../lib/*' org.bcos.contract.tools.SystemContractTools $1 $2 $3
				;;
			*)
				Usage
				esac
        ;;
    *)
        Usage
esac