FROM uselagoon/commons AS builder

RUN apk add hugo git
WORKDIR /app
COPY hugo/. /app

ARG HUGO_BASEURL="http://hugo.docker.amazee.io"

RUN hugo  --baseURL="$HUGO_BASEURL"


FROM uselagoon/nginx

COPY --from=builder /app/public/ /app
COPY lagoon/static-files.conf /etc/nginx/conf.d/app.conf

RUN fix-permissions /usr/local/openresty/nginx
