FROM ubuntu:bionic

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
