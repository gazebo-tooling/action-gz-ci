#!/bin/bash -l

set -x
set -e

OLD_APT_DEPENDENCIES=$1
CODECOV_ENABLED=$2
CODECOV_TOKEN_PRIVATE_REPOS=$3
DEPRECATED_CODECOV_TOKEN=$4
CMAKE_ARGS=$5
DOXYGEN_ENABLED=$6
TESTS_ENABLED=$7
CPPLINT_ENABLED=$8
CPPCHECK_ENABLED=$9

# keep the previous behaviour of running codecov if old token is set
[ -n "${DEPRECATED_CODECOV_TOKEN}" ] && CODECOV_ENABLED=1

export DEBIAN_FRONTEND="noninteractive"

cd "$GITHUB_WORKSPACE"

echo ::group::Install tools: apt
apt update 2>&1
apt -y install \
  build-essential \
  cmake \
  cppcheck \
  curl \
  git \
  gnupg \
  lcov \
  lsb-release \
  python3-pip \
  wget

if [ -n "$DOXYGEN_ENABLED" ] && ${DOXYGEN_ENABLED} ; then
  apt -y install doxygen
fi

# Add the workspace as a safe directory in the global git config. This ensures that any
# even if the workspace is owned by another user, git commands still work.
# See https://github.com/actions/checkout/issues/760
git config --global --add safe.directory $GITHUB_WORKSPACE

SYSTEM_VERSION=`lsb_release -cs`

SOURCE_DEPENDENCIES="`pwd`/.github/ci/dependencies.yaml"
SOURCE_DEPENDENCIES_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/dependencies.yaml"
SCRIPT_BEFORE_DEP_COMPILATION="`pwd`/.github/ci/before_dep_compilation.sh"
SCRIPT_BEFORE_DEP_COMPILATION_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/before_dep_compilation.sh"
SCRIPT_BEFORE_CMAKE="`pwd`/.github/ci/before_cmake.sh"
SCRIPT_BEFORE_CMAKE_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/before_cmake.sh"
SCRIPT_BETWEEN_CMAKE_MAKE="`pwd`/.github/ci/between_cmake_make.sh"
SCRIPT_BETWEEN_CMAKE_MAKE_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/between_cmake_make.sh"
SCRIPT_AFTER_MAKE="`pwd`/.github/ci/after_make.sh"
SCRIPT_AFTER_MAKE_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/after_make.sh"
SCRIPT_AFTER_MAKE_TEST="`pwd`/.github/ci/after_make_test.sh"
SCRIPT_AFTER_MAKE_TEST_VERSIONED="`pwd`/.github/ci-$SYSTEM_VERSION/after_make_test.sh"

# Infer package name from GITHUB_REPOSITORY
PACKAGE=$(echo "$GITHUB_REPOSITORY" | sed 's:.*/::')
wget https://raw.githubusercontent.com/gazebo-tooling/release-tools/master/jenkins-scripts/tools/detect_cmake_major_version.py
PACKAGE_MAJOR_VERSION=$(python3 detect_cmake_major_version.py "$GITHUB_WORKSPACE"/CMakeLists.txt)

# Check for ci_matching_branch in gzdev
wget https://raw.githubusercontent.com/gazebo-tooling/release-tools/master/jenkins-scripts/tools/detect_ci_matching_branch.py
if python3 detect_ci_matching_branch.py "${GITHUB_HEAD_REF:-${GITHUB_REF#refs/heads/}}"; then
  GZDEV_TRY_BRANCH=${GITHUB_HEAD_REF:-${GITHUB_REF#refs/heads/}}
fi

git clone https://github.com/osrf/gzdev /tmp/gzdev
if [ -n "${GZDEV_TRY_BRANCH}" ]; then
  git -C /tmp/gzdev checkout ${GZDEV_TRY_BRANCH} || true
fi
pip3 install -r /tmp/gzdev/requirements.txt
/tmp/gzdev/gzdev.py \
  repository enable --project="${PACKAGE}${PACKAGE_MAJOR_VERSION}"

apt-get update 2>&1
echo ::endgroup::

echo ::group::Install tools: pip
pip3 install -U pip vcstool colcon-common-extensions
echo ::endgroup::

if [ -f "$SOURCE_DEPENDENCIES" ] || [ -f "$SOURCE_DEPENDENCIES_VERSIONED" ] ; then
  echo ::group::Fetch source dependencies
  mkdir -p deps/src
  if [ -f "$SOURCE_DEPENDENCIES" ] ; then
    vcs import deps/src < $SOURCE_DEPENDENCIES
  fi
  if [ -f "$SOURCE_DEPENDENCIES_VERSIONED" ] ; then
    vcs import deps/src < $SOURCE_DEPENDENCIES_VERSIONED
  fi
  echo ::endgroup::
fi

echo ::group::Install dependencies from binaries
apt -y install \
  $OLD_APT_DEPENDENCIES \
  $(sort -u $(find . -iname 'packages-'$SYSTEM_VERSION'.apt' -o -iname 'packages.apt') | tr '\n' ' ')
echo ::endgroup::

if [ -f "$SCRIPT_BEFORE_DEP_COMPILATION" ] || [ -f "$SCRIPT_BEFORE_DEP_COMPILATION_VERSIONED" ] ; then
  echo ::group::Script before dependencies compilation from source
  if [ -f "$SCRIPT_BEFORE_DEP_COMPILATION" ] ; then
    . $SCRIPT_BEFORE_DEP_COMPILATION
  fi
  if [ -f "$SCRIPT_BEFORE_DEP_COMPILATION_VERSIONED" ] ; then
    . $SCRIPT_BEFORE_DEP_COMPILATION_VERSIONED
  fi
  echo ::endgroup::
fi

if [ -f "$SOURCE_DEPENDENCIES" ] || [ -f "$SOURCE_DEPENDENCIES_VERSIONED" ] ; then
  echo ::group::Compile dependencies from source
  cd deps
  colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false
  . install/setup.sh
  cd ..
  echo ::endgroup::
fi

echo ::group::Build folder
mkdir build
cd build
echo ::endgroup::

if [ -f "$SCRIPT_BEFORE_CMAKE" ] || [ -f "$SCRIPT_BEFORE_CMAKE_VERSIONED" ] ; then
  echo ::group::Script before cmake
  if [ -f "$SCRIPT_BEFORE_CMAKE" ] ; then
    . $SCRIPT_BEFORE_CMAKE
  fi
  if [ -f "$SCRIPT_BEFORE_CMAKE_VERSIONED" ] ; then
    . $SCRIPT_BEFORE_CMAKE_VERSIONED
  fi
  echo ::endgroup::
fi

echo ::group::cmake
if [ -n "$CODECOV_ENABLED" ] && ${CODECOV_ENABLED} ; then
  cmake .. $CMAKE_ARGS -DCMAKE_BUILD_TYPE=coverage
else
  cmake .. $CMAKE_ARGS
fi
echo ::endgroup::

echo ::group::cpplint
if [ -n "$CPPLINT_ENABLED" ] && ${CPPLINT_ENABLED} ; then
  if grep -iq cpplint Makefile; then
    make cpplint 2>&1
  fi
fi
echo ::endgroup

echo ::group::cppcheck
if [ -n "$CPPCHECK_ENABLED" ] && ${CPPCHECK_ENABLED} ; then
  if grep -iq cppcheck Makefile; then
    make cppcheck 2>&1
  fi
fi
echo ::endgroup

if [ -n "$DOXYGEN_ENABLED" ] && ${DOXYGEN_ENABLED} ; then
  echo ::group::Documentation check
  make doc 2>&1
  bash <(curl -s https://raw.githubusercontent.com/gazebosim/gz-cmake/main/tools/doc_check.sh)
  echo ::endgroup::
fi

if [ -f "$SCRIPT_BETWEEN_CMAKE_MAKE" ] || [ -f "$SCRIPT_BETWEEN_CMAKE_MAKE_VERSIONED" ] ; then
  echo ::group::Script between cmake and make
  if [ -f "$SCRIPT_BETWEEN_CMAKE_MAKE" ] ; then
    . $SCRIPT_BETWEEN_CMAKE_MAKE
  fi
  if [ -f "$SCRIPT_BETWEEN_CMAKE_MAKE_VERSIONED" ] ; then
    . $SCRIPT_BETWEEN_CMAKE_MAKE_VERSIONED
  fi
  echo ::endgroup::
fi

echo ::group::make
make
echo ::endgroup::

if [ -f "$SCRIPT_AFTER_MAKE" ] || [ -f "$SCRIPT_AFTER_MAKE_VERSIONED" ] ; then
  echo ::group::Script after make
  if [ -f "$SCRIPT_AFTER_MAKE" ] ; then
    . $SCRIPT_AFTER_MAKE
  fi
  if [ -f "$SCRIPT_AFTER_MAKE_VERSIONED" ] ; then
    . $SCRIPT_AFTER_MAKE_VERSIONED
  fi
  echo ::endgroup::
fi

if [ -n "$TESTS_ENABLED" ] && ${TESTS_ENABLED} ; then
  echo ::group::make test
  export CTEST_OUTPUT_ON_FAILURE=1
  cd "$GITHUB_WORKSPACE"/build
  make test
  echo ::endgroup::
fi

if [ -f "$SCRIPT_AFTER_MAKE_TEST" ] || [ -f "$SCRIPT_AFTER_MAKE_TEST_VERSIONED" ] ; then
  echo ::group::Script after make test
  if [ -f "$SCRIPT_AFTER_MAKE_TEST" ] ; then
    . $SCRIPT_AFTER_MAKE_TEST
  fi
  if [ -f "$SCRIPT_AFTER_MAKE_TEST_VERSIONED" ] ; then
    . $SCRIPT_AFTER_MAKE_TEST_VERSIONED
  fi
  echo ::endgroup::
fi

if [ -n "$CODECOV_ENABLED" ] && ${CODECOV_ENABLED} ; then
  echo ::group::codecov
  make coverage VERBOSE=1

  # Download codecov, check hash
  curl -s https://codecov.io/bash > codecov
  curl -s https://codecov.io/env > env # needed to make the checksum work
  VERSION=$(grep 'VERSION=\"[0-9\.]*\"' codecov | cut -d'"' -f2)
  curl -s "https://raw.githubusercontent.com/codecov/codecov-bash/${VERSION}/SHA512SUM" > hash_file
  shasum -a 512 -c hash_file
  # disable gcov output with `-X gcovout -X gcov`
  private_repo_token=
  [ -n "${CODECOV_TOKEN}" ] && private_repo_token="-t $CODECOV_TOKEN"
  bash codecov ${private_repo_token} -X gcovout -X gcov
  echo ::endgroup::
fi
