#
# Dockerfile for shadowsocks-libev
#

FROM alpine:latest
MAINTAINER William Wang <william@10ln.com>

COPY shadowsocks-libev-3.2.3.tar.gz /tmp/shadowsocks-libev-3.2.3.tar.gz
ENV SERVER_ADDR=
ENV LOCAL_ADDR 0.0.0.0
ENV SERVER_PORT 8838
ENV LOCAL_PORT 8838
ENV PASSWORD=
ENV METHOD      aes-256-cfb
ENV TIMEOUT     5

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN set -ex && \
    apk add --no-cache --virtual .build-deps \
                                autoconf \
                                build-base \
                                curl \
                                libev-dev \
                                libtool \
                                linux-headers \
                                libsodium-dev \
                                mbedtls-dev \
                                pcre-dev \
                                tar \
                                c-ares-dev \
                                udns-dev && \
    cd /tmp && \
    tar xzf shadowsocks-libev-3.2.3.tar.gz --strip 1  && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    cd .. && \

    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \
    apk del .build-deps && \
    rm -rf /tmp/*

USER nobody

EXPOSE $LOCAL_PORT/tcp $LOCAL_PORT/udp

CMD ss-local  -s $SERVER_ADDR \
              -p $SERVER_PORT \
              -b $LOCAL_ADDR \
              -l $LOCAL_PORT \
              -k $PASSWORD \
              -m $METHOD \
              -t $TIMEOUT \
              --fast-open \
              -u
