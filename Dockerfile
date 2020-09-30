FROM osrf/ubuntu_arm64:bionic

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
