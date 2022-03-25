#!/bin/bash 

#Global
WWWDOMAIN="www.qdlaravel.local"
HTACCESS=0

#Dev Env
LOCALHTTPPORT=8080
LOCALHTTPSPORT=10443 
LOCALMYSQLPORT=33060
LOCALREDISPORT=6379

#Prod Env
#LOCALHTTPPORT=8080
#LOCALHTTPSPORT=10443 
#LOCALMYSQLPORT=33060
#LOCALREDISPORT=6379

MYABSDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ -f ${MYABSDIR}/.env ]; then
    echo "${MYABSDIR}/.env already exists - won't clobber... aborting."
    exit 1
else
    echo QDLARAVELENVSET=1 > ${MYABSDIR}/.env
    echo "HOSTUID=$(id -u)" >> ${MYABSDIR}/.env
    echo "HOSTGID=$(id -g)" >> ${MYABSDIR}/.env
    echo "BINDHTTP=127.0.0.1:${LOCALHTTPPORT}:80" >> ${MYABSDIR}/.env
    echo "BINDHTTPS=127.0.0.1:${LOCALHTTPSPORT}:443" >> ${MYABSDIR}/.env
    echo "BINDMYSQL=127.0.0.1:${LOCALMYSQLPORT}:3306" >> ${MYABSDIR}/.env
    echo "BINDREDIS=127.0.0.1:${LOCALREDISPORT}:6379" >> ${MYABSDIR}/.env
    echo "WWWDOMAIN=${WWWDOMAIN}" >> ${MYABSDIR}/.env
    echo "NODEVERSION=${NODEVERSION}" >> ${MYABSDIR}/.env
fi 
