# Alfredpi Developer Guide

This guide covers local development, testing, firmware builds and deployment for Alfredpi.

## Architecture

Alfredpi is a poncho-style collection of three Mix projects rather than a Mix umbrella:

```text
alfredpi_new/
├── alfredpi/       # Nerves firmware and hardware drivers
├── rabbit_manager/ # Shared OTP/domain application
└── alfredpi_ui/    # Phoenix LiveView interface and API
```

Path dependencies connect the projects:

- `alfredpi` depends on `rabbit_manager` and `alfredpi_ui`.
- `alfredpi_ui` depends on `rabbit_manager`.
- On the host, `alfredpi_ui` starts `Alfredpi.RabbitSupervisor` and uses `Alfredpi.RabbitMock`.
- In firmware, `alfredpi` starts the shared supervisor and uses `Alfredpi.RabbitHardware`.

### Supervision

`Alfredpi.RabbitSupervisor` owns the hardware-independent runtime:

- `Alfredpi.DynamicSupervisor` for embedded applications and external commands
- `RabbitManager.PubSub` for UI/runtime events
- `Alfredpi.ChoregraphyAgent` for the in-memory choreography index
- `Alfredpi.ChoregraphyManager` for persistence and execution
- `Alfredpi.RabbitManager` as the main domain and hardware facade

On the device, `Alfredpi.Application` also supervises sound-device monitoring, Wi-Fi setup input, LEDs and both ears.

## Prerequisites

Install:

- Git
- `asdf` or another compatible language-version manager
- Erlang/OTP and Elixir
- Node.js
- `fwup`
- Standard Nerves host dependencies for your operating system
- An SSH public key in `~/.ssh` for target firmware builds

The expected versions are recorded in the repository root:

```sh
asdf install
```

Check [`.tool-versions`](.tool-versions) rather than relying on versions copied into this document.

Nerves may require additional packages such as build tools, `pkg-config`, autoconf, automake and squashfs utilities. Follow the official [Nerves installation guide](https://hexdocs.pm/nerves/installation.html) for your platform.

## Initial setup

Each poncho child has its own dependency lock and Mix environment. Fetch dependencies separately:

```sh
cd rabbit_manager
mix deps.get

cd ../alfredpi_ui
mix setup

cd ../alfredpi
mix deps.get
```

The firmware project declares the required `nerves_bootstrap` archive. If Mix asks to install or update it, follow the prompt, or install the version required by `alfredpi/mix.exs` explicitly.

## Host development

The Phoenix project is the normal host-development entry point. Its host configuration uses:

- `Alfredpi.RabbitMock` instead of real hardware
- `/tmp` for runtime data
- `Alfredpi.Ntfy`, `Alfredpi.Surprise` and `Alfredpi.Taichi` as available applications

Start it with:

```sh
cd alfredpi_ui
mix phx.server
```

Open <http://localhost:4000>.

For an interactive shell:

```sh
iex -S mix phx.server
```

The dev server binds to loopback by default. To access it from another machine, deliberately change the endpoint IP in `alfredpi_ui/config/dev.exs` and consider the security implications.

### Runtime data

Host data is written beneath `/tmp` according to `alfredpi_ui/config/config.exs`. Device data is written beneath `/data/alfredpi` according to `alfredpi/config/target.exs`.

Persistent files include:

- General parameters
- Embedded application configuration
- User choreography files
- Cached sound resources
- Surprise application downloads

## Tests and quality checks

Run each project's tests independently:

```sh
cd rabbit_manager && mix test
cd ../alfredpi_ui && mix test
cd ../alfredpi && mix test
```

The firmware project prefers the host target for `mix test`. Do not set `MIX_TARGET` when running ordinary host tests.

For the Phoenix project, use its precommit alias before submitting changes:

```sh
cd alfredpi_ui
mix precommit
```

This compiles with warnings as errors, removes unused dependency locks, formats code and runs tests.

Some existing tests are incomplete or may lag behind current behavior. Treat failures as issues to investigate rather than silently skipping them. Run focused tests with:

```sh
mix test path/to/test_file.exs
mix test --failed
```

Format each child project from its own directory because each has a separate `.formatter.exs`.

## Choreography engine

The choreography DSL lives in `rabbit_manager`:

- `src/alfredpi_choregraphy_parser_lexer.xrl` — Leex lexer
- `src/alfredpi_choregraphy.yrl` — Yecc grammar
- `lib/alfredpi/executor.ex` — validation and execution
- `priv/choregraphy/builtins.chor` — built-in system choreographies

The Mix project prepends `:leex` and `:yecc` to its compiler list, so generated parser modules are built automatically.

Important DSL constructs:

```text
var Delay = 200
repeat 3
  led_color ~ff0000, Led2
  sleep Delay
end

exec
  move_ear Left, 5
and
  move_ear Right, -5
end
```

Built-in action names map to `Alfredpi.RabbitManager` functions. Keep parsing and orchestration hardware-independent so they remain testable with `RabbitMock`.

## Build the web assets for firmware

The Nerves release includes the Phoenix application, so build production assets before building firmware:

```sh
cd alfredpi_ui
MIX_ENV=prod mix assets.deploy
```

The checked-in `alfredpi/Makefile` also performs asset deployment, but it currently contains machine-specific paths and a fixed device IP. Review it before use rather than treating it as a portable build entry point.

## Build firmware

The supported target is `alfredpi_rpi3a`:

```sh
cd alfredpi
export MIX_TARGET=alfredpi_rpi3a
mix deps.get
mix firmware
```

The custom Nerves system is fetched from `olb17/alfredpi_rpi3a` through the dependency in `alfredpi/mix.exs`.

Firmware is normally produced under:

```text
alfredpi/_build/alfredpi_rpi3a_dev/nerves/images/
```

Use `MIX_ENV=prod` consistently for both asset and firmware commands if producing a production build.

### SSH keys

Target configuration collects public keys matching:

```text
~/.ssh/id_{rsa,ecdsa,ed25519}.pub
```

A target build fails when no matching key exists. Generate a key first if necessary:

```sh
ssh-keygen -t ed25519
```

The target also currently configures an `alfredpi` password. SSH keys are preferred; review authentication settings before deploying on an untrusted network.

## Burn an SD card

With `MIX_TARGET` still set:

```sh
cd alfredpi
mix burn
```

Mix/fwup prompts for the destination device.

> [!WARNING]
> Burning destroys data on the selected card. Check the destination carefully.

To burn an explicit firmware file using `fwup`, run:

```sh
fwup -a -i path/to/alfredpi.fw -t complete
```

Specify an output device with `-d` only after verifying its path with your operating system's disk tools.

## Connect to a device

The target advertises `alfredpi.local` over mDNS. Connect to its Nerves IEx shell with:

```sh
ssh alfredpi.local
```

If mDNS is unavailable:

```sh
ssh DEVICE_IP
```

A useful SSH configuration for frequently reflashed devices is:

```sshconfig
Host alfredpi.local
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
```

Only disable host-key checking for a trusted development network.

## Upload firmware to a running device

After `mix firmware`, use the supplied upload script:

```sh
cd alfredpi
MIX_TARGET=alfredpi_rpi3a ./upload.sh alfredpi.local
```

Or specify an explicit image:

```sh
./upload.sh DEVICE_IP /absolute/path/to/alfredpi.fw
```

The script streams the image to the Nerves `fwup` SSH subsystem. Keep the device powered throughout the upload and update.

## Device configuration

Key files include:

| File | Purpose |
| --- | --- |
| `alfredpi/config/config.exs` | Firmware, embedded Phoenix endpoint and target selection |
| `alfredpi/config/host.exs` | Host-safe Nerves Runtime configuration |
| `alfredpi/config/target.exs` | Logging, SSH, networking and hardware implementation |
| `alfredpi/config/alfredpi_rpi3a.exs` | Blinkchain and Porcelain target details |
| `alfredpi_ui/config/config.exs` | Standalone Phoenix and host mock configuration |
| `alfredpi_ui/config/dev.exs` | Development endpoint and watchers |

The target exposes Phoenix over HTTP port 80 and currently disables origin checking. Treat the device UI as local-network software unless authentication, TLS and stricter origin policy are added.

### Network configuration

The firmware configures:

- `usb0` with `VintageNetDirect`
- `eth0` with DHCP
- `wlan0` with `VintageNetWiFi`
- `alfredpi.local` through `mdns_lite`
- VintageNetWizard for initial or manually requested Wi-Fi setup

The regulatory domain is currently `"00"`. Set the correct two-letter regulatory domain before deploying where required.

## Adding an embedded application

Embedded applications implement the `Alfredpi.RabbitManager.EmbedApplication` behaviour:

- `application_name/0`
- `child_spec/1`
- `kill/0`
- `default_config/0`
- `changeset/1`

Then add the module to the appropriate `:rabbit_manager, :application_list` configuration. If it needs custom UI, map it to a Phoenix component in `AlfredpiUiWeb.AppsLive`.

Use the shared `Alfredpi.DynamicSupervisor` for runtime application processes and publish lifecycle changes through `RabbitManager.PubSub`.

## Release checklist

Before publishing firmware:

1. Review `.tool-versions` and lockfiles.
2. Run all relevant host tests and `alfredpi_ui`'s `mix precommit`.
3. Build production web assets.
4. Build firmware with `MIX_TARGET=alfredpi_rpi3a` and the intended `MIX_ENV`.
5. Inspect firmware metadata with `fwup -m -i IMAGE.fw`.
6. Test first boot, Wi-Fi onboarding, hardware controls and firmware upgrade on real hardware.
7. Record the target system and application versions in release notes.
8. Collect applicable third-party copyright and license notices for the firmware distribution.
9. Attach the tested `.fw` image, `LICENSE`, `NOTICE` and checksums to the release.

## Known development caveats

- The root directory is a poncho workspace, not a Mix project; run Mix commands inside a child directory.
- Child projects currently declare different minimum Elixir versions, while the root toolchain controls the actual local version.
- The `Makefile` is not portable in its current form.
- The upload script's internal fallback target is `rpi0`; explicitly set `MIX_TARGET=alfredpi_rpi3a`.
- Existing documentation and tests are still being brought in line with the current implementation.
- Original repository content is licensed under Apache-2.0; dependencies and vendored files retain their respective licenses.
