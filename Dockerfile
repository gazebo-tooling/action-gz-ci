FROM ubuntu:latest

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
