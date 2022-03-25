#!/bin/bash

source /root/bash-functions.sh
envcheck



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

#PHPVER=$( apt list --installed | egrep "^php[0-9]\.[0-9]\/" | sed -r 's/php([0-9]{1}\.[0-9]{1}).*/\1/g' )
PHPVER=$( cat /root/php-version )

chmod -R 777 /storage/app/*/storage/framework/sessions
chmod -R 777 /storage/app/*/storage/logs

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


{
        echo "mypassword" | htpasswd -i -c /var/www/.htpasswd mylogin
} | tee /var/www/.htpasswd
chown www-data /var/www/.htpasswd
chmod 750 /var/www/.htpasswd 

#Check for certs
/root/cert.sh

evalcommand "/etc/init.d/php${PHPVER}-fpm start" 1
evalcommand "/etc/init.d/nginx start" 1

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
