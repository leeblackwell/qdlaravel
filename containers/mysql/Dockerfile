#Build via docker-compose for context/path to be correct
FROM ubuntu:focal

MAINTAINER lee@leeblackwell.com

ENV DATABASENAME ${DATABASENAME}
ENV DATABASEUSER ${DATABASEUSER}

COPY common/* mysql/configure* mysql/init.sh /root/

RUN /root/configure.sh

CMD ["/usr/bin/dumb-init","-v","/root/init.sh"]

#docker container run -it -p3306:3306 --mount type=bind,source="$(pwd)"/_BINDMOUNT,target=/mysql container:tag