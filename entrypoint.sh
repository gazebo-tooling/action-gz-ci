#!/bin/sh -l

set -x

APT_DEPENDENCIES=$1
TARGET=$2

mkdir /workspace
cp /WORKSPACE.bazel /workspace
cp /BUILD.bazel /workspace
cp -r $GITHUB_WORKSPACE /workspace

apt update
apt -y install wget lsb-release gnupg

# Add OpenRobotics package repository
sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list'
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2486D2DD83DB69272AFE98867170598AF249743

# Add Bazel package repository
sh -c 'echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" > /etc/apt/sources.list.d/bazel.list'
wget -qO - https://bazel.build/bazel-release.pub.gpg | apt-key add -

apt-get update
apt -y install \
  bazel \
  build-essential \
  curl \
  g++-8 \
  git \
  cppcheck \
  python3-pip \
  $APT_DEPENDENCIES

pip3 install -U pip vcstool

update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-8

vcs import /workspace < /dependencies.yaml
cd /workspace

bazel build //$TARGET/...
bazel test //$TARGET/...
