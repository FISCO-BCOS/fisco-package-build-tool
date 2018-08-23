#!/bin/bash

# bash check.sh      =>    check all node 
# bash check.sh IDX  =>    check the IDX node

index=$1;

if [ -z $index ];then
	total=999
	index=0
	echo "check all node status ... "
	while [ $index -le $total ]
	do
		if [ -d node$index ];then
			bash node$index/check.sh
		else	
			break
		fi
		index=$(($index+1))
	done
else
	echo "check node$index status ... "
	if [ -d node$index ];then
		bash node$index/check.sh
	else
		echo "node$index is not exist."
	fi
fi