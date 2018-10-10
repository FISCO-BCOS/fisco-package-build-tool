#!/bin/bash

# bash stop.sh      =>    stop all node 
# bash stop.sh IDX  =>    stop the IDX node

dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath

index=$1;

if [ -z $index ];then
    total=999
    index=0
    echo "stop all node ... "
    while [ $index -le $total ]
    do
    if [ -d node$index ];then
        bash node$index/stop.sh
    else	
        break
    fi
    index=$(($index+1))
    done
else
    # echo "stop all node ... "
	if [ -d node$index ];then
		bash node$index/stop.sh
	else
		echo "node$index is not exist."
	fi
fi