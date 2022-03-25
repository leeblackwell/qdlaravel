#Build via docker-compose for context/path to be correct
FROM ubuntu:focal

MAINTAINER lee@leeblackwell.com

ARG NODEVERSION=14
ENV NODEVERSION ${NODEVERSION}

COPY common/* qdlaravel-console/configure* qdlaravel-console/init.sh  /root/

RUN /root/configure.sh

CMD ["/usr/bin/dumb-init","-v","/root/init.sh"]

#docker container run -it -p80:80 --mount type=bind,source="$(pwd)"/_BINDMOUNT,target=/app container:tag
