# Alfredpi

Alfredpi is an Elixir/Nerves firmware and web interface for a Nabaztag rabbit fitted with a TagTagTag board extension. It provides local control of the rabbit's ears, LEDs and audio, plus configurable choreographies and small embedded applications.

> [!NOTE]
> The project is under active development. Documentation and release packaging are still evolving, and some operations require familiarity with Nerves and embedded Linux.

## Features

- Control both ears and read their positions
- Control the five front LEDs
- Play uploaded or remote sounds and record audio
- Create, validate, store and run choreographies
- Run embedded applications such as Surprise, Ntfy, Taichi and Rainbow
- Configure Wi-Fi through an access-point setup wizard
- Manage the device through a Phoenix LiveView web interface
- List and start choreographies through a JSON API and Swagger UI
- Develop on a host computer using mock hardware

## Project layout

This repository uses the [poncho](https://hexdocs.pm/mix/Mix.Tasks.New.html#module-poncho-projects) pattern: related OTP applications live beside each other and are connected with path dependencies.

| Path | Purpose |
| --- | --- |
| `alfredpi/` | Nerves firmware, device supervision and physical hardware integration |
| `rabbit_manager/` | Shared domain logic, application management and choreography engine |
| `alfredpi_ui/` | Phoenix 1.8 LiveView web interface and JSON API |
| `pynab_scripts/` | Utilities for converting Pynab choreographies |

The supported firmware target is `alfredpi_rpi3a`, supplied by the external [`olb17/alfredpi_rpi3a`](https://github.com/olb17/alfredpi_rpi3a) Nerves system.

## Getting started

### Using an Alfredpi device

See [USER.md](USER.md) for firmware installation, first boot, Wi-Fi setup, web interface usage and troubleshooting.

### Developing Alfredpi

See [DEVELOPER.md](DEVELOPER.md) for toolchain setup, host development, tests, firmware builds and deployment.

## Web interface

On a configured device, open:

- `http://alfredpi.local/` — hardware test and home page
- `http://alfredpi.local/apps` — embedded applications
- `http://alfredpi.local/choregraphy` — choreography management
- `http://alfredpi.local/config` — general configuration
- `http://alfredpi.local/swaggerui` — API documentation

If mDNS is unavailable, replace `alfredpi.local` with the device's IP address.

## Technology

- Elixir and OTP
- Nerves
- Phoenix and LiveView
- VintageNet and VintageNetWizard
- Ecto embedded schemas
- Leex/Yecc choreography parser
- Blinkchain and Circuits.GPIO

Exact development versions are recorded in [`.tool-versions`](.tool-versions).

## Contributing

Before making changes, read [DEVELOPER.md](DEVELOPER.md). Keep hardware-independent behavior in `rabbit_manager`, use `Alfredpi.RabbitMock` for host development, and run the relevant test suites before submitting changes.

## Project status and support

This is currently a source-first project without a documented stable release channel. Consult the repository issue tracker for known problems and support once the repository is published.

## License

Copyright 2024–2026 Olivier Belhomme.

Alfredpi is licensed under the [Apache License 2.0](LICENSE). Third-party components remain subject to their respective licenses; see [NOTICE](NOTICE).
