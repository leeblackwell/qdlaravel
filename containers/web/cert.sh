#!/bin/bash -x

SEARCHDOMAIN=""

#Pull in functions 
source /root/bash-functions.sh

checkcertfiles() {
  if [ -f /storage/certs/${SEARCHDOMAIN}.key ]; then KEY=1 ; fi
  if [ -f /storage/certs/${SEARCHDOMAIN}.crt ]; then CERT=1 ; CRTEXT=1 ; fi
  if [ -f /storage/certs/${SEARCHDOMAIN}.pem ]; then CERT=1 ; CRTEXT=2 ; fi
}

nginxconfig() {
  echo "Tweaking nginx config for certs ${SEARCHDOMAIN}"
  if [ ${CRTEXT} -eq 1 ]; then sed -r -i "s/_SSLMARKER1_/ssl_certificate \/storage\/certs\/${SEARCHDOMAIN}.crt/g" /etc/nginx/sites-enabled/default ; fi
  if [ ${CRTEXT} -eq 2 ]; then sed -r -i "s/_SSLMARKER1_/ssl_certificate \/storage\/certs\/${SEARCHDOMAIN}.pem/g" /etc/nginx/sites-enabled/default ; fi
  sed -r -i "s/_SSLMARKER2_/ssl_certificate_key \/storage\/certs\/${SEARCHDOMAIN}.key/g" /etc/nginx/sites-enabled/default
}

DOMAIN="${WWWDOMAIN}"
if [ -z "$DOMAIN" ]; then
  echo "\$WWWDOMAIN not specified.  Check ENV var?"
  exit 1
fi

#Are we looking for a wildcard cert?
if [ "${WILDCARDCERT}" -eq 1 ]; then 
  WSDOMAIN=$( echo "${DOMAIN}" | cut -d\. -f 2- | tr '\.' '_' )
  SEARCHDOMAIN="STAR_${WSDOMAIN}"
else
  SEARCHDOMAIN="${DOMAIN}"
fi



#Do we have a cert in place already?
KEY=0
CERT=0
CRTEXT=0
checkcertfiles
if [[ "${KEY}" -eq 1 && "${CERT}" -eq 1 ]]; then 
  echo "Found key & cert for ${DOMAIN}"
  nginxconfig
  exit 0
else
  echo "No key & cert for ${DOMAIN} - generating self signed"
fi

#Make our own cert.

#Generate a passphrase
export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo)

#Certificate details; replace items in angle brackets with your own info
subj="
C=UK
ST=TheNorthEast
O=CertyCertMcCertFace
localityName=Durham
commonName=$DOMAIN
organizationalUnitName=Blah Blah
emailAddress=admin@example.com
"

#Generate the server private key
openssl genrsa -des3 -out $DOMAIN.key -passout env:PASSPHRASE 2048
resultcheck

#Generate the CSR
openssl req \
    -new \
    -batch \
    -subj "$(echo -n "$subj" | tr "\n" "/")" \
    -key $DOMAIN.key \
    -out $DOMAIN.csr \
    -passin env:PASSPHRASE
fail_if_error $?
cp $DOMAIN.key $DOMAIN.key.org
resultcheck

#Strip the password so we don't have to type it every time we restart Apache
openssl rsa -in $DOMAIN.key.org -out $DOMAIN.key -passin env:PASSPHRASE
resultcheck

#Generate the cert (good for 10 years)
openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
resultcheck

#Put cert files into place
mv ${DOMAIN}.csr ${DOMAIN}.key ${DOMAIN}.key.org ${DOMAIN}.crt /storage/certs

#Check...
checkcertfiles
#... and configure.
nginxconfig

exit 0
