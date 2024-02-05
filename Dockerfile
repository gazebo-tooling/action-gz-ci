FROM ubuntu:noble

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
