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
          script-between-cmake-make: between_cmake_make.sh
          script-after-make: after_make.sh
```

Be sure to put all apt-installable dependencies into `apt-dependencies`.

Create a secret on the repository with Codecov's token, called `CODECOV_TOKEN`.

The `script-`s are optional hooks that you can run at specific times of the build.
