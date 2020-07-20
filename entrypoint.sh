#!/bin/sh -l

set -x
set -e

APT_DEPENDENCIES=$1
CODECOV_TOKEN=$2
CMAKE_ARGS=$3

SCRIPT_BEFORE_CMAKE="../.github/ci-bionic/before_cmake.sh"
SCRIPT_BETWEEN_CMAKE_MAKE="../.github/ci-bionic/between_cmake_make.sh"
SCRIPT_AFTER_MAKE="../.github/ci-bionic/after_make.sh"
SCRIPT_AFTER_MAKE_TEST="../.github/ci-bionic/after_make_test.sh"

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
  cppcheck \
  python3-pip \
  $APT_DEPENDENCIES

pip3 install -U pip vcstool colcon-common-extensions

update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-8

git clone https://github.com/linux-test-project/lcov.git -b v1.14
cd lcov
make install
cd ..

sh tools/code_check.sh

if [ -f ".github/ci-bionic/dependencies.yaml" ] ; then
  mkdir -p deps/src
  cd deps
  vcs import src < ../.github/ci-bionic/dependencies.yaml
  colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false
  . install/setup.sh
  cd ..
fi

mkdir build
cd build

if [ ! -z "$SCRIPT_BEFORE_CMAKE" ] ; then
  . $SCRIPT_BEFORE_CMAKE
fi

if [ ! -z "$CODECOV_TOKEN" ] ; then
  cmake .. $CMAKE_ARGS -DCMAKE_BUILD_TYPE=coverage
else
  cmake .. $CMAKE_ARGS
fi

if [ ! -z "$SCRIPT_BETWEEN_CMAKE_MAKE" ] ; then
  . $SCRIPT_BETWEEN_CMAKE_MAKE
fi

make

if [ ! -z "$SCRIPT_AFTER_MAKE" ] ; then
  . $SCRIPT_AFTER_MAKE
fi

export CTEST_OUTPUT_ON_FAILURE=1
make test

if [ ! -z "$SCRIPT_AFTER_MAKE_TEST" ] ; then
  . $SCRIPT_AFTER_MAKE_TEST
fi

if [ ! -z "$CODECOV_TOKEN" ] ; then
  make coverage VERBOSE=1

  curl -s https://codecov.io/bash > codecov.sh

  # disable gcov output with `-X gcovout -X gcov`
  bash codecov.sh -t $CODECOV_TOKEN -X gcovout -X gcov
fi
