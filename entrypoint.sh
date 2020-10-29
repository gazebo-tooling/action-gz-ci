#!/bin/sh -l

set -x
set -e

EXCLUDE_APT="libignition|libsdformat"

UBUNTU_VERSION=`lsb_release -cs`
COLLECTION_FILE=$1
export DEBIAN_FRONTEND="noninteractive"

cd "$GITHUB_WORKSPACE"

echo ::group::Install tools: apt
echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list
wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -
apt update 2>&1
echo ::endgroup::

echo ::group::Install tools: pip
pip3 install -U pip vcstool colcon-common-extensions
echo ::endgroup::

echo ::group::Fetch sources
mkdir -p workspace/src
vcs import workspace/src < $COLLECTION_FILE
echo ::endgroup::

echo ::group::Install dependencies 
ALL_PACKAGES=$(find . -iname 'packages-'$UBUNTU_VERSION'.apt' -o -iname 'packages.apt')
ALL_PACKAGES=$(grep -Ev $EXCLUDE_APT)
ALL_PACKAGES=$(sort -u $(ALL_PACKAGES) | tr '\n' ' ')
apt -y install $(ALL_PACKAGES)
echo ::endgroup::

echo ::group::Compile ignition from source
cd workspace 
colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false
echo ::endgroup::

echo ::group::Run codecheck
colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false --cmake-target codecheck --cmake-target-skip-unavailable
echo ::endgroup::
