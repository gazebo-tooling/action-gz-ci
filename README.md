# Ubuntu CI action

Compile and run tests for Ignition libraries.

## Usage

Add the following file to an Ignition repository:
`.github/workflows/ci.yml`

```
name: Ubuntu CI

on: [push, pull_request]

jobs:
  jammy-ci:
    runs-on: ubuntu-latest
    name: Ubuntu Focal CI
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Compile and test
        id: ci
        uses: gazebo-tooling/ubuntu-ci-action@jammy
        with:
          codecov-enabled: true
          doxygen-enabled: true
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
`.github/ci/dependencies.yaml` (replacing `branch_name` with the
`ign-rendering` branch you want to use):

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

For public repositories, Codecov can be enabled with `codecov-enabled: true`.

For private repositories, create a secret on the repository with Codecov's
token and add it through the `codecov-token-private-repos` input. For example:

```
        with:
          codecov-token-private-repos: ${{ secrets.CODECOV_TOKEN }}
```

> The `codecov-token` input has been deprecated, use one of the approaches above.

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

### Doxygen

Doxygen checks can be enabled with `doxygen-enabled: true`. This will make CI
fail if there is code not documented properly.

### Tests

Tests will run by default, and can be disabled with `tests-enabled: false`.
