FROM bitwalker/alpine-elixir:1.6.6 as builder

ADD . /app

WORKDIR /app

ENV MIX_ENV=prod REPLACE_OS_VARS=true

RUN mix do deps.get, deps.compile, release

###############################################
FROM alpine:3.6

RUN apk add --no-cache bash

RUN apk add --no-cache \
      ca-certificates \
      openssl \
      ncurses-libs \
      zlib

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/kubot/releases/0.1.0/kubot.tar.gz /app

ENV MIX_ENV=prod REPLACE_OS_VARS=true

RUN tar -xzf kubot.tar.gz; rm kubot.tar.gz

CMD bin/kubot foreground
