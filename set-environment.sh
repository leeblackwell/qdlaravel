#!/bin/bash 

MYABSDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ -f ${MYABSDIR}/.env ]; then
    echo "${MYABSDIR}/.env already exists - won't clobber... aborting."
    exit 1
else
    echo QDLARAVELENVSET=1 > ${MYABSDIR}/.env
    echo "HOSTUID=$(id -u)" >> ${MYABSDIR}/.env
    echo "HOSTGID=$(id -g)" >> ${MYABSDIR}/.env
fi 
