ARG docker_image
FROM alpine:${docker_image}

COPY . .

RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]
