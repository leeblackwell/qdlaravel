#Build via docker-compose for context/path to be correct
#FROM ubuntu:focal
FROM qdlaravel_console

MAINTAINER lee@leeblackwell.com

ARG WWWDOMAIN="www.placeholder.com"
ENV WWWDOMAIN ${WWWDOMAIN}

COPY common/* qdlaravel-web/configure* qdlaravel-web/init.sh qdlaravel-web/cert.sh /root/

RUN /root/configure.sh

CMD ["/usr/bin/dumb-init","-v","/root/init.sh"]

#docker container run -it -p80:80 --mount type=bind,source="$(pwd)"/_BINDMOUNT,target=/app container:tag