FROM ghcr.io/ignition-tooling/ign-ubuntu:citadel-bionic

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
