FROM ubuntu:focal

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
