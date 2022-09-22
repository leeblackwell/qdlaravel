#!/bin/bash -x

usercreate() {
    useradd -o -m -s /bin/bash -u ${HOSTUID} containeruser
    RES=$?
    if [ "${RES}" -ne 0 ]; then 
        echo "failed to create containeruser for UID ${HOSTUID}"
        exit 1
    fi
    echo "Created containeruser for UID ${HOSTUID}"
}

userdelete() {
    userdel -r containeruser
    RES=$?
    if [ "${RES}" -ne 0 ]; then 
        echo "failed to delete containeruser"
        exit 1
    fi
}

installlaravel() {
    #TODO Wrap these commands with some error checking
    #if [ ! -f /home/containeruser/.composer/vendor/bin/laravel ]; then
    #    su - -c 'composer global require laravel/installer' containeruser
    #    echo 'export PATH="$PATH:/home/containeruser/.composer/vendor/bin/"' | tee -a /home/containeruser/.bashrc
    #fi
    ###rsync /root/.composer to /home/containeruser, chown etc
    echo "NULL"
    rsync -avP /root/.composer/ /home/containeruser/.composer
    chown -R containeruser:containeruser /home/containeruser/.composer
    #sudo su -c "echo 'export PATH="$PATH:$HOME/.composer/vendor/bin/"' | tee -a ~/.bashrc"
    echo 'export PATH="$PATH:/home/containeruser/.composer/vendor/bin/"' | tee -a /home/containeruser/.bashrc
}

#Does the 'containeruser' account exist?
CONTAINERUSER=$( egrep "^containeruser" /etc/passwd )
RES=$?
if [ ${RES} -ne 0 ]; then
    usercreate
    installlaravel
fi

#Does the 'containeruser' exist and match our required UID?
CONTAINERUSER=$( egrep "^containeruser" /etc/passwd )
NULL=$( echo ${CONTAINERUSER} | egrep "^containeruser:x:${HOSTUID}" )
RES=$?
if [ ${RES} -ne 0 ]; then
    echo "containeruser exists but with wrong UID; recreating"
    userdelete
    usercreate
    installlaravel
fi

source /root/bash-functions.sh

#check env vars passed from host
envcheck

#Runtime tweak
usermod www-data -a -G containeruser
echo 'export PATH="$PATH:/home/containeruser/bin/"' | tee -a /home/containeruser/.bashrc
echo "cd /storage/app" | tee -a /home/containeruser/.bashrc

#Create perms fix script, then use it
mkdir /home/containeruser/bin
{
    echo '#!/bin/bash'
    echo 'sudo chown -R containeruser:www-data /storage/app'
    echo 'sudo chmod -R 770 /storage/app'
} > /home/containeruser/bin/fixpermissions.sh
chown containeruser:containeruser /home/containeruser/bin/fixpermissions.sh
chmod 755 /home/containeruser/bin/fixpermissions.sh

{
    echo '#!/bin/bash'
    echo "cd /storage/app/${APPNAME}"
    echo 'npm install'
    echo 'npm run dev'    
} > /home/containeruser/bin/npmmagic.sh
chown containeruser:containeruser /home/containeruser/bin/npmmagic.sh
chmod 755 /home/containeruser/bin/npmmagic.sh

{
    echo '#!/bin/bash'
    echo "cd /storage/app/${APPNAME}"
    echo 'composer install'
} > /home/containeruser/bin/composerinstall.sh
chown containeruser:containeruser /home/containeruser/bin/composerinstall.sh
chmod 755 /home/containeruser/bin/composerinstall.sh

{
    echo '#!/bin/bash'
    echo "cd /storage/app/${APPNAME}"
    echo 'if [ ! -f .env ]; then'
    echo '  cp -p .env.example .env'
    echo "  sed -r -i 's/APP_NAME=.*/APP_NAME=\"My Complete Coach\"/g' .env"
    echo "  sed -r -i 's/DB_CONNECTION.*/DB_CONNECTION=mysql/g' .env"
    echo "  sed -r -i 's/DB_HOST.*/DB_HOST=${APPNAME}-db/g' .env"
    echo "  sed -r -i 's/DB_PORT.*/DB_PORT=3306/g' .env"
    echo "  sed -r -i 's/DB_DATABASE.*/DB_DATABASE=${DATABASENAME}/g' .env"
    echo "  sed -r -i 's/DB_USERNAME.*/DB_USERNAME=${DATABASEUSER}/g' .env"
    echo "  sed -r -i 's/DB_PASSWORD.*/DB_PASSWORD=secret/g' .env"
    echo "  sed -r -i 's/MAIL_DRIVER.*/MAIL_DRIVER=smtp/g' .env"
    echo "  sed -r -i 's/MAIL_HOST.*/MAIL_HOST=maildev/g' .env"
    echo "  sed -r -i 's/MAIL_PORT.*/MAIL_PORT=25/g' .env"
    echo "  sed -r -i 's/MAIL_USERNAME.*/MAIL_USERNAME=null/g' .env"
    echo "  sed -r -i 's/MAIL_PASSWORD.*/MAIL_PASSWORD=null/g' .env"
    echo "  sed -r -i 's/MAIL_ENCRYPTION.*/MAIL_ENCRYPTION=null/g' .env"
    echo '  ./artisan key:generate'
    echo 'fi'
} > /home/containeruser/bin/envfix.sh
chown containeruser:containeruser /home/containeruser/bin/envfix.sh
chmod 755 /home/containeruser/bin/envfix.sh

#Bootstrap/cleanup stuff
linebar
echo "Fixing permissions"
sudo su -c /home/containeruser/bin/fixpermissions.sh containeruser

linebar
echo "Casting spells for NPM magic"
sudo su -c /home/containeruser/bin/npmmagic.sh containeruser

linebar
echo "Chatting to Composer about package installs"
sudo su -c /home/containeruser/bin/composerinstall.sh containeruser

linebar
echo "Sorting out .env"
sudo su -c /home/containeruser/bin/envfix.sh containeruser

#Set console user to the 'correct' user by default
echo "sudo su - -c /bin/bash containeruser" | tee -a ~/.bashrc

linebar
echo "WE ARE READY TO RUUUUUUMMMMMBBBBBLLLLLLEEEEEEEEEE"

#enter forever loop
while true
do
    sleep 600
done
