FROM osrf/ubuntu_i386:bionic

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
