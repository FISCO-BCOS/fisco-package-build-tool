#!/bin/bash

alarm() {
        alert_ip=`/sbin/ifconfig eth0 | grep inet | awk '{print $2}'`
        time=`date "+%Y-%m-%d %H:%M:%S"`
        echo "$alert_ip $1"
}

restart() {
        stopfile=${1/start/stop}
        $stopfile
        sleep 3
        $startfile
}

dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath
(
for configfile in `ls $dirpath/node*/config.json`
do
        startfile=$(dirname $configfile)/start.sh
        config_ip=$(cat $configfile |grep -o '"listenip":".*"' | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+")
        config_port=$(cat $configfile |grep -o '"rpcport":".*"' | grep -o "[0-9]\+")
        configjs=$(ps aux | grep  "$configfile" |grep -v "grep"|awk -F " " '{print $15}')
        [ -z "$configjs" ] && {
        alarm "ERROR! $config_ip:$config_port does not exist"
                restart $startfile
        continue
    }


for((i=0;i<3;i++))
do 
                heightresult=$(curl -s  "http://$config_ip:$config_port" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":67}')
                echo $heightresult
                height=$(echo $heightresult|awk -F'"' '{if($2=="id" && $4=="jsonrpc" && $8=="result") {print $10}}')
                [[ -z "$height" && $i -eq 2 ]] &&  {
                        alarm "ERROR! Cannot connect to $config_ip:$config_port $heightresult"
                        restart $startfile
                        break
                }
                configdir=$(dirname $configfile)
                height_file="$configdir.height"
                prev_height=0
                [ -f $height_file ] && prev_height=$(cat $height_file)
                heightvalue=$(printf "%d\n" "$height")
                prev_heightvalue=$(printf "%d\n" "$prev_height")

                viewresult=$(curl -s  "http://$config_ip:$config_port" -X POST --data '{"jsonrpc":"2.0","method":"eth_pbftView","params":[],"id":68}')
                echo $viewresult
                view=$(echo $viewresult|awk -F'"' '{if($2=="id" && $4=="jsonrpc" && $8=="result") {print $10}}')
                [[ -z "$view" && $i -eq 2 ]] &&  {
                        alarm "ERROR! Cannot connect to $config_ip:$config_port $viewresult"
                        restart $startfile
                        break
                }

                [[ -n "$height" && -n "$view" ]] && { 
                        break 
                }
                sleep 1
done

        view_file="$configdir.view"
        prev_view=0
        [ -f $view_file ] && prev_view=$(cat $view_file)
        viewvalue=$(printf "%d\n" "$view")
    prev_viewvalue=$(printf "%d\n" "$prev_view")

        [  $heightvalue -eq  $prev_heightvalue ] && [ $viewvalue -eq  $prev_viewvalue ] && {
                alarm "ERROR! $config_ip:$config_port is not working properly: height $height and view $view no change"
                restart $startfile
                continue
        }

        echo $height > $height_file
        echo $view > $view_file
        echo "OK! $config_ip:$config_port is working properly: height $height view $view" 
done) | while read line; do
        echo [$(date '+%F %T')]"$line"
done
#update version 1.0.2