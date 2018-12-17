#!/bin/bash
dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath

# debug
# 
alarm() {
        alert_ip=`/sbin/ifconfig eth0 | grep inet | awk '{print $2}'`
        time=`date "+%Y-%m-%d %H:%M:%S"`
		echo " [$alert_ip] [$time] $1"
}

restart() {
        stopfile=${1/start/stop}
        $stopfile
        sleep 5
        $startfile
}

# info
info() {
        time=`date "+%Y-%m-%d %H:%M:%S"`
        echo "[$time] $1"
}



#check if $1 is install
function check_if_install()
{
    type $1 >/dev/null 2>&1
    if [ $? -ne 0 ];then
        alarm "ERROR: $1 is not installed."
        exit 1
    fi
}

# OracleJDK 1.8 + or OpenJDK 1.9 +
function java_check()
{
    check_if_install java

    #JAVA version
    JAVA_VER=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | awk -F . '{print $1$2}')
    if  java -version 2>&1 | egrep TM >/dev/null 2>&1; then
    #openjdk
        if [[ ${JAVA_VER} -lt 18 ]];then
            alarm " OracleJDK need 1.8 or above, now OracleJDK is - ${JAVA_VER}. "
            exit 1
        fi
    else
        alarm " OracleJDK 1.8 or above need, now JDK is - ${JAVA_VER}. "
        exit 1
    fi 
}

# check java env first
java_check

# get total consensus count of this chain
function get_total_consensus_node_count()
{
        java_check
        node_length=$(bash $dirpath/node_manager.sh all 2> /dev/null | egrep NodeIdsLength | awk -F= '{ print $2 }' | sed 's/^[ \t]*//g')
        echo "$node_length"
}

# get my node index
function get_my_nodeidx()
{
        java_check
        node_index=$(bash $dirpath/node_manager.sh all  2> /dev/null| egrep -B 1 `cat $1/data/node.nodeid` | egrep -o "node [0-9]+" | awk '{ print $2 }')
        echo "$node_index"
}

# check if nodeX is work well
function check_node_work_properly()
{
        # node dir
        nodedir=$1
        # should restart the node when it not work properly
        restart="$2"
        # 
        suffix="$3"
        # start shell
        startfile=$1/start.sh
        # stop shell
        stopfile=$1/stop.sh
        # config.json for this node
        configjson=$1/config.json

        config_ip=$(cat $configjson | grep 'listenip' | awk -F: '{ print $2 }' | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+")
        config_port=$(cat $configjson |grep 'rpcport' | awk -F: '{ print $2 }' | grep -o "[0-9]\+")
        
        # check if process id exist
        fisco_pwd=$(ps aux | grep  "$configjson" |grep "fisco-bcos"|grep -v "grep"|awk -F " " '{print $15}')
        [ -z "$fisco_pwd" ] &&  {
                [ "$restart" == "true" ] && {
                        alarm " ERROR! $config_ip:$config_port does not exist"
                        restart $startfile
                        return 1
                }
                info " ERROR! $config_ip:$config_port does not exist"
                return 1
        }

        # get blocknumber
        heightresult=$(curl -s  "http://$config_ip:$config_port" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":67}')
        echo $heightresult
        height=$(echo $heightresult|awk -F'"' '{if($2=="id" && $4=="jsonrpc" && $8=="result") {print $10}}')
        [[ -z "$height" ]] && {
                [ "$restart" == "true" ]  && {
                        alarm " ERROR! Cannot connect to $config_ip:$config_port $heightresult"
                        restart $startfile
                        return 1
                }
                info " ERROR! Cannot connect to $config_ip:$config_port $heightresult"
                return 1
        }

        node=$(basename $nodedir)
        height_file="$nodedir/$node$suffix.height"
        prev_height=0
        [ -f $height_file ] && prev_height=$(cat $height_file)
        heightvalue=$(printf "%d\n" "$height")
        prev_heightvalue=$(printf "%d\n" "$prev_height")

        # get pbft view
        viewresult=$(curl -s  "http://$config_ip:$config_port" -X POST --data '{"jsonrpc":"2.0","method":"eth_pbftView","params":[],"id":68}')
        echo $viewresult
        view=$(echo $viewresult|awk -F'"' '{if($2=="id" && $4=="jsonrpc" && $8=="result") {print $10}}')
        [[ -z "$view" ]] && {
                [ "$restart" == "true" ] &&  {
                        alarm " ERROR! Cannot connect to $config_ip:$config_port $viewresult"
                        restart $startfile
                        return 1
                }
                info " ERROR! Cannot connect to $config_ip:$config_port $viewresult"
                return 1
        }

        view_file="$nodedir/$node$suffix.view"
        prev_view=0
        [ -f $view_file ] && prev_view=$(cat $view_file)
        viewvalue=$(printf "%d\n" "$view")
        prev_viewvalue=$(printf "%d\n" "$prev_view")

        # check if blocknumber of pbft view already change, if all of them is the same with before, the node may not work well.
        [  $heightvalue -eq  $prev_heightvalue ] && [ $viewvalue -eq  $prev_viewvalue ] && {
                [ "$restart" == "true" ] && {
                        alarm " ERROR! $config_ip:$config_port is not working properly: height $height and view $view no change"
                        return 1
                }
                # [ "$restart" == "true" ] &&  restart $startfile
                info " ERROR! $config_ip:$config_port is not working properly: height $height and view $view no change"
                return 1
        }

        echo $height > $height_file
        echo $view > $view_file
        info " OK! $config_ip:$config_port is working properly: height $height view $view"

        return 0
}

# check all node of this server, if all node work well.
function check_all_node_work_properly()
{
        for configfile in `ls $dirpath/node*/config.json`
        do
                nodedir=$(dirname $configfile)
                check_node_work_properly $nodedir "true"
                if [[ $? == 0 ]];then
                        time_point=$(($(date +%s) - 60))
                        do_log_analyze_by_time_point $nodedir $time_point
                fi
        done
}

function get_err_type()
{
        ret=""
        case $1 in
        "0")ret="[NETWORK]]";;
        "1")ret="[getLeader<X,X>]";;
        "2")ret="[ChangeViewWarning]";;
        "3")ret="[Closing]";;
        "4")ret="[tq.num > 512]";;
        "5")ret="[block exec too slow]";;
        "6")ret="[commit too slow]";;
        *) ret="[UNKNOWN]";;
        esac

        echo "$ret"
}

# diff time, 2018-12-12 16:00:20:512, 2018-12-12 16:00:20:512
function diff_time()
{
        start=$1
        end=$2
        # get start time in ms
        eval $(echo ${start} |awk '{ match($0,/([0-9]{4})-([0-9]{1,2})-([0-9]{1,2}) ([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,3})/,t); print "year_s="t[1]; print "month_s="t[2]; print "day_s="t[3]; print "hour_s="t[4]; print "min_s="t[5]; print "sec_s="t[6]; print "ms_s="t[7];}') 
        start=$(date -d "$year_s-$month_s-$day_s $hour_s:$min_s:$sec_s" +%s)
        ((start=start*1000 + 10#${ms_s}))

        # get end time in ms
        eval $(echo ${end} |awk '{ match($0,/([0-9]{4})-([0-9]{1,2})-([0-9]{1,2}) ([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,3})/,t); print "year_e="t[1]; print "month_e="t[2]; print "day_e="t[3]; print "hour_e="t[4]; print "min_e="t[5]; print "sec_e="t[6]; print "ms_e="t[7];}') 
        end=$(date -d "$year_e-$month_e-$day_e $hour_e:$min_e:$sec_e" +%s)
        ((end=end*1000 + 10#${ms_e}))

        echo $((end - start))
}

# Analysis of Result
function do_log_analyze_statistics_result()
{
        node_count=$(get_total_consensus_node_count)
        if [[ -z "$node_count" || $node_count -eq 0 ]];then
                alarm $(basename $1)" get consensus count of this chain failed, maybe web3sdk not work well."
                exit 1
        fi

        total_blk=0
        for i in "${!report[@]}"
        do
                ((total_blk +=${report[$i]}))
        done

        # 
        AVG_SEAL_COUNT=5
        ((exp_total=node_count*AVG_SEAL_COUNT))
        # info "total_blk is $total_blk, exp_total is $exp_total, node_count is $node_count, AVG_SEAL_COUNT is ${AVG_SEAL_COUNT}."

        if [[ $total_blk -ge ${exp_total} ]];then
                avg=$(($total_blk/$node_count))
                err_msg=""
                for ((i=0;i<node_count;++i))
                do
                        count=${report[$i]}
                        if [[ -z $count ]];then
                                count=0
                        fi

                        if [[ $count -le $avg/2 ]];then
                                err_msg=$err_msg" |node$i, seal blk count is $count"
                        fi 
                done

                if [[ ! -z "$err_msg" ]];then
                        alarm " [$1]-[$2] # total sealed blk count is $total_blk, node count is ${node_count}, ${err_msg}"
                fi
        fi
}

# dispose log error
function dispose_log_error_result()
{
        err_msg=""
        index=0
        for i in "${!err[@]}"
        do
                err_msg=$err_msg" | $index、error"$(get_err_type $i)", count=${err[$i]} "
                ((index+=1))
        done

        if [[ ! -z "$err_msg" ]];then
                info " [$1] dispose_log_error_result =>  "
                alarm "${err_msg}"
        else 
                info " [$1] dispose_log_error_result empty."
        fi  
}

# show log analyze result.
function show_log_analyze_result()
{
        info "  ## log analyze result => "
        #blk and transaction count
        echo "  ==> blk count is $blk_count"
        echo "  ==> transaction count is ${transaction_count}"
        #if [[ $blk_count -eq 0 ]];then
        #        echo "          ==> tps is 0."
        #else
        #        echo "          ==> tps is "$(awk -v transaction_count=$transaction_count -v blk_count=$blk_count 'BEGIN{printf "%.2f",transaction_count/blk_count}')
        #fi

        # err message result
        echo "  ==>> error message"
        for i in "${!err[@]}"
        do
                echo "          error"$(get_err_type $i)", count=${err[$i]}"
        done

        # view, pre-pare, sign, commit message
        echo "  ==>> total view message"
        for i in "${!view_total[@]}"
        do
                echo "          from=$i, count=${view_total[$i]}"
        done

        echo "  ==>> direct view message"
        for i in "${!view_d[@]}"
        do
                echo "          from=$i, count=${view_d[$i]}"
        done

        echo "  ==>> forward view message"
        for i in "${!view_f[@]}"
        do
                echo "          from=$i, count=${view_f[$i]}"
        done

        echo "  ==>> total pre message"
        for i in "${!pre_total[@]}"
        do
                echo "          from=$i, count=${pre_total[$i]}"
        done

        echo "  ==>> direct pre message"
        for i in "${!pre_d[@]}"
        do
                echo "          from=$i, count=${pre_d[$i]}"
        done

        echo "  ==>> forward pre message"
        for i in "${!pre_f[@]}"
        do
                echo "          from=$i, count=${pre_f[$i]}"
        done

        echo "  ==>> total sign message"
        for i in "${!sign_total[@]}"
        do
                echo "          from=$i, count=${sign_total[$i]}"
        done

        echo "  ==>> direct sign message"
        for i in "${!sign_d[@]}"
        do
                echo "          from=$i, count=${sign_d[$i]}"
        done

        echo "  ==>> forward sign message"
        for i in "${!sign_f[@]}"
        do
                echo "          from=$i, count=${sign_f[$i]}"
        done

        echo "  ==>> total commit message"
        for i in "${!commit_total[@]}"
        do
                echo "          from=$i, count=${commit_total[$i]}"
        done

        echo "  ==>> direct commit message"
        for i in "${!commit_d[@]}"
        do
                echo "          from=$i, count=${commit_d[$i]}"
        done

        echo "  ==>> forward commit message"
        for i in "${!commit_f[@]}"
        do
                echo "          from=$i, count=${commit_f[$i]}"
        done

        echo "  ==>> report message"
        for i in "${!report[@]}"
        do
                echo "          report, index=$i, count=${report[$i]}"
        done

        # pbft time
test() { # as multi-line comments
        echo " ==>> pbft prepare phase time point, count is ${#pbft_pre[*]}"
        for i in "${!pbft_pre[@]}"
        do
                echo "                  blk=$i, time point=${pbft_pre[$i]}"
        done

        echo " ==>> pbft sign phase time point, count is ${#pbft_sign[*]}"
        for i in "${!pbft_sign[@]}"
        do
                echo "                  blk=$i, time point=${pbft_sign[$i]}"
        done

        echo " ==>> pbft commit phase time point, count is ${#pbft_commit[*]}"
        for i in "${!pbft_commit[@]}"
        do
                echo "                  blk=$i, time point=${pbft_commit[$i]}"
        done

        echo " ==>> pbft write block phase time point, count is ${#pbft_write[*]}"
        for i in "${!pbft_write[@]}"
        do
                echo "                  blk=$i, time point=${pbft_write[$i]}"
        done
}

        echo "  ==>> pbft and seal time"
        blk_count=0
        pbft_min_time=0 # pbft min time (ms)
        pbft_max_time=0 # pbft max time (ms)
        pbft_avg_time=0 # pbft avg time (ms)
        seal_min_time=0 # seal min time (ms)
        seal_max_time=0 # seal max time (ms)
        seal_avg_time=0 # seal avg time (ms)
        total_pbft_time=0
        total_seal_time=0

        for i in "${!pbft_write[@]}"
        do
                # pbft prepare message not found, maybe another log file
                if [[ -z ${pbft_pre[$i]}  ]];then
                        continue
                fi

                # # pbft prepare message not found, maybe another log file
                if [[ -z ${pbft_commit[$i]}  ]];then
                        continue
                fi

                ((blk_count+=1))
                pbft_time=$(diff_time "${pbft_pre[$i]}" "${pbft_commit[$i]}")
                seal_time=$(diff_time "${pbft_pre[$i]}" "${pbft_write[$i]}")
                ((total_pbft_time+=pbft_time))
                ((total_seal_time+=seal_time))

                if [[ $pbft_min_time -eq 0 ]];then
                        pbft_min_time=$pbft_time
                fi

                if [[ $pbft_max_time -eq 0 ]];then
                        pbft_max_time=$pbft_time
                fi

                if [[ $seal_min_time -eq 0 ]];then
                        seal_min_time=$pbft_time
                fi

                if [[ $seal_max_time -eq 0 ]];then
                        seal_max_time=$pbft_time
                fi

                if [[ $pbft_time -gt $pbft_max_time ]];then
                        pbft_max_time=$pbft_time
                fi

                if [[ $pbft_time -lt $pbft_min_time ]];then
                        pbft_min_time=$pbft_time
                fi

                if [[ $seal_time -gt $seal_max_time ]];then
                        seal_max_time=$seal_time
                fi

                if [[ $seal_time -lt $seal_min_time ]];then
                        seal_min_time=$seal_time
                fi

                #echo "          blk is $i, pbft_time is ${pbft_time}, seal_time is ${seal_time}"
        done

        # echo "          # blk_count is ${blk_count}, pbft_max_time is ${pbft_max_time}(ms), pbft_min_time is ${pbft_min_time}(ms), seal_max_time is ${seal_max_time}(ms), seal_min_time is ${seal_min_time}(ms)"
        echo "          # blk_count is ${blk_count}"
        echo "          # pbft_max_time is ${pbft_max_time}(ms), pbft_min_time is ${pbft_min_time}(ms)"
        echo "          # seal_max_time is ${seal_max_time}(ms), seal_min_time is ${seal_min_time}(ms)"
        echo "          # pbft prepare count is ${#pbft_pre[*]}"
        echo "          # pbft sign count is ${#pbft_sign[*]}"
        echo "          # pbft commit count is ${#pbft_commit[*]}"
        echo "          # pbft write block count is ${#pbft_write[*]}"
        if [[ ${blk_count} -gt 0 ]];then
                echo "          # pbft_avg_time is "$(($total_pbft_time/$blk_count))"(ms)"
                echo "          # seal_avg_time is "$(($total_seal_time/$blk_count))"(ms)"
        else
                echo "          # pbft_avg_time is 0(ms)"
                echo "          # seal_avg_time is 0(ms)"
        fi
}

# analyze log file of which content recorded start_time and end_time.
function do_log_analyze_by_duration_time()
{
        nodedir=$1
        start_time=$2
        end_time=$3
        info "start_time is $start_time #$(date -d @$start_time +"%Y-%m-%d %H:%M:%S")"
        info "end_time is $end_time #$(date -d @$end_time +"%Y-%m-%d %H:%M:%S")"

        # date -d @1361542596 +"%Y-%m-%d %H:%M:%S"
        start_log="log_"$(date -d @${start_time} +"%Y%m%d%H")".log"
        end_log="log_"$(date -d @${end_time} +"%Y%m%d%H")".log"

        start_min=$(date -d @${start_time} +"%Y-%m-%d %H:%M")
        end_min=$(date -d @${end_time} +"%Y-%m-%d %H:%M")

        if [[ $start_log == $end_log ]];then
        # start time and end time is the same log file.
                eval $(sed -n "/$start_min/,/$end_min/p" $nodedir/log/$start_log | awk -f monitor.awk)
        else 
        # start time and end time is different log file, now the max duration is 60 min, so start time and end time is most in two file.
                eval $(ls $nodedir/log/$start_log $nodedir/log/$end_log 2>/dev/null | xargs sed -n "/$start_min/,/$end_min/p" | awk -f monitor.awk)
        fi

        if [[ $? -eq 0 ]];then
                show_log_analyze_result ${start_min} ${end_min}
                do_log_analyze_statistics_result ${start_min} ${end_min}
        fi
}

# analyze log file of which content recorded during time_point min.
function do_log_analyze_by_time_point()
{
        nodedir=$1
        time_point=$2
       
        # date -d @1361542596 +"%Y-%m-%d %H:%M:%S"
        log_file="log_"$(date -d @${time_point} +"%Y%m%d%H")".log"

        min_time=$(date -d @${time_point} +"%Y-%m-%d %H:%M")

        info " #log parser, $(date -d @$time_point +"%Y-%m-%d %H:%M:%S")"

        eval $(sed -n "/$min_time/p" $nodedir/log/$log_file 2>/dev/null | awk -f monitor.awk)
        
        if [[ $? -eq 0 ]];then
                dispose_log_error_result "$min_time"
        fi
}

# analyze log file.
function do_log_analyze_by_file()
{
        file=$1
        [ ! -f $file ] && {
                echo " $file is not exist. "
                exit 1
        }

        eval $(awk -f monitor.awk $file)

        if [[ $? -eq 0 ]];then
                show_log_analyze_result
        fi
}

# 
function do_all_log_analyze()
{
        for configfile in `ls $dirpath/node*/config.json`
        do
                nodedir=$(dirname $configfile)
                # check if node work well first, then do log analyze.
                if check_node_work_properly $nodedir "false" "_suffix";then
                        do_log_analyze_by_duration_time $nodedir $start_time $end_time
                fi
        done
}

mode="monitor"
log_file=""
duration=10
# default end_time when log analyze
end_time=$(($(date +%s) - 60))
# default start_time when log analyze
start_time=$(($end_time-duration*60))

# help
function help()
{
        echo "Usage : bash monitor.sh "
        echo "          -m : monitor, statistics.  default : monitor ."
        echo "          -f : log file to be analyzed. "
        echo "          -d : log analyze time range. default : 10(min), it should not bigger than 60(min)."
        echo "          -h : help. "
        echo "          example : "
        echo "                   bash  monitor.sh"
        echo "                   bash  monitor.sh -m statistics"
        echo "                   bash  monitor.sh -m statistics -f node0/log/log_2018120514.log "
        exit 0
}

while getopts "m:f:d:h" option;do
    case $option in
    m) mode=$OPTARG;;
    f) log_file=$OPTARG;;
    d)
        if [[ $OPTARG -gt 0 && $OPTARG -le 60 ]];then
                duration=$OPTARG
                start_time=$(($end_time-duration*60))
        fi
        ;;
    h) help;;
    esac
done

case $mode in
 monitor)
        check_all_node_work_properly
        ;;
 statistics)
        if [[ -z $log_file ]];then
                do_all_log_analyze  
        else
                do_log_analyze_by_file $log_file
        fi
        ;;
 *)
        help
        ;;
esac