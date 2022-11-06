FROM alpine

## install all packages necessary for building
RUN apk update && apk add make && apk add g++ && apk add git && apk add sqlite && apk add sqlite-dev && apk add flex && apk add bison

## build and install mhash
RUN rm -rf /mhash

RUN mkdir mhash
RUN cd mhash && git clone https://github.com/Sembiance/mhash.git

RUN cd /mhash/mhash*/ && /mhash/mhash*/libmhash-config.sh
RUN cd /mhash/mhash*/ && /mhash/mhash*/libmhash-build.sh
RUN cd /mhash/mhash*/deps/mhash && make install

## build and install nntpd
RUN mkdir git
RUN cd git && git clone https://github.com/Nockiro/WendzelNNTPd.git

## build package
RUN cd /git/WendzelNNTPd/ && MYSQL=NO /git/WendzelNNTPd/configure

RUN cd /git/WendzelNNTPd && make
RUN cd /git/WendzelNNTPd && make install


## copy into bare working container
FROM alpine

RUN if [ ! -d /usr/local/etc ]; then install -d -m 0755 /usr/local/etc; fi
RUN if [ ! -d /usr/local/sbin ]; then install -d -m 0755 /usr/local/sbin; fi
RUN if [ ! -d /usr/local/share ]; then install -d -m 0755 /usr/local/share; fi
RUN if [ ! -d /usr/local/share/doc ]; then install -d -m 0755 /usr/local/share/doc; fi
RUN if [ ! -d /usr/local/share/doc/wendzelnntpd ]; then install -d -m 0755 /usr/local/share/doc/wendzelnntpd; fi
# copy libraries necessary
COPY --from=0 /usr/lib/libsqlite3.so* /usr/lib/
COPY --from=0 /usr/local/lib/libmhash* /usr/local/lib/

# binaries
COPY --from=0 /git/WendzelNNTPd/bin/wendzelnntpd /git/WendzelNNTPd/bin/wendzelnntpadm /usr/local/sbin/
RUN chown 0:0 /usr/local/sbin/wendzelnntpd /usr/local/sbin/wendzelnntpadm
RUN chmod 0755 /usr/local/sbin/wendzelnntpd /usr/local/sbin/wendzelnntpadm

# documentation and config files
COPY --from=0 /git/WendzelNNTPd/database/* /var/spool/news/wendzelnntpd/
COPY --from=0 /git/WendzelNNTPd/docs/docs /usr/local/share/doc/wendzelnntpd/
RUN chown 0:0 /usr/local/share/doc/wendzelnntpd/*
RUN chmod 0644 /usr/local/share/doc/wendzelnntpd/*

# config

RUN mkdir -p /var/spool/news/

## following lines have to be enabled for keeping the config/database inside the container
# COPY --from=0 /git/WendzelNNTPd/wendzelnntpd.conf /usr/local/etc/
# RUN chown 0:0 /usr/local/etc/wendzelnntpd.conf
# RUN chmod 0644 /usr/local/etc/wendzelnntpd.conf

# RUN chmod 700 /var/spool/news/wendzelnntpd
# og-rwx since the passwords are stored in the database too!
# RUN chmod 700 /var/spool/news/wendzelnntpd
# create a backup of the old usenet database, if needed
# RUN install -d -m 0700 -o 0 -g 0 /var/spool/news/wendzelnntpd

EXPOSE 119

ENTRYPOINT ["wendzelnntpd"]
