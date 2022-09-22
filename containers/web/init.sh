#!/bin/bash

source /root/bash-functions.sh
envcheck

APPBASEDIR="/var/www/html"
CERTSDIR="/var/www/html"

#Bind mount check
#Check bind mounts are in place
MOUNTSPRESENTANDCORRECT=1
for CHKDIR in ${APPBASEDIR} ${CERTSDIR}
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


#PHPVER=$( apt list --installed | egrep "^php[0-9]\.[0-9]\/" | sed -r 's/php([0-9]{1}\.[0-9]{1}).*/\1/g' )
PHPVER=$( cat /root/php-version )

#Force perms
#chgrp -R www-data /storage/app
#chmod -R g+w /storage/app

#Not ideal, I know, but sort useful for local development... 
#chmod -R o+w /storage/app

#set umask so that permissions on session files are correct
# {
# umask 012
# } | tee -a /etc/profile
chmod -R 777 /storage/app/mcc/storage/framework/sessions
chmod -R 777 /storage/app/mcc/storage/logs

echo "****************** HTACCESS IS HERE ${HTACCESS}"

#Nginx config
{
echo 'server {'
echo '        listen 80 default_server;'
echo '        listen 443 ssl default_server;'
echo '        _SSLMARKER1_;'
echo '        _SSLMARKER2_;'
echo '        root /var/www/html/public;'
echo '        index index.html index.php;'
echo '        server_name _;'
#echo '        location / {'
#echo '                try_files $uri $uri/ =404;'
} | tee /etc/nginx/sites-enabled/default

if [ ${HTACCESS} -gt 0 ]; then
    {
    echo '                auth_basic HereBeDragons;'
    echo '                auth_basic_user_file /var/www/.htpasswd;'
    } | tee -a /etc/nginx/sites-enabled/default
fi


{
echo '          location / {'
echo '              try_files $uri $uri/ /index.php?$query_string;'
echo '          }'
echo '          location ~ \.php$ {'
echo '              fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;'
echo "              fastcgi_pass unix:/run/php/php${PHPVER}-fpm.sock;"
echo '              fastcgi_index index.php;'
echo '              include fastcgi_params;'
echo '          }'
echo '          location ~ /\.ht {'
echo '              deny all;'
echo '          }'
echo '}'
} | tee -a /etc/nginx/sites-enabled/default

echo "Setting up /var/www/.htpasswd with user ${HTUSER} and pass ${HTPASS}"
{
        echo "${HTPASS}" | htpasswd -i -c /var/www/.htpasswd ${HTUSER}
} | tee /var/www/.htpasswd
chown www-data /var/www/.htpasswd
chmod 750 /var/www/.htpasswd 

#Check for certs
/root/cert.sh

evalcommand "/etc/init.d/php${PHPVER}-fpm start" 1
evalcommand "/etc/init.d/nginx start" 1

cat -n /etc/nginx/sites-enabled/default

#Loop until something dies or is killed 
LOOPIT=1
while [ ${LOOPIT} -eq 1 ]
do
    sleep 3 #0
    /etc/init.d/php${PHPVER}-fpm status 2>&1  > /dev/null
    RES=$? ; if [ "${RES}" -ne 0 ]; then LOOPIT=0 ; fi
    /etc/init.d/nginx status 2>&1  > /dev/null
    RES=$? ; if [ "${RES}" -ne 0 ]; then LOOPIT=0 ; fi
done
