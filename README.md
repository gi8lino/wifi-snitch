# WiFiSnitch

WiFiSnitch is a small macOS helper app that exposes Wi-Fi and network status over a local Unix socket.

It ships with a small CLI client, `wifisnitch`, so the data can be queried easily from shell scripts, status bars like Easybar, SketchyBar, and other local automation.

It exists because recent macOS versions often hide the current SSID and related Wi-Fi details from normal shell scripts. WiFiSnitch runs in the user session, requests the required location permission, and makes the result available to local tools in a simple, script-friendly way.

## Scope

WiFiSnitch is intentionally narrow:

- Wi-Fi data that is awkward to access from shell scripts on modern macOS
- network and tunnel status that is useful in bars, scripts, and local automation
- a tiny local socket protocol
- a small CLI client for querying the socket
- a Homebrew-friendly app and service workflow

## Features

- current SSID and BSSID
- interface name and hardware address
- power and service state
- RSSI, noise, SNR, and derived link quality
- transmit rate, channel, band, and channel width
- security mode, PHY mode, interface mode, and country code
- roaming detection and simple change timestamps
- primary interface and tunnel detection
- active tunnel interface list
- IPv4, IPv6, default gateway, and DNS servers
- internet reachability and captive portal hints
- location authorization state
- snapshot generation timestamp

## Install

WiFiSnitch is distributed through Homebrew in the `gi8lino/tap` tap.

Add the tap:

```bash
brew tap gi8lino/tap
```

Install WiFiSnitch:

```bash
brew install gi8lino/tap/wifisnitch
```

This installs:

- `WiFiSnitch.app` inside the Homebrew Cellar
- `wifisnitch` for CLI access to the local socket API

Start it as a user service:

```bash
brew services start wifisnitch
```

Useful service commands:

```bash
brew services stop wifisnitch
brew services restart wifisnitch
```

> [!NOTE]
> By using WiFiSnitch, you acknowledge that it is not notarized.
>
> Notarization is one of Apple's distribution checks. In practice, it means sending binaries to Apple and dealing with their packaging and approval flow.
>
> I do not mind the general idea of signing or notarization. I specifically do not want to spend time dealing with Apple's developer account, notarization pipeline, and release bureaucracy for this project.
>
> The Homebrew install is meant to work out of the box in the common case. If macOS still blocks WiFiSnitch or the CLI with a Gatekeeper or malware verification warning on your machine, remove the quarantine attribute and start it again.

If macOS blocks the app or CLI with a Gatekeeper or malware verification warning, remove quarantine and start it again:

```bash
xattr -dr com.apple.quarantine "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
xattr -d com.apple.quarantine "$(command -v wifisnitch)"
brew services start wifisnitch
```

## Permissions

WiFiSnitch needs location permission to read the current Wi-Fi network name and related Wi-Fi details.

On first launch, macOS should prompt for permission.

If the permission prompt does not appear or you want to reset it:

```bash
tccutil reset Location io.github.gi8lino.wifisnitch
open /Applications/WiFiSnitch.app
```

If installed with Homebrew, open the app bundle directly if needed:

```bash
open "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
```

Then allow location access in:

**System Settings → Privacy & Security → Location Services**

You can verify the current state with:

```bash
wifisnitch field auth.location_authorized --format=text
wifisnitch field auth.location_permission_state --format=text
```

When location access is unavailable:

- Wi-Fi-specific commands like `ssid`, `wifi`, and `signal` return `ERR permission_denied:<state>`
- `field ...` returns the same error if any requested field starts with `wifi.`
- `status` still works, but its Wi-Fi section is redacted
- non-sensitive `network.*` and `auth.*` fields still work

## Usage

Show help:

```bash
wifisnitch --help
```

Common examples:

```bash
wifisnitch
wifisnitch ssid
wifisnitch status --format=lines
wifisnitch wifi
wifisnitch network
wifisnitch debug
wifisnitch field wifi.ssid --format=text
wifisnitch field wifi.ssid,wifi.bssid,wifi.channel --format=lines
wifisnitch field wifi.hardware_address,wifi.interface_mode --format=lines
wifisnitch field network.primary_interface,network.active_tunnel_interface --format=lines
wifisnitch field network.primary_interface_is_tunnel --format=text
wifisnitch ping
wifisnitch version
```

The socket path is:

```text
~/Library/Caches/wifisnitch/wifisnitch.sock
```

You can override it with:

```bash
WIFISNITCH_SOCKET=/path/to/socket
```

## Commands

Built-in commands:

- `ping`
- `version`
- `fields`
- `formats`
- `ssid`
- `status`
- `wifi`
- `network`
- `auth`
- `signal`
- `debug`
- `field`

Field queries use:

- `field <field>`
- `field <field1>,<field2>,...`

Formats:

- `text`
- `json`
- `lines`

Available fields:

- `network.generated_at`
- `wifi.ssid`
- `wifi.bssid`
- `wifi.interface`
- `wifi.hardware_address`
- `wifi.power`
- `wifi.service_active`
- `wifi.rssi`
- `wifi.noise`
- `wifi.snr`
- `wifi.link_quality`
- `wifi.tx_rate`
- `wifi.channel`
- `wifi.channel_band`
- `wifi.channel_width`
- `wifi.security`
- `wifi.phy_mode`
- `wifi.interface_mode`
- `wifi.country_code`
- `wifi.roaming`
- `wifi.ssid_changed_at`
- `wifi.interface_changed_at`
- `network.primary_interface`
- `network.active_tunnel_interface`
- `network.active_tunnel_interfaces`
- `network.primary_interface_is_tunnel`
- `network.ipv4_address`
- `network.ipv6_address`
- `network.default_gateway`
- `network.dns_servers`
- `network.internet_reachable`
- `network.captive_portal`
- `auth.location_authorized`
- `auth.location_permission_state`

## Output shape

`status` returns the full default payload as JSON.

`field ... --format=json` returns typed JSON values, not stringified ones.

Examples:

- booleans stay booleans
- integers stay integers
- DNS and tunnel interface lists stay arrays

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
    "channel_width": "80mhz",
    "country_code": "CH",
    "hardware_address": "11:22:33:44:55:66",
    "interface": "en0",
    "interface_changed_at": "2026-03-17T12:34:56Z",
    "interface_mode": "station",
    "link_quality": 68,
    "noise": -90,
    "phy_mode": "802.11ax",
    "power": true,
    "roaming": false,
    "rssi": -63,
    "security": "wpa3_personal",
    "service_active": true,
    "snr": 27,
    "ssid": "ExampleWiFi",
    "ssid_changed_at": "2026-03-17T12:30:00Z",
    "tx_rate": 780
  }
}
```

Notes:

- `network.active_tunnel_interface` is a convenience field for the primary tunnel-like interface when the primary interface itself looks like a tunnel.
- `network.active_tunnel_interfaces` contains all currently visible tunnel-like interfaces.
- `network.internet_reachable` is a cheap reachability hint, not an active probe.
- `network.captive_portal` is a cheap heuristic, not a captive portal login check.
- `ssid` returns `OK <ssid>` or `EMPTY`.
- `debug` returns extra internal state useful for troubleshooting.

## Lua example

Show the current Wi-Fi name:

```lua
local handle = io.popen("wifisnitch field wifi.ssid --format=text")
local output = handle and handle:read("*a") or ""
if handle then handle:close() end

local ssid = output:gsub("^%s+", ""):gsub("%s+$", "")
if ssid == "" or ssid == "EMPTY" then
  ssid = "WiFi"
end

print(ssid)
```

Read Wi-Fi plus tunnel info:

```lua
local handle = io.popen(
  "wifisnitch field wifi.ssid,network.active_tunnel_interface,network.primary_interface_is_tunnel --format=lines"
)
local output = handle and handle:read("*a") or ""
if handle then handle:close() end

local values = {}
for line in output:gmatch("[^\r\n]+") do
  local key, value = line:match("^([^=]+)=(.*)$")
  if key then
    values[key] = value
  end
end

print(values["wifi.ssid"] or "")
print(values["network.active_tunnel_interface"] or "")
print(values["network.primary_interface_is_tunnel"] or "")
```

## Build

Build everything:

```bash
swift build
```

Build optimized binaries:

```bash
swift build -c release
```

Package the app bundle and CLI into `dist/`:

```bash
make bundle
```

Run the packaged app:

```bash
open dist/WiFiSnitch.app
```

Or:

```bash
make run
```

Stop local and Homebrew-managed instances:

```bash
make stop
```

## License

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.
