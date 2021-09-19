#!/bin/bash

source /root/bash-functions.sh

APPBASEDIR="/var/www/html"
if [ -f ${APPBASEDIR}/BIND-MARKER ]; then 
    echo "Bind mount present on ${APPBASEDIR}"
else
    echo "Bind mount missing (${APPBASEDIR}); abort."
    exit 1
fi

CERTSDIR="/var/www/html"
if [ -f ${CERTSDIR}/BIND-MARKER ]; then 
    echo "Bind mount present on ${CERTSDIR}"
else
    echo "Bind mount missing (${CERTSDIR}); abort."
    exit 1
fi

#Force perms
chgrp -R www-data /storage/app
chmod -R g+w /storage/app

#Not ideal, I know, but sort useful for local development... 
chmod -R o+w /storage/app

#Check for certs
/root/cert.sh

#PHPVER=$( apt list --installed | egrep "^php[0-9]\.[0-9]\/" | sed -r 's/php([0-9]{1}\.[0-9]{1}).*/\1/g' )
PHPVER=$( cat /root/php-version )
evalcommand "/etc/init.d/php${PHPVER}-fpm start" 1
evalcommand "/etc/init.d/nginx start" 1

#Loop until something dies or is killed 
LOOPIT=1
while [ ${LOOPIT} -eq 1 ]
do
    sleep 30
    /etc/init.d/php${PHPVER}-fpm status 2>&1  > /dev/null
    RES=$? ; if [ "${RES}" -ne 0 ]; then LOOPIT=0 ; fi
    /etc/init.d/nginx status 2>&1  > /dev/null
    RES=$? ; if [ "${RES}" -ne 0 ]; then LOOPIT=0 ; fi
done
