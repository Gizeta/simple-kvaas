FROM elixir:1.17.3-alpine AS builder

ENV MIX_ENV prod

WORKDIR /build

RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache git alpine-sdk

RUN mix local.rebar --force && \
    mix local.hex --force

COPY . .

RUN mix deps.get --only ${MIX_ENV} && \
    mix compile && \
    mix release

FROM alpine:3.20.3

ENV HTTP_PORT 8080

WORKDIR /opt/app

VOLUME [ "/data" ]

RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache ncurses leveldb

COPY --from=builder /build/_build/prod/rel/* .

EXPOSE $HTTP_PORT

ENTRYPOINT ["/opt/app/bin/simple_kvaas", "start"]
