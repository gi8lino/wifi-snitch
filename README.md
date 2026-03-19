# WiFiSnitch

WiFiSnitch is a small macOS background app that exposes Wi-Fi and network tunnel status over a local Unix socket.

It exists because recent macOS versions often hide the current SSID from normal shell scripts. WiFiSnitch runs as a bundled app in user context, requests the required location permission, and makes the result available to local tools like SketchyBar.

## Features

- current SSID
- current BSSID
- Wi-Fi interface name
- Wi-Fi power state
- RSSI
- noise
- SNR
- derived link quality
- transmit rate
- channel
- channel band
- security mode
- PHY mode
- country code
- roaming detection
- SSID change timestamp
- interface change timestamp
- active tunnel interface
- active tunnel interfaces
- primary interface
- primary interface tunnel detection
- IPv4 address
- IPv6 address
- default gateway
- DNS servers
- internet reachability hint
- captive portal hint
- location authorization state
- location permission state
- local Unix socket API
- small CLI client
- Homebrew-managed background service support

## Project layout

- `agent/` — the macOS app target
- `cli/` — the CLI client
- `shared/` — shared socket helpers
- `dist/` — packaged output created by `make bundle`

## Install with Homebrew

WiFiSnitch is distributed through Homebrew in the `gi8lino/homebrew-tap` tap.

Add the tap:

```sh
brew tap gi8lino/tap
```

Install WiFiSnitch:

```sh
brew install gi8lino/tap/wifisnitch
```

This installs:

- `WiFiSnitch.app` inside the Homebrew Cellar
- `wifisnitch` to launch the app bundle executable
- `wifisnitchctl` for CLI access to the local socket API

## Start at login with Homebrew

Start WiFiSnitch as a Homebrew-managed user service:

```sh
brew services start wifisnitch
```

Stop it:

```sh
brew services stop wifisnitch
```

Restart it:

```sh
brew services restart wifisnitch
```

## Upgrade

```sh
brew upgrade gi8lino/tap/wifisnitch
brew services restart wifisnitch
```

## Uninstall

```sh
brew services stop wifisnitch
brew uninstall gi8lino/tap/wifisnitch
```

## Build from source

Build everything:

```sh
swift build
```

Build optimized binaries:

```sh
swift build -c release
```

Package the app bundle and copy the CLI into `dist/`:

```sh
make bundle
```

That creates:

- `dist/WiFiSnitch.app`
- `dist/wifisnitchctl`

## Run from a local build

Start the packaged app:

```sh
open dist/WiFiSnitch.app
```

Or:

```sh
make run
```

You can also run the raw build output directly during development:

```sh
swift build
.build/debug/WiFiSnitchAgent
```

Or optimized:

```sh
swift build -c release
.build/release/WiFiSnitchAgent
```

## Permissions

WiFiSnitch needs location permission to read the current Wi-Fi network name and related Wi-Fi details.

On first launch, macOS should prompt for permission.

If the permission prompt does not appear or you want to reset it:

```sh
tccutil reset Location io.github.gi8lino.wifisnitch
open /Applications/WiFiSnitch.app
```

If installed with Homebrew, open the app bundle directly if needed:

```sh
open /usr/local/opt/wifisnitch/libexec/WiFiSnitch.app
```

Then allow location access in:

**System Settings → Privacy & Security → Location Services**

You can verify the current state with:

```sh
wifisnitchctl get auth.location_authorized --format=text
wifisnitchctl get auth.location_permission_state --format=text
```

## Socket

WiFiSnitch listens on:

```text
~/Library/Caches/wifisnitch/wifisnitch.sock
```

You can override the socket path with the `WIFISNITCH_SOCKET` environment variable.

## CLI usage

Show help:

```sh
wifisnitchctl --help
```

Common examples:

```sh
wifisnitchctl
wifisnitchctl ssid
wifisnitchctl status
wifisnitchctl status --format=lines
wifisnitchctl wifi
wifisnitchctl network
wifisnitchctl auth
wifisnitchctl signal
wifisnitchctl debug
wifisnitchctl get wifi.ssid --format=text
wifisnitchctl get wifi.ssid,wifi.bssid,wifi.channel --format=lines
wifisnitchctl get wifi.snr,wifi.link_quality --format=lines
wifisnitchctl get network.primary_interface,network.active_tunnel_interface --format=lines
wifisnitchctl get network.primary_interface_is_tunnel --format=text
wifisnitchctl get network.active_tunnel_interfaces --format=lines
wifisnitchctl get network.ipv4_address,network.default_gateway --format=lines
wifisnitchctl ping
wifisnitchctl version
wifisnitchctl fields
wifisnitchctl formats
```

## Commands

Built-in commands:

- `PING`
- `VERSION`
- `FIELDS`
- `FORMATS`
- `GET_SSID`
- `GET_STATUS`
- `GET_WIFI`
- `GET_NETWORK`
- `GET_AUTH`
- `GET_SIGNAL`
- `GET_DEBUG`

Field queries use:

- `GET <field>`
- `GET <field1>,<field2>,...`

Examples:

- `GET wifi.ssid`
- `GET wifi.bssid`
- `GET wifi.interface`
- `GET wifi.power`
- `GET wifi.rssi`
- `GET wifi.noise`
- `GET wifi.snr`
- `GET wifi.link_quality`
- `GET wifi.tx_rate`
- `GET wifi.channel`
- `GET wifi.channel_band`
- `GET wifi.security`
- `GET wifi.phy_mode`
- `GET wifi.country_code`
- `GET wifi.roaming`
- `GET wifi.ssid_changed_at`
- `GET wifi.interface_changed_at`
- `GET network.primary_interface`
- `GET network.active_tunnel_interface`
- `GET network.active_tunnel_interfaces`
- `GET network.primary_interface_is_tunnel`
- `GET network.ipv4_address`
- `GET network.ipv6_address`
- `GET network.default_gateway`
- `GET network.dns_servers`
- `GET network.internet_reachable`
- `GET network.captive_portal`
- `GET auth.location_authorized`
- `GET auth.location_permission_state`

Formats:

- `text`
- `json`
- `lines`

## Output shape

`GET_STATUS` returns the full default payload as JSON.

Example:

```json
{
  "auth": {
    "location_authorized": true,
    "location_permission_state": "authorized_when_in_use"
  },
  "network": {
    "active_tunnel_interface": null,
    "active_tunnel_interfaces": [],
    "captive_portal": false,
    "default_gateway": "192.168.1.1",
    "dns_servers": ["1.1.1.1", "9.9.9.9"],
    "internet_reachable": true,
    "ipv4_address": "192.168.1.42",
    "ipv6_address": "fe80::1234",
    "primary_interface": "en0",
    "primary_interface_is_tunnel": false
  },
  "wifi": {
    "bssid": "aa:bb:cc:dd:ee:ff",
    "channel": 44,
    "channel_band": "5ghz",
    "country_code": "CH",
    "interface": "en0",
    "interface_changed_at": "2026-03-17T12:34:56Z",
    "link_quality": 68,
    "noise": -90,
    "phy_mode": "802.11ax",
    "power": true,
    "roaming": false,
    "rssi": -63,
    "security": "wpa3_personal",
    "snr": 27,
    "ssid": "ExampleWiFi",
    "ssid_changed_at": "2026-03-17T12:30:00Z",
    "tx_rate": 780
  }
}
```

Notes:

- `network.active_tunnel_interface` is a convenience field for the active tunnel-like interface only when the primary interface itself is tunnel-like.
- `network.active_tunnel_interfaces` contains all currently visible tunnel-like interfaces.
- `network.primary_interface_is_tunnel` tells you whether the primary interface itself looks like a tunnel.
- `network.internet_reachable` is a cheap reachability hint, not an active probe.
- `network.captive_portal` is a cheap heuristic, not a captive portal login check.
- `GET_DEBUG` exposes extra internal state useful for troubleshooting.

## SketchyBar example

Show the current Wi-Fi name:

```lua
sbar.exec("wifisnitchctl get wifi.ssid --format=text", function(output)
  local ssid = output:gsub("^%s+", ""):gsub("%s+$", "")
  if ssid == "" or ssid == "EMPTY" then
    ssid = "WiFi"
  end
end)
```

Show Wi-Fi plus tunnel info:

```lua
sbar.exec(
  "wifisnitchctl get wifi.ssid,network.active_tunnel_interface,network.primary_interface_is_tunnel --format=lines",
  function(output)
    -- parse output here
  end
)
```

## Notes

- WiFiSnitch is an agent app with `LSUIElement`.
- It must run in the logged-in user session.
- The first launch may trigger the macOS location permission prompt.
- The CLI is a thin socket client.
- `GET_SSID` returns `OK <ssid>` or `EMPTY`.
- `GET_STATUS` returns the full default payload as JSON.
- `GET_DEBUG` returns extra internal state useful for troubleshooting.
- `--socket` overrides the socket path for the CLI.
- `WIFISNITCH_SOCKET` overrides the socket path for both the app and the CLI.

## Clean and rebuild

```sh
make clean
make bundle
```

Or manually:

```sh
swift build -c release
```

## License

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.

```

```
