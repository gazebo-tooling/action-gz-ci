#!/bin/sh -l

set -x
set -e

OLD_APT_DEPENDENCIES=$1
CODECOV_TOKEN=$2
CMAKE_ARGS=$3

export DEBIAN_FRONTEND="noninteractive"

cd "$GITHUB_WORKSPACE"

echo ::group::Install tools: apt
apt update 2>&1
apt -y install \
  build-essential \
  cmake \
  cppcheck \
  curl \
  g++-8 \
  git \
  gnupg \
  lsb-release \
  python3-pip \
  wget

SYSTEM_VERSION=`lsb_release -cs`

SOURCE_DEPENDENCIES="`pwd`/.github/ci/dependencies.yaml"
SOURCE_DEPENDENCIES_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/dependencies.yaml"
SCRIPT_BEFORE_CMAKE="`pwd`/.github/ci/before_cmake.sh"
SCRIPT_BEFORE_CMAKE_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/before_cmake.sh"
SCRIPT_BETWEEN_CMAKE_MAKE="`pwd`/.github/ci/between_cmake_make.sh"
SCRIPT_BETWEEN_CMAKE_MAKE_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/between_cmake_make.sh"
SCRIPT_AFTER_MAKE="`pwd`/.github/ci/after_make.sh"
SCRIPT_AFTER_MAKE_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/after_make.sh"
SCRIPT_AFTER_MAKE_TEST="`pwd`/.github/ci/after_make_test.sh"
SCRIPT_AFTER_MAKE_TEST_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/after_make_test.sh"

# Infer package name from GITHUB_REPOSITORY
PACKAGE=$(echo "$GITHUB_REPOSITORY" | sed 's:.*/::' | sed 's:ign-:ignition-:')
wget https://raw.githubusercontent.com/ignition-tooling/release-tools/master/jenkins-scripts/tools/detect_cmake_major_version.py
PACKAGE_MAJOR_VERSION=$(python3 detect_cmake_major_version.py "$GITHUB_WORKSPACE"/CMakeLists.txt)

echo "Run ENV inside entryopoint.sh"
env
echo "SECRET"
echo $OTHER_RANDOM_SECRET

if [ ! -z "$CODECOV_TOKEN" ] ; then
  echo ::group::codecov

  curl -v -f https://codecov.io/bash > codecov.sh
  echo "Run ENV inside entryopoint.sh just before calling codecov.sh"
  env
  bash codecov.sh -t $CODECOV_TOKEN -X gcovout -X gcov || true
  echo ::endgroup::
fi
