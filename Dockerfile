FROM golang:1.19.3-alpine3.17 as confd

ARG CONFD_VERSION=0.18.0

ADD https://github.com/abtreece/confd/archive/v${CONFD_VERSION}.tar.gz /tmp/

RUN apk add --no-cache \
    bzip2 \
    make && \
  mkdir -p /go/src/github.com/abtreece/confd && \
  cd /go/src/github.com/abtreece/confd && \
  tar --strip-components=1 -zxf /tmp/v${CONFD_VERSION}.tar.gz && \
  go install github.com/abtreece/confd && \
  rm -rf /tmp/v${CONFD_VERSION}.tar.gz

FROM alpine

COPY --from=confd /go/bin/confd /usr/local/bin/confd


LABEL maintainer="H Alipour" \
  org.label-schema.name="Squid" \
  org.label-schema.description="Squid docker image based on Alpine Linux." \
  org.label-schema.schema-version="1.0"

# HEALTHCHECK --interval=30m --timeout=1s \
#   CMD squidclient -h localhost cache_object://localhost/counters || exit 1

# Install packages
RUN apk add --no-cache --update bash squid

# Redirect squid access logs to stdout
RUN ln -sf /dev/stdout /var/log/squid/access.log

# Copy confd configuration
COPY confd /etc/confd

# Set entrypoint and default command arguments
COPY entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["squid","-f","/etc/squid/squid.conf","-NYCd","1"]
