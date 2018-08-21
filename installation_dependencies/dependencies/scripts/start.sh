#!/bin/bash

# bash start.sh      =>    start all node 
# bash start.sh IDX  =>    start the IDX node

index=$1;

if [ -z $index ];then
    total=999
    index=0
    echo "start all node ... "
    while [ $index -le $total ]
    do
        if [ -d node$index ];then
            bash node$index/start.sh
        else	
            break
        fi
	sleep 3
        index=$(($index+1))
    done

    sleep 3

    bash check.sh
else
    #echo "start node$index ... "
    if [ -d node$index ];then
        bash node$index/start.sh
        sleep 3
        bash check.sh $index
    else
        echo "node$index is not exist."
    fi
fi
