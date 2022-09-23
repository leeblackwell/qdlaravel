#!/bin/bash 

WWWDOMAIN="www.qdlaravel.local"
HTUSER=qdlaravel
HTPASS=qdlaravel
APPNAME="qdlaravel"
DATABASENAME="qdlaravel"
DATABASEUSER="qdlaravel"

WILDCARDCERT=0
HTACCESS=0
MODE=0 #0=dev, 2=prod
NODEVERSION=14
BINDHTTP=127.0.0.1:8080:80
BINDHTTPS=127.0.0.1:10443:443
BINDMYSQL=127.0.0.1:33060:3306
BINDREDIS=127.0.0.1:6379:6379


CLOBBER=0
DRYRUN=0

writevalues() {
    echo ENVSET=1 
    echo "COMPOSE_PROJECT_NAME=${APPNAME}" 
    echo "DATABASENAME=${DATABASENAME}" 
    echo "DATABASEUSER=${DATABASEUSER}" 
    echo "HOSTUID=$(id -u)" 
    echo "HOSTGID=$(id -g)" 
    echo "BINDHTTP=${BINDHTTP}" 
    echo "BINDHTTPS=${BINDHTTPS}" 
    echo "BINDMYSQL=${BINDMYSQL}" 
    echo "BINDREDIS=${BINDREDIS}" 
    echo "WWWDOMAIN=${WWWDOMAIN}" 
    echo "WILDCARDCERT=${WILDCARDCERT}" 
    echo "APPNAME=${APPNAME}" 
    echo "NODEVERSION=${NODEVERSION}" 
    echo "HTACCESS=${HTACCESS}" 
    echo "HTUSER=${HTUSER}" 
    echo "HTPASS=${HTPASS}" 
}

ME=$(basename $0)
MYABSDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ -f ${MYABSDIR}/.env ]; then 
    echo "Reading/importing: ${MYABSDIR}/.env"
    source ${MYABSDIR}/.env
    if [ "$?" -ne 0 ]; then 
        echo "Error loading: ${MYABSDIR}/.env"
        exit 1
    fi
fi

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --dev)
    MODE=0
    BINDHTTP=127.0.0.1:8080:80
    BINDHTTPS=127.0.0.1:10443:443
    BINDMYSQL=127.0.0.1:33060:3306
    BINDREDIS=127.0.0.1:6379:6379
    shift # past argument
    ;;
  --prod)
    MODE=2
    BINDHTTP=127.0.0.1:80:80
    BINDHTTPS=127.0.0.1:443:443
    BINDMYSQL=127.0.0.1:3306:3306
    BINDREDIS=127.0.0.1:6379:6379
    shift # past argument
    ;;
  --wildcardcert)
    WILDCARDCERT=1
    shift # past argument
    ;;
  --htaccess)
    HTACCESS=1
    shift # past argument
    ;;
  --htuser)
    HTUSER="$2"
    shift # past argument
    shift # past value
    ;;
  --htpass)
    HTPASS="$2"
    shift # past argument
    shift # past value
    ;;
  --appname)
    APPNAME="$2"
    shift # past argument
    shift # past value
    ;;
  --nodeversion)
    NODEVERSION="$2"
    shift # past argument
    shift # past value
    ;;
  --dbname)
    DATABASENAME="$2"
    shift # past argument
    shift # past value
    ;;
  --dbuser)
    DATABASEUSER="$2"
    shift # past argument
    shift # past value
    ;;
  --porthttp)
    BINDHTTP="127.0.0.1:$2:80"
    shift # past argument
    shift # past value
    ;;
  --porthttps)
    BINDHTTPS="127.0.0.1:$2:443"
    shift # past argument
    shift # past value
    ;;
  --portmysql)
    BINDMYSQL="127.0.0.1:$2:3306"
    shift # past argument
    shift # past value
    ;;
  --portredis)
    BINDREDIS="127.0.0.1:$2:6379"
    shift # past argument
    shift # past value
    ;;
  --clobber)
    CLOBBER=1
    shift # past argument
    ;;
  -n)
    DRYRUN=1
    shift # past argument
    ;;
  -h | --help)
    echo "${ME} - set environment used by containers in this application,"
    echo "Environment file: ${MYABSDIR}/.env"
    echo "Ports:"
    echo "  HTTP  - ${BINDHTTP}"
    echo "  HTTPS - ${BINDHTTPS}"
    echo "  MySQL - ${BINDMYSQL}"
    echo "  Redis - ${BINDREDIS}"
    echo ""
    echo "--dev"
    echo "     Assume 'development' mode; ports are set to 8080/10443/33060/6379"
    echo "--prod"
    echo "     Assume 'production' mode; ports are set to 80/443/3306/6379"
    echo "--wildcardcert"
    echo "     We are using a wildcard certificate (for nginx configuration) (currently set to ${WILDCARDCERT})"
    echo "--htaccess"
    echo "     Turn on HTaccess (currently set to ${HTACCESS})"
    echo "--htuser"
    echo "     HTaccess username (currently set to '${HTUSER}')"
    echo "--htpass"
    echo "     HTaccess password (currently set to '${HTPASS}')"
    echo "--appname"
    echo "     Set the application name (currently set to '${APPNAME}')"
    echo "--nodeversion"
    echo "     Set the version of Node (currently set to ${NODEVERSION})"
    echo "--dbname"
    echo "     Database name (currently set to '${DATABASENAME}')"
    echo "--dbuser"
    echo "     Database username (currently set to '${DATABASEUSER}')"
    echo "--porthttp"
    echo "     HTTP listening port (currently set to ${BINDHTTP})"
    echo "--porthttps"
    echo "     HTTPS listening port (currently set to ${BINDHTTPS})"
    echo "--portmysql"
    echo "     MySQL listening port (currently set to ${BINDMYSQL})"
    echo "--portredis"
    echo "     Redis listening port  (currently set to ${BINDREDIS})"
    echo "--clobber"
    echo "     Overwrite ${MYABSDIR}/.env if it exists (currently set to ${CLOBBER})"
    echo ""
    exit 2
    shift # past argument
    ;;
  *) # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    echo "Unknown option: $1"
    shift              # past argument
    ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -n "${POSITIONAL}" ]; then 
  echo "Unused params: ${POSITIONAL}"
  exit 1
fi


if [ "${DRYRUN}" -eq 1 ]; then 
    writevalues
else
    if [ -f ${MYABSDIR}/.env ]; then
        if [ "${CLOBBER}" -ne 1 ]; then 
            echo "${MYABSDIR}/.env already exists - won't clobber... aborting."
            exit 1
        fi
    fi
    #If we get here, either file doesn't exist or we are going to clobber it.
    { 
        writevalues
    } > ${MYABSDIR}/.env
    echo "Updated: ${MYABSDIR}/.env"
fi


exit 0 


    echo ENVSET=1 > ${MYABSDIR}/.env
    echo "COMPOSE_PROJECT_NAME=${APPNAME}" 
    echo "DATABASENAME=${DATABASENAME}" 
    echo "DATABASEUSER=${DATABASEUSER}" 
    echo "HOSTUID=$(id -u)" 
    echo "HOSTGID=$(id -g)" 
    echo "BINDHTTP=127.0.0.1:${BINDHTTP}:80" 
    echo "BINDHTTPS=127.0.0.1:${BINDHTTPS}:443" 
    echo "BINDMYSQL=127.0.0.1:${BINDMYSQL}:3306" 
    echo "BINDREDIS=127.0.0.1:${BINDREDIS}:6379" 
    echo "WWWDOMAIN=${WWWDOMAIN}" 
    echo "WILDCARDCERT=${WILDCARDCERT}" 
    echo "APPNAME=${APPNAME}" 
    echo "NODEVERSION=${NODEVERSION}" 
    echo "HTACCESS=${HTACCESS}" 
    echo "HTUSER=${HTUSER}" 
    echo "HTPASS=${HTPASS}" 





    



