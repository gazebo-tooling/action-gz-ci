#!/bin/sh -l

set -x

APT_DEPENDENCIES=$1
COVERAGE=$2

cd $GITHUB_WORKSPACE

apt update
apt -y install wget lsb-release gnupg
sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list'
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2486D2DD83DB69272AFE98867170598AF249743
apt-get update
apt -y install \
  cmake \
  build-essential \
  curl \
  g++-8 \
  git \
  cppcheck

update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-8

git clone https://github.com/linux-test-project/lcov.git -b v1.14
cd lcov
make install
cd ..

sh tools/code_check.sh

apt -y install $APT_DEPENDENCIES

mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=coverage
make

export CTEST_OUTPUT_ON_FAILURE=1
make test

if [ "$COVERAGE" = true ] ; then
  make coverage VERBOSE=1

  # disable gcov output with `-X gcovout -X gcov`
  run: bash <(curl -s https://codecov.io/bash) -X gcovout -X gcov
fi
