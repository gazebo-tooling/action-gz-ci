FROM ubuntu:18.04

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
