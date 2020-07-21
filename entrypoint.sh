#!/bin/sh -l

set -x
set -e

OLD_APT_DEPENDENCIES=$1
CODECOV_TOKEN=$2
CMAKE_ARGS=$3

SOURCE_DEPENDENCIES="`pwd`/.github/ci-bionic/dependencies.yaml"
SCRIPT_BEFORE_CMAKE="`pwd`/.github/ci-bionic/before_cmake.sh"
SCRIPT_BETWEEN_CMAKE_MAKE="`pwd`/.github/ci-bionic/between_cmake_make.sh"
SCRIPT_AFTER_MAKE="`pwd`/.github/ci-bionic/after_make.sh"
SCRIPT_AFTER_MAKE_TEST="`pwd`/.github/ci-bionic/after_make_test.sh"

cd $GITHUB_WORKSPACE

echo ::group::Install tools: apt
apt update
apt -y install wget lsb-release gnupg
sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list'
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2486D2DD83DB69272AFE98867170598AF249743
apt-get update 2>&1
apt -y install \
  cmake \
  build-essential \
  curl \
  g++-8 \
  git \
  cppcheck \
  python3-pip
echo ::endgroup::

echo ::group::Install tools: pip
pip3 install -U pip vcstool colcon-common-extensions
echo ::endgroup::

echo ::group::Install tools: source
git clone https://github.com/linux-test-project/lcov.git -b v1.14 2>&1
cd lcov
make install
cd ..
echo ::endgroup::

echo ::group::GCC 8
update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-8
echo ::endgroup::

if [ -f "$SOURCE_DEPENDENCIES" ] ; then
  echo ::group::Fetch source dependencies
  mkdir -p deps/src
  vcs import deps/src < ../.github/ci-bionic/dependencies.yaml
  echo ::endgroup::
fi

echo ::group::Install dependencies from binaries
apt -y install \
  $OLD_APT_DEPENDENCIES \
  $(sort -u $(find . -iname 'packages.apt') | tr '\n' ' ')
echo ::endgroup::

if [ -f "$SOURCE_DEPENDENCIES" ] ; then
  echo ::group::Compile dependencies from source
  cd deps
  colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false
  . install/setup.sh
  cd ..
  echo ::endgroup::
fi

echo ::group::Code check
sh tools/code_check.sh 2>&1
echo ::endgroup::

echo ::group::Build folder
mkdir build
cd build
echo ::endgroup::

if [ -f "$SCRIPT_BEFORE_CMAKE" ] ; then
  echo ::group::Script before cmake
  . $SCRIPT_BEFORE_CMAKE
  echo ::endgroup::
fi

echo ::group::cmake
if [ ! -z "$CODECOV_TOKEN" ] ; then
  cmake .. $CMAKE_ARGS -DCMAKE_BUILD_TYPE=coverage
else
  cmake .. $CMAKE_ARGS
fi
echo ::endgroup::

if [ -f "$SCRIPT_BETWEEN_CMAKE_MAKE" ] ; then
  echo ::group::Script between cmake and make
  . $SCRIPT_BETWEEN_CMAKE_MAKE 2>&1
  echo ::endgroup::
fi

echo ::group::make
make
echo ::endgroup::

if [ -f "$SCRIPT_AFTER_MAKE" ] ; then
  echo ::group::Script after make
  . $SCRIPT_AFTER_MAKE 2>&1
  echo ::endgroup::
fi

echo ::group::make test
export CTEST_OUTPUT_ON_FAILURE=1
make test
echo ::endgroup::

if [ -f "$SCRIPT_AFTER_MAKE_TEST" ] ; then
  echo ::group::Script after make test
  . $SCRIPT_AFTER_MAKE_TEST 2>&1
  echo ::endgroup::
fi

if [ ! -z "$CODECOV_TOKEN" ] ; then
  echo ::group::codecov
  make coverage VERBOSE=1

  curl -s https://codecov.io/bash > codecov.sh

  # disable gcov output with `-X gcovout -X gcov`
  bash codecov.sh -t $CODECOV_TOKEN -X gcovout -X gcov
  echo ::endgroup::
fi
