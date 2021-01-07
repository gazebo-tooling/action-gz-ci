FROM ghcr.io/ignition-tooling/ign-ubuntu:edifice-focal

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
