FROM alpine:3.2

RUN apk add --update ruby ruby-dev git alpine-sdk
COPY . /usr/src/oneops/cli
WORKDIR /usr/src/oneops/cli
RUN gem build oneops.gemspec
RUN gem install oneops-*.gem --no-rdoc --no-ri

RUN apk del git alpine-sdk && rm -rf /var/cache/apk/* && rm -fr /usr/src/oneops/cli

ENTRYPOINT ["/usr/bin/oneops"]
