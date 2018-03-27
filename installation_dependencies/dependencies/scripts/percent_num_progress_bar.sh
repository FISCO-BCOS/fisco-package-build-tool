#!/bin/bash

spin() {
    sp='/-\|'
    printf ' '
    while true; do
        printf '\b%.1s' "$sp"
        sp=${sp#?}${sp%???}
        sleep 0.05
    done
}

progressbar()
{
    bar="##################################################"
    barlength=${#bar}
    n=$(($1*barlength/100))
    printf "\r[%-${barlength}s (%d%%)] " "${bar:0:n}" "$1" 
}

#spin &
#pid=$!

#your task here

total_sec=$1
interval=$(bc <<< "scale=2; $total_sec/100")

for i in `seq 1 100`;
do
    progressbar $i
    sleep $interval
done
# kill the spinner task
#kill $pid > /dev/null 2>&1
echo
