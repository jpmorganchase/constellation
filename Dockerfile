FROM ubuntu:trusty as builder

RUN apt-get update

RUN apt-get install -y curl && \
    curl -sSL https://get.haskellstack.org/ | sh

# We need a PPA for libsodium on trusty:
RUN bash -c 'if [ "$(lsb_release -sc)" == "trusty" ]; then \
               apt-get install -y software-properties-common && \
               add-apt-repository ppa:chris-lea/libsodium && \
               apt-get update; \
             fi'

RUN apt-get install -y libgmp-dev libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev && \
    apt-get install -y ruby ruby-dev build-essential && \
    gem install --no-ri --no-rdoc fpm

ENV SRC /usr/local/src/constellation
WORKDIR $SRC

ADD stack.yaml $SRC/
RUN stack setup

ADD LICENSE constellation.cabal $SRC/
RUN stack build --dependencies-only

ADD README.md CHANGELOG.md Setup.hs $SRC/
COPY bin/ $SRC/bin/
COPY test/ $SRC/test/
COPY Constellation/ $SRC/Constellation/
RUN stack install --local-bin-path /usr/local/bin --test

# Pull binary into a second stage deploy alpine container
FROM ubuntu:trusty

COPY --from=builder /usr/local/bin/constellation-node /usr/local/bin/

ENTRYPOINT ["constellation-node"]