# Dockerfile
FROM crystallang/crystal:0.33.0

ADD . /src
WORKDIR /src
RUN crystal build --release ./src/lokalise-github-integration.cr

RUN ldd ./lokalise-github-integration | tr -s '[:blank:]' '\n' | grep '^/' | \
  xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

FROM scratch
COPY --from=0 /src/deps /
COPY --from=0 /src/lokalise-github-integration /lokalise-github-integration

ENV PORT=80

EXPOSE 80

ENTRYPOINT ["/lokalise-github-integration"]
