#!/bin/sh -l

set -x

APT_DEPENDENCIES=$1
CODECOV_TOKEN=$2
SCRIPT_BEFORE_CMAKE=$3
SCRIPT_BETWEEN_CMAKE_MAKE=$4
SCRIPT_AFTER_MAKE=$5
SCRIPT_AFTER_MAKE_TEST=$6

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
  python3-pip

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

apt -y install $APT_DEPENDENCIES

if [ -f "../.github/ci-bionic/dependencies.yaml" ] ; then
  mkdir -p deps/src
  cd deps
  vcs import src < ../.github/ci-bionic/dependencies.yaml
  cd ..
  colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false
  . install/setup.sh
  cd ..
fi

mkdir build
cd build

echo "SCRIPT_BEFORE_CMAKE"
if [ ! -z "$SCRIPT_BEFORE_CMAKE" ] ; then
  bash $SCRIPT_BEFORE_CMAKE
fi

if [ ! -z "$CODECOV_TOKEN" ] ; then
  cmake .. -DCMAKE_BUILD_TYPE=coverage
else
  cmake ..
fi

echo "SCRIPT_BETWEEN_CMAKE_MAKE"
if [ ! -z "$SCRIPT_BETWEEN_CMAKE_MAKE" ] ; then
  bash $SCRIPT_BETWEEN_CMAKE_MAKE
fi

make

echo "SCRIPT_AFTER_MAKE"
if [ ! -z "$SCRIPT_AFTER_MAKE" ] ; then
  bash $SCRIPT_AFTER_MAKE
fi

export CTEST_OUTPUT_ON_FAILURE=1
make test

echo "SCRIPT_AFTER_MAKE_TEST"
if [ ! -z "$SCRIPT_AFTER_MAKE_TEST" ] ; then
  bash $SCRIPT_AFTER_MAKE_TEST
fi

if [ ! -z "$CODECOV_TOKEN" ] ; then
  make coverage VERBOSE=1

  curl -s https://codecov.io/bash > codecov.sh

  # disable gcov output with `-X gcovout -X gcov`
  bash codecov.sh -t $CODECOV_TOKEN -X gcovout -X gcov
fi
