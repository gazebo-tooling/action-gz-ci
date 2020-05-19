# Ubuntu CI action

Compile and run tests for Ignition libraries.

## Usage

Add the following file to an Ignition repository:
`.github/workflows/ci-bionic.yml`

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
        uses: ignition-tooling/ubuntu-bionic-ci-action@v1
        with:
          apt-dependencies: ''
          codecov-token: ${{ secrets.CODECOV_TOKEN }}
          script-before-cmake: before_cmake.sh
          cmake-args: '-DBUILD_TESTING=1'
          script-between-cmake-make: between_cmake_make.sh
          script-after-make: after_make.sh
          script-after-make-test: after_make_test.sh
```

### Dependencies

Be sure to put all apt-installable dependencies into `apt-dependencies`.

If you need to install dependencies from source, add a Vcstool yaml file to
`.github/ci-bionic/dependencies.yaml`. Dependencies will be built using
`colcon`. Be sure to add the apt dependencies of dependencies build from source
to `apt-dependencies`.

### Codecov

Create a secret on the repository with Codecov's token, called `CODECOV_TOKEN`.

### Custom scripts

The `script-`s are optional hooks that you can run at specific times of the build.

### Custom CMake Arguments

The `cmake-args` can be used to pass additional CMake arguments to the build.
If building with codecov is enabled, it is not possible to override the build type,
which will always be `CMAKE_BUILD_TYPE=coverage`.
