# Ubuntu CI action

Compile and run tests for Ignition libraries.

## Usage

Add the following file to an Ignition repository:
`.github/workflows/ci.yml`

```
name: Ubuntu CI

on: [push, pull_request]

jobs:
  bionic-ci:
    runs-on: ubuntu-latest
    name: Ubuntu Bionic CI
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Compile and test
        id: ci
        uses: ignition-tooling/ubuntu-ci-action@master
        with:
          codecov-token: ${{ secrets.CODECOV_TOKEN }}
          cmake-args: '-DBUILD_TESTING=1'
```

### Dependencies

#### APT dependencies

Be sure to declare all apt-installable dependencies in the following files, one
package per line.

* `.github/ci/packages.apt` : Installed for all versions.
* `.github/ci/packages-<system version>.apt` : where `<system version>` can be
  bionic, focal, etc. Use these if you need to install different dependencies
  according to the distribution.

See some examples
[here](https://github.com/ignitionrobotics/ign-gazebo/tree/ign-gazebo5/.github/ci).

> The `apt-dependencies` input is deprecated. Use the `.apt` files instead.

#### Source dependencies

If you need to install dependencies from source, add a
[vcstool](https://github.com/dirk-thomas/vcstool) yaml file to:

* `.github/ci/dependencies.yaml` : Installed for all versions
* `.github/ci-<system version>/dependencies.yaml` : where `<system version>`
  can be bionic, focal, etc. Use these if you need to install different
  dependencies according to the distribution.

Dependencies are built using `colcon`.

For example, to build a custom `ign-rendering` branch on `ign-gui`, add
`.github/ci/dependencies.yaml`:

```.yaml
repositories:
  ign-rendering:
    type: git
    url: https://github.com/ignitionrobotics/ign-rendering
    version: branch_name
```

When we install a dependency from binaries, it brings all its own
dependencies along with it. But when we build it from source, we need to
manually install these indirect dependencies through `packages.apt`. In
the example above, this means appending `ign-rendering`'s dependencies like
`libogre-2.1-dev` to the other dependencies already in `ign-gui`'s
`packages.apt`.

### Codecov

Create a secret on the repository with Codecov's token, called `CODECOV_TOKEN`.

### Custom scripts

You can add optional scripts to be run at specific times of the build. They can
be either in `.github/ci` or `/github/ci-<system version>` as needed.

* `before_cmake.sh`: Runs before the `cmake` call
* `between_cmake_make.sh`: Runs after the `cmake` and before `make`
* `after_make.sh`: Runs after `make` and before `make test`
* `after_make_test.sh`: Runs after `make test`

All scripts are sourced inside the build folder. Be sure to move back to the
build folder before exiting the script.

### Custom CMake Arguments

The `cmake-args` can be used to pass additional CMake arguments to the build.
If building with codecov is enabled, it is not possible to override the build type,
which will always be `CMAKE_BUILD_TYPE=coverage`.
