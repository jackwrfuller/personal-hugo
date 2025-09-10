FROM uselagoon/commons

RUN apk add --no-cache hugo git

WORKDIR /app

VOLUME ["/app"]

EXPOSE 1313

CMD ["hugo", "server", "-D", "--bind", "0.0.0.0", "--baseURL", "http://hugo.docker.amazee.io"]


