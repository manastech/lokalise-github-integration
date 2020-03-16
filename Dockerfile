# Dockerfile
FROM crystallang/crystal:0.33.0

ADD . /src
WORKDIR /src
RUN crystal build --release ./src/lokalise-github-integration.cr

# RUN ldd ./lokalise-github-integration | tr -s '[:blank:]' '\n' | grep '^/' | \
#   xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

# FROM scratch
# COPY --from=0 /src/deps /
# FROM ubuntu:bionic
# RUN \
#   apt-get update && \
#   apt-get install -y apt-transport-https && \
#   apt-get update && \
#   DEBIAN_FRONTEND=noninteractive \
#   apt-get install -y tzdata libssl-dev libxml2-dev libyaml-dev libpcre3-dev libevent-dev && \
#   apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# COPY --from=0 /src/lokalise-github-integration /lokalise-github-integration

ENV PORT=80

EXPOSE 80

ENTRYPOINT ["/src/lokalise-github-integration"]
