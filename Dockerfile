FROM ubuntu:jammy

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
