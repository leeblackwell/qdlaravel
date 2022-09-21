#Build via docker-compose for context/path to be correct
FROM ubuntu:focal

MAINTAINER lee@leeblackwell.com

COPY common/* redis/configure* redis/init.sh /root/

RUN /root/configure.sh

CMD ["/usr/bin/dumb-init","-v","/root/init.sh"]

#docker container run -it -p80:80 --mount type=bind,source="$(pwd)"/_BINDMOUNT,target=/app container:tag