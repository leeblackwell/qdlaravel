#!/bin/bash

source /root/bash-functions.sh
envcheck

DATABASEDIR="/mysql"

createdbuser() {
    #Create our user
    {
        echo "USE mysql;"
        echo "CREATE USER '${DATABASEUSER}'@'%' IDENTIFIED BY 'secret';"
        echo "GRANT ALL ON *.* TO '${DATABASEUSER}'@'%';"
        echo "FLUSH PRIVILEGES;"    
    } | mysql -A
}

createdefaultdatabase() {
    {
        echo "CREATE DATABASE ${DATABASENAME};"
        echo "GRANT ALL PRIVILEGES ON ${DATABASENAME}.* TO '${DATABASEUSER}'@'%';"
    } | mysql -A
}

createtestdatabase() {
    {
        echo "CREATE DATABASE IF NOT EXISTS ${DATABASENAME}_testing;"
        echo "GRANT ALL PRIVILEGES ON ${DATABASENAME}_testing.* TO '${DATABASEUSER}'@'%';"
    } | mysql -A
}

startMySQL() {
    #stop su complaining about /nonexistent
    usermod -d /tmp mysql 

    #
    echo "127.0.0.1 mysql" >> /etc/hosts

    #
    install -m 755 -o mysql -g root -d /var/run/mysqld
    bash -c 'nohup su - mysql -s /bin/sh -c "/usr/bin/mysqld_safe 2>&1 &"'

    #Wait for MySQL to wake up
    sleep 5 
}

################################################################


#TODO
#Ensure we have a drive present, expecting a bind mount
#if [ -f "${DATABASEDIR}/BIND-MARKER" ]; then 
#    echo "Bind mount present on ${DATABASEDIR}"
#else
#    echo "Bind mount missing (${DATABASEDIR}); abort."
#    exit 1
#fi

#Bind mount check
#Check bind mounts are in place
MOUNTSPRESENTANDCORRECT=1
for CHKDIR in ${DATABASEDIR}
do 
    MOUNTED=$( grep -E -v "(\/proc|\/etc)|^(devpts|tmpfs|cgroup|sysfs|mqueue|shm|overlay)" /etc/mtab )
    echo "${MOUNTED}" | grep -E "${CHKDIR}"
    RES=$?
    if [ "${RES}" -eq 0 ]; then
        echo "Bind mount present on ${CHKDIR}"
    else
        echo "Bind mount missing (${CHKDIR})"
        MOUNTSPRESENTANDCORRECT=0
    fi
done

if [ ${MOUNTSPRESENTANDCORRECT} -ne 1 ]; then
    exit 1
fi

#if [ "${DEBUGMODE}" -gt 0 ]; then 
#    SKIPBINDMOUNT=1
#fi
#
#if [[ ${MOUNTSPRESENTANDCORRECT} -ne 1 && ${SKIPBINDMOUNT} -ne 1 ]]; then
#    exit 1
#fi

#Remove old PID files
for PIDFILE in $( ls ${DATABASEDIR}/*.pid )
do
    rm ${PIDFILE}
done

#Override where MySQL looks for databases (to our BIND mount)
#/etc/mysql/mysql.conf.d/mysqld.cnf:# datadir    = /var/lib/mysql
sed -r -i "s/(#\s?datadir\s?=\s?\/var\/lib\/mysql)/\1\ndatadir = \\${DATABASEDIR}/g" /etc/mysql/mysql.conf.d/mysqld.cnf

#If /mysql/mysql (dir, originally /var/lib/mysql/mysql) doesn't exist, we're starting from an empty dir; put what we need into place.
if [ ! -d ${DATABASEDIR}/mysql ]; then 
    echo "DB appears to be empty; setting up default."
    rsync -avP /var/lib/mysql/ ${DATABASEDIR}/
    chown -R mysql:mysql ${DATABASEDIR}
    startMySQL
    createdbuser
    createdefaultdatabase
    createtestdatabase
else
    echo "DB appears to be setup already; continuing."
    startMySQL
    createtestdatabase
fi

#Loop until mysql dies or is killed 
LOOPIT=1
while [ ${LOOPIT} -eq 1 ]
do
    sleep 30
    #echo "MySQL alive check loop, started"
    P=$( ls -1rt ${DATABASEDIR}/*.pid | tail -1 )
    if [ ! -f ${P} ]; then LOOPIT=0 ; fi
    M=$( cat $P )
    C=$( ps -eF | sed -r -n "/^mysql\s+${M}/p" | wc -l ) 
    if [ "${C}" -eq 0 ]; then LOOPIT=0 ; fi
    #echo "MySQL alive check loop, finished, LOOPIT = ${LOOPIT}"
done
