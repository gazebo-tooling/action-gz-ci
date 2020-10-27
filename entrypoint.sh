#!/bin/sh -l

set -x
set -e

UBUNTU_VERSION=`lsb_release -cs`
COLLECTION_FILE=$1
export DEBIAN_FRONTEND="noninteractive"

cd "$GITHUB_WORKSPACE"

echo ::group::Install tools: apt
echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list
wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
apt update 2>&1
echo ::endgroup::

echo ::group::Install tools: pip
pip3 install -U pip vcstool colcon-common-extensions
echo ::endgroup::

echo ::group::Fetch sources
mkdir -p workspace/src
vcs import workspace/src $COLLECTION_FILE
echo ::endgroup::

echo ::group::Install dependencies 
apt -y install \
  $(sort -u $(find . -iname 'packages-'$UBUNTU_VERSION'.apt' -o -iname 'packages.apt') | tr '\n' ' ')
echo ::endgroup::

echo ::group::Compile ignition from source
cd workspace 
colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false
. install/setup.sh
cd ..
echo ::endgroup::

echo ::group::Run codecheck
cd workspace 
colcon build --symlink-install --merge-install --cmake-args -DBUILD_TESTING=false --cmake-target codecheck --cmake-target-skip-unavailable
. install/setup.sh
cd ..
echo ::endgroup::
