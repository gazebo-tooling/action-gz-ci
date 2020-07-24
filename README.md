# Ignition CI action

Compile and run tests for Ignition libraries.

## Usage

Add the following file to an Ignition repository:
`.github/workflows/ci.yml`

```
name: Ubuntu Bionic CI

on: [push, pull_request]

jobs:
  bionic-ci:
    runs-on: ubuntu-latest
    name: Ubuntu Bionic CI
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Bionic CI
        id: ci
        uses: ignition-tooling/action-ignition-ci@master
        with:
          docker_image: 'ubuntu:bionic'
          apt-dependencies: ''
          codecov-token: ${{ secrets.CODECOV_TOKEN }}
          cmake-args: '-DBUILD_TESTING=1'
```

### Docker image

The `docker_image` input is optional and defaults to `ubuntu:bionic`. It can
be set to any valid Docker image.

Make sure the files below are saved on directories matching the chosen image.

### Dependencies

Be sure to put all apt-installable dependencies into `apt-dependencies`.

If you need to install dependencies from source, add a Vcstool yaml file to:

`.github/ubuntu:bionic/dependencies.yaml`

> Change `ubuntu:bionic` to match the `docker_image` input.

Dependencies will be built using `colcon`. Be sure to add the apt dependencies
of dependencies build from source to `apt-dependencies`.

### Codecov

Create a secret on the repository with Codecov's token, called `CODECOV_TOKEN`.

### Custom scripts

You can add optional scripts to be run at specific times of the build:

* `.github/ubuntu:bionic/before_cmake.sh`: Runs before the `cmake` call
* `.github/ubuntu:bionic/between_cmake_make.sh`: Runs after the `cmake` and before `make`
* `.github/ubuntu:bionic/after_make.sh`: Runs after `make` and before `make test`
* `.github/ubuntu:bionic/after_make_test.sh`: Runs after `make test`

> Change `ubuntu:bionic` to match the `docker_image` input.

All scripts are sourced inside the build folder. Be sure to move back to the
build folder before exiting the script.

### Custom CMake Arguments

The `cmake-args` can be used to pass additional CMake arguments to the build.
If building with codecov is enabled, it is not possible to override the build type,
which will always be `CMAKE_BUILD_TYPE=coverage`.
