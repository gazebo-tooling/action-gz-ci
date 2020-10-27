FROM ubuntu:focal

RUN apt update && \
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

RUN apt install -y binutils-dev curl freeglut3-dev libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev libbenchmark-dev libcurl4-openssl-dev libdart-collision-ode-dev libdart-dev libdart-external-ikfast-dev libdart-external-odelcpsolver-dev libdart-utils-urdf-dev libeigen3-dev libfreeimage-dev libgflags-dev libglew-dev libgts-dev libjsoncpp-dev libogre-1.9-dev libprotobuf-dev libprotoc-dev libsqlite3-dev libswscale-dev libtinyxml2-dev libwebsockets-dev libxi-dev libxmu-dev libyaml-dev libzip-dev libzmq3-dev pkg-config protobuf-compiler python-yaml qml-module-qtcharts qml-module-qtgraphicaleffects qml-module-qt-labs-folderlistmodel qml-module-qt-labs-platform qml-module-qt-labs-settings qml-module-qtqml-models2 qml-module-qtquick2 qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-dialogs qml-module-qtquick-layouts qml-module-qtquick-templates2 qml-module-qtquick-window2 qtbase5-dev qtdeclarative5-dev qtquickcontrols2-5-dev rubocop ruby ruby-dev ruby-ronn swig uuid-dev xvfb

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
