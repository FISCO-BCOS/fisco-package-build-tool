#!/bin/bash

# bash stop.sh      =>    stop all node 
# bash stop.sh IDX  =>    stop the IDX node

dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath

index=$1;
if [ -z $index ];then
    echo "stop all node ... "
    for stopfile in `ls $dirpath/node*/stop.sh`
    do
        bash $stopfile
    done
else
    # echo "stop all node ... "
	if [ -d node$index ];then
		bash node$index/stop.sh
	else
		echo "node$index is not exist."
	fi
fi