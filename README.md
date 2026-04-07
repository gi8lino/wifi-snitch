# WiFiSnitch

WiFiSnitch is a small macOS helper app that exposes Wi-Fi and network status over a local Unix socket.

It ships with a small CLI client, `wifisnitch`, so the data can be queried easily from shell scripts, status bars like Easybar, SketchyBar, and other local automation.

It exists because recent macOS versions often hide the current SSID and related Wi-Fi details from normal shell scripts. WiFiSnitch runs in the user session, requests the required location permission, and makes the result available to local tools in a simple, script-friendly way.

Internally, WiFiSnitch is intentionally thin. It starts EasyBar’s network-agent core on a WiFiSnitch-specific socket and exposes that agent through the bundled `wifisnitch` CLI.

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
- startup logging and duplicate-instance protection

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
open "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
```

Then allow location access in:

**System Settings → Privacy & Security → Location Services**

You can verify the current state with:

```bash
wifisnitch fetch auth.location_authorized --format=text
wifisnitch fetch auth.location_permission_state --format=text
```

When location access is unavailable:

- `wifi.*` fields are unavailable
- `network.*` and `auth.*` fields still work
- `fetch` returns only the fields the network agent can currently provide
- if the agent rejects a fetch request, the CLI prints the returned error message

## Environment

WiFiSnitch supports these environment variables:

- `WIFISNITCH_SOCKET`
  Override the Unix socket path used by the WiFiSnitch agent and CLI.

The bundled agent also sets EasyBar’s network-agent socket override internally so the EasyBar network core listens on the WiFiSnitch socket path.

Default:

```text
socket: /tmp/wifi-snitch/wifi-snitch.sock
```

Examples:

```bash
WIFISNITCH_SOCKET=/path/to/wifi-snitch.sock wifisnitch ping
WIFISNITCH_SOCKET=/tmp/test.sock open /Applications/WiFiSnitch.app
```

## Usage

Show help:

```bash
wifisnitch --help
```

Common examples:

```bash
wifisnitch ping
wifisnitch version
wifisnitch fields
wifisnitch formats
wifisnitch fetch wifi.ssid --format=text
wifisnitch fetch wifi.ssid,wifi.bssid,wifi.channel --format=lines
wifisnitch fetch wifi.hardware_address,wifi.interface_mode --format=lines
wifisnitch fetch network.primary_interface,network.active_tunnel_interface --format=lines
wifisnitch fetch network.primary_interface_is_tunnel --format=text
wifisnitch fetch auth.location_authorized,auth.location_permission_state --format=lines
```

The default socket path is:

```text
/tmp/wifi-snitch/wifi-snitch.sock
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
- `fetch`

Field queries use:

- `fetch <field>`
- `fetch <field1>,<field2>,...`

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

`fetch ... --format=json` returns typed JSON values, not stringified ones.

Examples:

- booleans stay booleans
- integers stay integers
- DNS and tunnel interface lists stay arrays

Example:

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

Notes:

- `network.active_tunnel_interface` is a convenience field for the primary tunnel-like interface when the primary interface itself looks like a tunnel.
- `network.active_tunnel_interfaces` contains all currently visible tunnel-like interfaces.
- `network.internet_reachable` is a cheap reachability hint, not an active probe.
- `network.captive_portal` is a cheap heuristic, not a captive portal login check.
- `version` returns a structured version payload from the underlying network agent.
- `fields` lists the field names supported by `fetch`.
- `formats` lists the supported CLI output formats.

## Troubleshooting

When something goes wrong, first check whether WiFiSnitch is running once, whether the service is healthy, and whether permission state is what you expect.

### Quick checks

Check the Homebrew service:

```bash
brew services list | grep wifisnitch
```

Check running processes:

```bash
pgrep -fl WiFiSnitch
pgrep -fl wifisnitch
```

Check the CLI against the local agent:

```bash
wifisnitch ping
wifisnitch version
```

If `ping` fails, the agent is probably not running, was blocked by macOS, or never finished startup.

### Logs

WiFiSnitch logs useful startup and permission information. If you enabled file logging, inspect the configured log directory.

If you installed with Homebrew services, also inspect service logs:

```bash
tail -n 200 ~/Library/Logs/Homebrew/wifisnitch/*.log
```

If your machine writes Homebrew logs elsewhere, use `brew services info wifisnitch` to locate them.

### Common problems and fixes

#### WiFiSnitch is already running

WiFiSnitch uses a single-instance guard. If another instance already holds the startup lock, the second one exits and logs a warning.

Detect duplicates with:

```bash
pgrep -fl WiFiSnitch
```

If you accidentally launched both the Homebrew service and a manual instance, stop the extra one and restart cleanly:

```bash
pkill -x WiFiSnitch || true
brew services restart wifisnitch
```

If you are testing local builds, stop the service first so you do not mix manual and service runs.

#### `wifisnitch ping` fails

Check whether the service is actually running:

```bash
brew services list | grep wifisnitch
```

Try opening the app directly:

```bash
open "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
```

Then retry:

```bash
wifisnitch ping
```

If the direct app launch works but the service does not, restart the service:

```bash
brew services restart wifisnitch
```

#### Permission stays unresolved or Wi-Fi fields are denied

Check the permission state directly:

```bash
wifisnitch fetch auth.location_authorized --format=text
wifisnitch fetch auth.location_permission_state --format=text
```

If the state is not what you expect, reset the permission and relaunch:

```bash
tccutil reset Location io.github.gi8lino.wifisnitch
open "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
```

Then allow location access in System Settings and retry your field queries.

#### Wi-Fi-specific fetches fail

That usually means Location Services access is denied, restricted, or not yet granted.

Useful checks:

```bash
wifisnitch fetch wifi.ssid --format=text
wifisnitch fetch auth.location_permission_state --format=text
```

Expected behavior:

- `wifi.*` fields depend on location access
- `network.*` and `auth.*` fields still work

If you changed permission settings, restart WiFiSnitch:

```bash
brew services restart wifisnitch
```

#### Service and manual app launch behave differently

This usually means one of these:

- different environment
- duplicate instances
- stale permission state in an older process
- quarantine or launch blocking in one path but not the other

Compare the two by:

```bash
brew services stop wifisnitch
open "$(brew --prefix)/opt/wifisnitch/libexec/WiFiSnitch.app"
wifisnitch ping
```

If that works, the service path is the issue. Restart the service and inspect logs.

#### Socket or stale process issues

If the app was interrupted or multiple instances were launched, restarting cleanly usually fixes it:

```bash
brew services stop wifisnitch
pkill -x WiFiSnitch || true
brew services start wifisnitch
```

Then verify:

```bash
wifisnitch ping
wifisnitch version
```

### Reset and recover

A good clean recovery sequence is:

```bash
brew services stop wifisnitch
pkill -x WiFiSnitch || true
brew services start wifisnitch
wifisnitch ping
```

If permission still looks wrong after that, also reset Location Services permission and relaunch the app once manually.

## Lua example

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
