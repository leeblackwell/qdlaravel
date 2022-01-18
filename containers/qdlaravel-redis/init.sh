#!/bin/bash

source /root/bash-functions.sh
envcheck


evalcommand "/etc/init.d/redis-server start" 1

#Loop until something dies or is killed 
LOOPIT=1
while [ ${LOOPIT} -eq 1 ]
do
    sleep 30
    /etc/init.d/redis-server status 2>&1  > /dev/null
    RES=$? ; if [ "${RES}" -ne 0 ]; then LOOPIT=0 ; fi
done
