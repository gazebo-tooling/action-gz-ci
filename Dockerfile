FROM ubuntu:resolute

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
