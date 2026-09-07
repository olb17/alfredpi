# Alfredpi User Guide

This guide explains how to install and operate Alfredpi on a compatible Nabaztag fitted with a TagTagTag board extension.

## Requirements

- A compatible Nabaztag and TagTagTag board
- A microSD card suitable for the board
- A computer with an SD card reader for initial installation
- A 2.4 GHz Wi-Fi network supported by the device
- A current Alfredpi `.fw` firmware image

Alfredpi currently targets the custom `alfredpi_rpi3a` Nerves system. Do not install its firmware on unrelated hardware.

## Install firmware on an SD card

> [!WARNING]
> Burning firmware erases the selected card. Verify the device name before continuing.

The exact process depends on how firmware is distributed. If you received a release image, install `fwup` and burn it with:

```sh
fwup your-alfredpi-image.fw
```

`fwup` will ask you to select and confirm the destination. Follow its prompts carefully. Developers building firmware from source can instead use `mix burn`; see [DEVELOPER.md](DEVELOPER.md).

After writing the card:

1. Safely eject it from the computer.
2. Insert it into the powered-off rabbit.
3. Power on the rabbit.
4. Allow several minutes for the first boot.

## First boot and Wi-Fi setup

If Alfredpi has no saved Wi-Fi configuration, it automatically starts the VintageNet Wi-Fi setup wizard and temporarily stops the normal web interface.

1. Wait for the setup access point to appear on your phone or computer.
2. Connect to that access point.
3. If the setup page does not open automatically, open the captive-portal page offered by your operating system.
4. Select your Wi-Fi network and enter its credentials.
5. Wait while Alfredpi leaves setup mode and joins the selected network.

When setup completes, the normal web interface starts again. Open:

```text
http://alfredpi.local/
```

If that address does not resolve, find the rabbit's IP address in your router and use `http://DEVICE_IP/`.

## Connect over SSH

From a computer on the same network, connect to the rabbit with:

```sh
ssh alfredpi@alfredpi.local
```

When prompted, enter `alfredpi` as the password. The username and password are both `alfredpi`.

If `alfredpi.local` does not resolve, replace it with the rabbit's IP address:

```sh
ssh alfredpi@DEVICE_IP
```

The SSH session opens an Elixir shell that can control the rabbit through functions in `Alfredpi.RabbitManager`. To discover the available functions, run:

```elixir
h Alfredpi.RabbitManager
```

### Reopen Wi-Fi setup

Hold the configured hardware button for about five seconds. Alfredpi turns the LEDs red, stops the normal web interface and starts the Wi-Fi wizard. Releasing the button before five seconds is treated as a normal single-click event instead.

## Web interface

The production firmware serves HTTP on port 80. It does not currently configure HTTPS, so use it only on a trusted local network.

### Tests — `/`

The test page provides direct hardware controls:

- Move either ear by a number of clicks
- Set an ear position
- Read both ear positions
- Set one LED or all LEDs to a color
- Upload and play an MP3 file
- Record, stop and play a WAV recording

Use modest ear movements while testing. Repeatedly forcing a mechanism against its physical stop may damage it.

### Applications — `/apps`

This page lists configured embedded applications and their state. Available applications depend on whether Alfredpi is running on real hardware or in host-development mode.

Typical applications include:

- **Ntfy** — responds to notifications received over WebSocket
- **Surprise** — periodically downloads and plays a random sound
- **Taichi** — periodically runs the built-in Taichi choreography
- **Rainbow** — animates the LEDs on supported hardware

Application settings, including automatic startup, can be edited from this section where a configuration component is available.

### Choreographies — `/choregraphy`

This page lists built-in and user-created choreographies. You can:

- Create a choreography
- Validate its action script
- Execute it without saving
- Save and edit user choreographies
- Delete user choreographies
- Run existing choreographies

Codes beginning with `SYSTEM_` are reserved for built-in choreographies. Built-in entries cannot be edited or deleted.

Only one choreography can run at a time.

### General configuration — `/config`

General settings include:

- Startup choreography code
- Language (`fr_FR` or `en_GB`)
- Reboot
- Shutdown
- Factory reset

> [!WARNING]
> Factory reset removes persistent device data and reboots the device. Back up anything important before using it.

Use the web shutdown action before disconnecting power whenever practical.

### API documentation — `/swaggerui`

Swagger UI describes the available JSON endpoints. The current API can list choreographies and request playback of a choreography by code.

## Choreography basics

A choreography is a line-oriented action script. Examples:

```text
led_color ~0000ff, Led0
move_ear Left, 5
sleep 500
```

Variables and repetition:

```text
var Delay = 200
var Color = ~ff0000
repeat 3
  led_color Color, Led2
  sleep Delay
  led_color ~000000, Led2
  sleep Delay
end
```

Parallel branches:

```text
exec
  move_ear Left, 5
and
  led_color ~00ff00, Led1
end
```

Available names include `Left`, `Right`, `Led0` through `Led4`, and actions such as `move_ear`, `set_ear`, `wait_ear`, `led_color`, `play` and `sleep`.

## Firmware updates

A running device supports firmware upload over SSH. This is primarily a developer operation; see [DEVELOPER.md](DEVELOPER.md). Do not interrupt power while an update is being installed.

## Troubleshooting

### `alfredpi.local` does not open

- Confirm the rabbit and your computer are on the same network.
- Wait a few minutes after boot or Wi-Fi setup.
- Try the IP address shown by your router.
- Ensure your network permits mDNS traffic.
- Confirm you are using `http://`, not `https://`.

### The setup portal does not appear

- Disconnect mobile data or other preferred networks temporarily.
- Reconnect to Alfredpi's setup access point.
- Open your operating system's captive-portal notification.
- Hold the setup button for five seconds to restart setup mode.

### Audio does not work immediately after boot

The sound subsystem is initialized when Linux reports that the audio device is ready. Wait briefly and try again. Reboot the rabbit if the audio device never appears.

### A choreography does not run

- Validate it in the editor first.
- Check that referenced variables and choreography codes exist.
- Wait for the currently running choreography to finish.
- Check argument order and capitalization; DSL names are case-sensitive.

### An embedded application will not start

Review all required settings. Invalid or incomplete application configuration prevents startup. Network-backed applications also require working internet access.

## Data and privacy

Alfredpi stores configuration, user choreographies, downloaded resources and application data locally under its persistent data partition. Some applications contact external services—for example GitHub-hosted sound resources or a configured Ntfy server. Review application settings before enabling automatic startup.
