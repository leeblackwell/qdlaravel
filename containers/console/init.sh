#!/bin/bash -x

usercreate() {
    useradd -m -s /bin/bash -u ${HOSTUID} containeruser
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
    echo 'sudo chmod 770 /storage/app'
} > /home/containeruser/bin/fixpermissions.sh
chown containeruser:containeruser /home/containeruser/bin/fixpermissions.sh
chmod 755 /home/containeruser/bin/fixpermissions.sh

{
    echo '#!/bin/bash'
    echo 'cd /storage/app/public'
    echo 'npm install'
    echo 'npm run dev'    
} > /home/containeruser/bin/npmmagic.sh
chown containeruser:containeruser /home/containeruser/bin/npmmagic.sh
chmod 755 /home/containeruser/bin/npmmagic.sh

#Bootstrap/cleanup stuff
sudo su -c /home/containeruser/bin/fixpermissions.sh containeruser
sudo su -c /home/containeruser/bin/npmmagic.sh containeruser

#Set console user to the 'correct' user by default
echo "sudo su - -c /bin/bash containeruser" | tee -a ~/.bashrc

#enter forever loop
while true
do
    sleep 600
done
