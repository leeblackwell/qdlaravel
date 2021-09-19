#!/bin/bash

linebar(){
  seq -s- 79|tr -d '[:digit:]'
  #seq -s- $(tput cols)|tr -d '[:digit:]'
}

logger()
{
	TIMESTAMP=$( date "+%Y-%m-%d %H:%M:%S" )
	echo "$0 $TIMESTAMP $@" >> $0.log
	echo -e "$0 $TIMESTAMP\n$@" 
}

#Pull in functions 
source /root/bash-functions.sh

#Place a marker down showing when this image was built
TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
echo "$TIMESTAMP" > /image_build_timestamp.txt

#Enable globbing because it's disabled by default for non-interactive shells.  Yeah, I know, who's idea was THAT?
shopt -s extglob

#Where are we looking for files?
if [ -z $1 ]; then
	BASE="/root"
else
	BASE=$1
fi
export BASE

###############################################################################
#Tasks that are common across *all* container builds

#Notes:
#Don't install software-properties-common as it bloats the image by 300Mb+

#Expand apt repos - already done in ubuntu:focal?
#sed -r -i 's/ main/ main restricted universe multiverse/g' /etc/apt/sources.list
#RES=$? ; rescheck $RES "Failed to expand apt repo list"

#Get updated repo/pkg list
evalcommand "env DEBIAN_FRONTEND=noninteractive apt update" 1

#Add pkgs we need as 'standard'
evalcommand "env DEBIAN_FRONTEND=noninteractive apt install -y apt-utils bash less tzdata" 1

#Add pkgs that need the expanded repos
evalcommand "env DEBIAN_FRONTEND=noninteractive apt install -y dumb-init" 1

#Clear apt-cache and keep image size small as possible.
evalcommand "env DEBIAN_FRONTEND=noninteractive apt clean" 1

#Clean up
linebar ; logger "Cleaning up" ; linebar
env DEBIAN_FRONTEND=noninteractive apt autoremove -y ; resultcheck

#Go get a list and execute 'em
for S in $( ls -1 $BASE/configure_+([0-9])_* | sort -t_ -k2 )
do
	linebar
	logger "Enter: $S"
	linebar
	eval "$S 2>&1"
	RES=$?
	linebar
	logger "Exit : $S with result $RES"
	linebar
	if [ $RES -ne 0 ]; then
		exit 1
	fi
done
