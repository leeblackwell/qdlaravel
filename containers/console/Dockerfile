#Build via docker-compose for context/path to be correct
FROM ubuntu:focal

MAINTAINER lee@leeblackwell.com

ARG NODEVERSION=16
ENV NODEVERSION ${NODEVERSION}
ENV APPNAME ${APPNAME}
ENV DATABASENAME ${DATABASENAME}
ENV DATABASEUSER ${DATABASEUSER}


COPY common/* console/configure* console/init.sh /root/

RUN /root/configure.sh

CMD ["/usr/bin/dumb-init","-v","/root/init.sh"]

#docker container run -it -p80:80 --mount type=bind,source="$(pwd)"/_BINDMOUNT,target=/app container:tag