#Build via docker-compose for context/path to be correct
FROM ubuntu:focal

MAINTAINER lee@leeblackwell.com

#ARG WWWDOMAIN="www.placeholder.com"
ENV WWWDOMAIN ${WWWDOMAIN}
ENV HTACCESS ${HTACCESS}
ENV WILDCARDCERT ${WILDCARDCERT}

COPY common/* web/configure* web/init.sh web/cert.sh /root/

RUN /root/configure.sh

CMD ["/usr/bin/dumb-init","-v","/root/init.sh"]

#Run everything else as www-data (which is what nginx is expecting)
#USER www-data

#docker container run -it -p80:80 --mount type=bind,source="$(pwd)"/_BINDMOUNT,target=/app container:tag
