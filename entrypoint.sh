#!/bin/sh -l

set -x
set -e

APT_DEPENDENCIES=$1
CODECOV_TOKEN=$2
CMAKE_ARGS=$3

SOURCE_DEPENDENCIES="`pwd`/.github/ci-bionic/dependencies.yaml"
SCRIPT_BEFORE_CMAKE="`pwd`/.github/ci-bionic/before_cmake.sh"
SCRIPT_BETWEEN_CMAKE_MAKE="`pwd`/.github/ci-bionic/between_cmake_make.sh"
SCRIPT_AFTER_MAKE="`pwd`/.github/ci-bionic/after_make.sh"
SCRIPT_AFTER_MAKE_TEST="`pwd`/.github/ci-bionic/after_make_test.sh"

cd $GITHUB_WORKSPACE

echo ::group::Dependencies from binaries
apt update
apt -y install wget lsb-release gnupg

if [ -n "${GITHUB_REPOSITORY}" ]; then

  IGNTIION="ignition"
  PACKAGE_REPO=$(echo $GITHUB_REPOSITORY | cut -d'/' -f 2)
  PACKAGE=$(echo "${PACKAGE_REPO/ign/$IGNITION}")
  echo ${GITHUB_REPOSITORY}
  echo ${PACKAGE_REPO}
  echo ${PACKAGE}

  apt -y install \
    git \
    python3-pip
  wget https://raw.githubusercontent.com/ignition-tooling/release-tools/master/jenkins-scripts/tools/detect_cmake_major_version.py
  software_major_version=$(python3 detect_cmake_major_version.py $GITHUB_WORKSPACE/CMakeLists.txt)
  git clone --depth 1 https://github.com/osrf/gzdev /tmp/gzdev
  pip3 install -r /tmp/gzdev/requirements.txt
  /tmp/gzdev/gzdev.py \
    repository enable --project="${PACKAGE}${software_major_version}"
else
  sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list'
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2486D2DD83DB69272AFE98867170598AF249743
fi

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
echo ::endgroup::

echo ::group::GCC 8
update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-8
echo ::endgroup::

echo ::group::Install LCOV
git clone https://github.com/linux-test-project/lcov.git -b v1.14 2>&1
cd lcov
make install
cd ..
echo ::endgroup::

echo ::group::Code check
sh tools/code_check.sh 2>&1
echo ::endgroup::

echo ::group::Dependencies from source
if [ -f "$SOURCE_DEPENDENCIES" ] ; then
  mkdir -p deps/src
  cd deps
  vcs import src < ../.github/ci-bionic/dependencies.yaml
  colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false
  . install/setup.sh
  cd ..
fi

mkdir build
cd build
echo ::endgroup::

echo ::group::Script before cmake
if [ -f "$SCRIPT_BEFORE_CMAKE" ] ; then
  . $SCRIPT_BEFORE_CMAKE
fi
echo ::endgroup::

echo ::group::cmake
if [ ! -z "$CODECOV_TOKEN" ] ; then
  cmake .. $CMAKE_ARGS -DCMAKE_BUILD_TYPE=coverage
else
  cmake .. $CMAKE_ARGS
fi
echo ::endgroup::

echo ::group::Script between cmake and make
if [ -f "$SCRIPT_BETWEEN_CMAKE_MAKE" ] ; then
  . $SCRIPT_BETWEEN_CMAKE_MAKE 2>&1
fi
echo ::endgroup::

echo ::group::make
make
echo ::endgroup::

echo ::group::Script after make
if [ -f "$SCRIPT_AFTER_MAKE" ] ; then
  . $SCRIPT_AFTER_MAKE 2>&1
fi
echo ::endgroup::

echo ::group::make test
export CTEST_OUTPUT_ON_FAILURE=1
make test
echo ::endgroup::

echo ::group::Script after make test
if [ -f "$SCRIPT_AFTER_MAKE_TEST" ] ; then
  . $SCRIPT_AFTER_MAKE_TEST 2>&1
fi
echo ::endgroup::

echo ::group::codecov
if [ ! -z "$CODECOV_TOKEN" ] ; then
  make coverage VERBOSE=1

  curl -s https://codecov.io/bash > codecov.sh

  # disable gcov output with `-X gcovout -X gcov`
  bash codecov.sh -t $CODECOV_TOKEN -X gcovout -X gcov
fi
echo ::endgroup::
