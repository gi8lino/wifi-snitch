# WiFiSnitch

WiFiSnitch is a small macOS helper app that exposes Wi-Fi and network status over a local Unix socket.

It ships with a CLI client, `wifisnitch`, so shell scripts, status bars, and local automation can query the current network state without talking to private macOS APIs directly.

Wi-Fi-specific fields require Location Services permission. Network and authorization fields remain available without Wi-Fi permission unless you explicitly lock them down.

## Install

Install from Homebrew:

```bash
brew tap gi8lino/tap
brew install gi8lino/tap/wifisnitch
brew services start wifisnitch
```

This installs:

- `WiFiSnitch.app`
- `wifisnitch`

Useful service commands:

```bash
brew services stop wifisnitch
brew services restart wifisnitch
```

If macOS blocks the app or CLI with a quarantine warning:

```bash
xattr -dr com.apple.quarantine "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
xattr -d com.apple.quarantine "$(command -v wifisnitch)"
brew services start wifisnitch
```

## Permissions

On first launch, macOS should ask for location access. WiFiSnitch needs that permission to read SSID, BSSID, RSSI, channel, and related Wi-Fi details.

To reset permission and trigger the prompt again:

```bash
tccutil reset Location io.github.gi8lino.wifisnitch
open "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
```

Then allow location access in:

**System Settings → Privacy & Security → Location Services**

Check the current state with:

```bash
wifisnitch fetch auth.location_authorized --format=text
wifisnitch fetch auth.location_permission_state --format=text
```

Without location access:

- `wifi.*` fields are unavailable
- `network.*` and `auth.*` fields still work
- `fetch` returns only the fields the agent can currently provide

## Configuration

Default config path:

```text
~/.config/wifisnitch/config.toml
```

The repository includes [config.default.toml](config.default.toml) with every current default value.

Runtime defaults:

```text
socket: /tmp/wifi-snitch/wifi-snitch.sock
lock dir: /tmp/wifi-snitch
log dir: ~/.local/state/wifisnitch
refresh interval: 60
log level: info
file logging: false
allow unauthorized fields without location: false
```

Supported environment variables:

- `WIFISNITCH_CONFIG_PATH` selects the config file.
- `WIFISNITCH_LOG_LEVEL` temporarily overrides log verbosity.

Example config:

```toml
[logging]
enabled = false
level = "info"
directory = "~/.local/state/wifisnitch"

[agent]
socket_path = "/tmp/wifi-snitch/wifi-snitch.sock"
refresh_interval_seconds = 60
allow_unauthorized_fields_without_location = false

[app]
lock_dir = "/tmp/wifi-snitch"
```

Example overrides:

```bash
WIFISNITCH_CONFIG_PATH=~/.config/wifisnitch/config.toml wifisnitch version
WIFISNITCH_LOG_LEVEL=debug open "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
wifisnitch --socket /path/to/wifi-snitch.sock ping
```

## Usage

Show help:

```bash
wifisnitch --help
```

Common commands:

```bash
wifisnitch ping
wifisnitch version
wifisnitch fields
wifisnitch formats
wifisnitch fetch wifi.ssid --format=text
wifisnitch fetch wifi --format=json
wifisnitch fetch all --format=json
wifisnitch fetch wifi.ssid,wifi.bssid,wifi.channel --format=lines
wifisnitch fetch network.primary_interface,network.active_tunnel_interface --format=lines
wifisnitch fetch auth.location_authorized,auth.location_permission_state --format=lines
```

Override the default socket for one CLI command:

```bash
wifisnitch --socket /path/to/socket ping
```

## Commands

Built-in commands:

- `ping`
- `version`
- `fields`
- `formats`
- `fetch`

Supported output formats:

- `text`
- `json`
- `lines`

Supported fetch selectors:

- `all`
- namespaces: `wifi`, `network`, and `auth`
- aliases: `<namespace>.` and `<namespace>.*`

Bare namespace selectors are the preferred form. The dotted and wildcard aliases expand the same way.

## Fields

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

Selectors expand to concrete fields before the request is sent to the agent. Unavailable fields may still be omitted from the response at runtime, for example when Wi-Fi fields are blocked by missing location permission.

`fetch ... --format=json` returns typed values, not stringified ones. Booleans stay booleans, integers stay integers, and lists stay lists.

Example JSON payload:

```json
{
  "auth.location_authorized": true,
  "auth.location_permission_state": "authorized_when_in_use",
  "network.active_tunnel_interface": null,
  "network.active_tunnel_interfaces": [],
  "network.captive_portal": false,
  "network.default_gateway": "192.168.1.1",
  "network.dns_servers": ["1.1.1.1", "9.9.9.9"],
  "network.generated_at": "2026-03-17T12:34:56Z",
  "network.internet_reachable": true,
  "network.ipv4_address": "192.168.1.42",
  "network.ipv6_address": "fe80::1234",
  "network.primary_interface": "en0",
  "network.primary_interface_is_tunnel": false,
  "wifi.bssid": "aa:bb:cc:dd:ee:ff",
  "wifi.channel": 44,
  "wifi.channel_band": "5ghz",
  "wifi.channel_width": "80mhz",
  "wifi.country_code": "CH",
  "wifi.hardware_address": "11:22:33:44:55:66",
  "wifi.interface": "en0",
  "wifi.interface_changed_at": "2026-03-17T12:34:56Z",
  "wifi.interface_mode": "station",
  "wifi.link_quality": 68,
  "wifi.noise": -90,
  "wifi.phy_mode": "802.11ax",
  "wifi.power": true,
  "wifi.roaming": false,
  "wifi.rssi": -63,
  "wifi.security": "wpa3_personal",
  "wifi.service_active": true,
  "wifi.snr": 27,
  "wifi.ssid": "ExampleWiFi",
  "wifi.ssid_changed_at": "2026-03-17T12:30:00Z",
  "wifi.tx_rate": 780
}
```

## Troubleshooting

Quick checks:

```bash
brew services list | grep wifisnitch
pgrep -fl WiFiSnitch
wifisnitch ping
wifisnitch version
```

Useful logs:

```bash
tail -n 200 ~/Library/Logs/Homebrew/wifisnitch/*.log
```

Common cases:

- If `wifisnitch ping` fails, the agent is usually not running, was blocked by macOS, or never finished startup.
- If `wifi.*` fields fail, location permission is usually denied, restricted, or not yet granted.
- If manual launch works but `brew services` does not, restart the service and compare logs.
- If two instances are fighting, stop the service, kill manual copies, and start cleanly again.

Clean restart:

```bash
brew services stop wifisnitch
pkill -x WiFiSnitch || true
brew services start wifisnitch
wifisnitch ping
```

## Lua Examples

Show the current Wi-Fi name:

```lua
local handle = io.popen("wifisnitch fetch wifi.ssid --format=text")
local output = handle and handle:read("*a") or ""
if handle then handle:close() end

local ssid = output:gsub("^%s+", ""):gsub("%s+$", "")
if ssid == "" then
  ssid = "WiFi"
end

print(ssid)
```

Read Wi-Fi plus tunnel info:

```lua
local handle = io.popen(
  "wifisnitch fetch wifi.ssid,network.active_tunnel_interface,network.primary_interface_is_tunnel --format=lines"
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

```bash
swift build
swift build -c release
make bundle
make run
make stop
```

Run the packaged app:

```bash
open dist/WiFiSnitch.app
```

## License

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.

