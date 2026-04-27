<h1 align="center"><img width="460" src="https://github.com/balena-io/wifi-connect/raw/master/docs/images/wifi-connect.png" /></h1>

> Easy WiFi setup for Linux devices from your mobile phone or laptop

WiFi Connect is a utility for dynamically setting the WiFi configuration on a Linux device via a captive portal. WiFi credentials are specified by connecting with a mobile phone or laptop to the access point that WiFi Connect creates.

[![Current Release](https://img.shields.io/github/release/balena-io/wifi-connect.svg?style=flat-square)](https://github.com/balena-io/wifi-connect/releases/latest)
[![GitHub Actions status](https://img.shields.io/github/actions/workflow/status/balena-os/wifi-connect/ci.yml?branch=master&style=flat-square)](https://github.com/balena-os/wifi-connect/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/balena-io/wifi-connect.svg?style=flat-square)](https://github.com/balena-io/wifi-connect/blob/master/LICENSE)
[![Issues](https://img.shields.io/github/issues/balena-io/wifi-connect.svg?style=flat-square)](https://github.com/balena-io/wifi-connect/issues)

<div align="center">
  <sub>an open source :satellite: project by <a href="https://balena.io">balena.io</a></sub>
</div>

***

[**Download**][DOWNLOAD] | [**How it works**](#how-it-works) | [**Installation**](#installation) | [**Support**](#support) | [**Roadmap**][MILESTONES]

[DOWNLOAD]: https://github.com/balena-io/wifi-connect/releases/latest
[MILESTONES]: https://github.com/balena-io/wifi-connect/milestones

![How it works](./docs/images/how-it-works.png?raw=true)

How it works
------------

WiFi Connect interacts with NetworkManager, which should be the active network manager on the device's host OS.

### 1. Advertise: Device Creates Access Point

WiFi Connect detects available WiFi networks and opens an access point with a captive portal. Connecting to this access point with a mobile phone or laptop allows new WiFi credentials to be configured.

### 2. Connect: User Connects Phone to Device Access Point

Connect to the opened access point on the device from your mobile phone or laptop. The access point SSID is, by default, `WiFi Connect`. It can be changed by setting the `--portal-ssid` command line argument or the `PORTAL_SSID` environment variable (see [this guide](https://balena.io/docs/management/env-vars/) for how to manage environment variables when running on top of balenaOS). By default, the network is unprotected, but a WPA2 passphrase can be added by setting the `--portal-passphrase` command line argument or the `PORTAL_PASSPHRASE` environment variable.

### 3. Portal: Phone Shows Captive Portal to User

After connecting to the access point from a mobile phone, it will detect the captive portal and open its web page. Opening any web page will redirect to the captive portal as well.

### 4. Credentials: User Enters Local WiFi Network Credentials on Phone

The captive portal provides the option to select a WiFi SSID from a list with detected WiFi networks and enter a passphrase for the desired network.

### 5. Connected!: Device Connects to Local WiFi Network

When the network credentials have been entered, WiFi Connect will disable the access point and try to connect to the network. If the connection fails, it will enable the access point for another attempt. If it succeeds, the configuration will be saved by NetworkManager.

---

For a complete list of command line arguments and environment variables check out our [command line arguments](./docs/command-line-arguments.md) guide.

The full application flow is illustrated in the [state flow diagram](./docs/state-flow-diagram.md).

***

Installation
------------

WiFi Connect is designed to work on systems like Raspbian or Debian, or run in a docker container on top of balenaOS.

### Raspbian/Debian Stretch

WiFi Connect depends on NetworkManager, but by default Raspbian Stretch uses dhcpcd as a network manager. The provided installation shell script disables dhcpcd, installs NetworkManager as the active network manager and downloads and installs WiFi Connect.

Run the following in your terminal, then follow the onscreen instructions:

`bash <(curl -L https://github.com/balena-io/wifi-connect/raw/master/scripts/raspbian-install.sh)`

### balenaOS

WiFi Connect can be integrated with a [balena.io](http://balena.io) application. (New to balena.io? Check out the [Getting Started Guide](https://balena.io/docs/#/pages/installing/gettingStarted.md).) This integration is accomplished through the use of two shared files:
- The [Dockerfile template](./Dockerfile.template) manages dependencies. The example included here has everything necessary for WiFi Connect. Application dependencies need to be added. For help with Dockerfiles, take a look at this [guide](https://balena.io/docs/deployment/dockerfile/).
- The [start script](./scripts/start.sh) should contain the commands that run the application. Adding these commands at the end of the script will ensure that everything kicks off after WiFi is correctly configured. 
An example of using WiFi Connect in a Python project can be found [here](https://github.com/balena-io-projects/balena-wifi-connect-example).

### balenaOS: multicontainer app

To use WiFi Connect on a multicontainer app you need to:
- Set container network mode to host
- Enable DBUS by adding the required label and environment variable (more on [balenaOS dbus](https://www.balena.io/docs/learn/develop/runtime/#dbus-communication-with-host-os))
- Grant the container Network Admin capabilities

Your `docker-compose.yml` file should look like this:
```yaml
version: "2.1"

services:
    wifi-connect:
        build: ./wifi-connect
        network_mode: "host"
        labels:
            io.balena.features.dbus: '1'
        cap_add:
            - NET_ADMIN
        environment:
            DBUS_SYSTEM_BUS_ADDRESS: "unix:path=/host/run/dbus/system_bus_socket"
    ...
```

***

Release workflow
----------------

This repository no longer depends on Flowzone. Releases are handled with repo-owned GitHub Actions workflows.

### Prepare a release PR

Run the `Prepare Version` workflow from the Actions tab. It installs `versionist` and `balena-versionist`, updates the versioned files, and opens or refreshes a release PR.

GitHub only allows `workflow_dispatch` runs for workflow files that already exist on the default branch. Before this workflow is merged, you can still test it from a feature branch by pushing changes to that branch. The workflow now supports a push-triggered dry-run mode on non-default branches, which computes the version bump and uploads a patch artifact without creating a PR.

The workflow updates these files:
- `Cargo.toml`
- `CHANGELOG.md`
- `.versionbot/CHANGELOG.yml`

Dry-run mode is for validating the workflow on a feature branch. PR creation only happens for `workflow_dispatch` runs.

### Publish a release

After the release PR is merged:
- create the matching git tag in the `vX.Y.Z` format
- create or update the GitHub release for that tag
- push the tag

The `Release Assets` workflow then builds these release artifacts:
- `wifi-connect-aarch64-unknown-linux-gnu.tar.gz`
- `wifi-connect-armv7-unknown-linux-gnueabihf.tar.gz`
- `wifi-connect-x86_64-unknown-linux-gnu.tar.gz`
- `wifi-connect-i686-unknown-linux-gnu.tar.gz`
- `wifi-connect-ui.tar.gz`

If the GitHub release already exists, the workflow uploads the assets to it. Otherwise, the assets remain attached to the workflow run for manual upload.

### Local Rust toolchain setup

The CI workflows are pinned to Rust `1.76`. To match that locally, install the toolchain and the components used by CI with:

```bash
rustup toolchain install 1.76.0 --component rustfmt --component clippy --component rust-src
rustup override set 1.76.0
```

If you do not want a repository-local override, run commands with `+1.76.0` instead, for example `cargo +1.76.0 fmt` or `cross +1.76.0 test --target aarch64-unknown-linux-gnu`.

### Local release builds

Local cross-platform release builds use `cross`, which provides the same Docker-backed build environment used in CI.

Build the default Rust release matrix locally:

```bash
cargo install cross --locked
scripts/local-build.sh
```

Build a subset of targets or include the UI tarball:

```bash
scripts/local-build.sh x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu
scripts/local-build.sh --ui
```

### Local CI runs with act

The Rust CI jobs can also be exercised locally with `act`. Because the workflow uses `cross` with a `Cross.toml` pre-build step, `act` must run in bind-mount mode so the nested Docker build sees a real host workspace path.

Run the Rust checks job for a single target with:

```bash
act -b pull_request -W .github/workflows/ci.yml -j rust-checks --matrix target:aarch64-unknown-linux-gnu
```

The `-b` flag is required for these `cross`-backed jobs. Running `act` without bind mode can fail when `cross` tries to build its custom image for the target.

***

Supported boards / dongles
--------------------------

WiFi Connect has been successfully tested using the following WiFi dongles:

Dongle                                     | Chip
-------------------------------------------|-------------------
[TP-LINK TL-WN722N](http://bit.ly/1P1MdAG) | Atheros AR9271
[ModMyPi](http://bit.ly/1gY3IHF)           | Ralink RT3070
[ThePiHut](http://bit.ly/1LfkCgZ)          | Ralink RT5370

It has also been successfully tested with the onboard WiFi on a Raspberry Pi 3.

Given these results, it is probable that most dongles with *Atheros* or *Ralink* chipsets will work.

The following dongles are known **not** to work (as the driver is not friendly with access point mode or NetworkManager):

* Official Raspberry Pi dongle (BCM43143 chip)
* Addon NWU276 (Mediatek MT7601 chip)
* Edimax (Realtek RTL8188CUS chip)

Dongles with similar chipsets will probably not work.

WiFi Connect is expected to work with all balena.io [supported boards](https://www.balena.io/docs/reference/hardware/devices/) as long as they have the [compatible dongles](https://www.balena.io/docs/reference/hardware/wifi-dongles/).

***

Support
-------

If you're having any problem, please [raise an issue](https://github.com/balena-io/wifi-connect/issues/new) on GitHub or [contact us](https://balena.io/community/), and the balena.io team will be happy to help.

***

License
-------

WiFi Connect is free software, and may be redistributed under the terms specified in
the [license](https://github.com/balena-io/wifi-connect/blob/master/LICENSE).
