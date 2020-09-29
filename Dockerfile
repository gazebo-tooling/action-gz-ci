FROM osrf/ubuntu_i386:18.04

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
