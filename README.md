# WiFiSnitch

WiFiSnitch is a small macOS background app that exposes Wi-Fi and network tunnel status over a local Unix socket.

It exists because recent macOS versions often hide the current SSID from normal shell scripts. WiFiSnitch runs as a bundled app in user context, requests the required permission, and makes the result available to local tools like SketchyBar.

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
- generic active tunnel detection
- active tunnel interface
- active tunnel interfaces
- primary interface
- IPv4 address
- IPv6 address
- default gateway
- DNS servers
- internet reachability hint
- captive portal hint
- VPN count
- VPN display name
- VPN type
- location authorization state
- location permission state
- local Unix socket API
- small CLI client
- Settings window with start-at-login toggle

## Project layout

- `agent/` — the macOS app target
- `cli/` — the CLI client
- `shared/` — shared socket helpers
- `dist/` — packaged output created by `make bundle`

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

## Run the agent

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

## Stop the agent

If you started the packaged app:

```sh
pkill -f "dist/WiFiSnitch.app/Contents/MacOS/WiFiSnitch"
```

If you started the raw executable:

```sh
pkill WiFiSnitchAgent
```

Or inspect first:

```sh
ps aux | grep WiFiSnitch
```

Then kill by PID:

```sh
kill <pid>
```

## Install from local build

Package the app first:

```sh
make bundle
```

Install the app and CLI:

```sh
mkdir -p ~/.local/bin
cp dist/wifisnitchctl ~/.local/bin/
chmod +x ~/.local/bin/wifisnitchctl

rm -rf /Applications/WiFiSnitch.app
cp -R dist/WiFiSnitch.app /Applications/WiFiSnitch.app
```

Start it:

```sh
open /Applications/WiFiSnitch.app
```

Then test it:

```sh
~/.local/bin/wifisnitchctl status | jq
```

## Permissions

WiFiSnitch needs location permission to read the current Wi-Fi network name.

On first launch, macOS should prompt for permission.

If the permission prompt does not appear or you want to reset it:

```sh
tccutil reset Location com.example.wifisnitch
open /Applications/WiFiSnitch.app
```

Then allow location access in:

**System Settings → Privacy & Security → Location Services**

You can verify the current state with:

```sh
~/.local/bin/wifisnitchctl get auth.location_authorized --format=text
~/.local/bin/wifisnitchctl get auth.location_permission_state --format=text
```

## Start at login

WiFiSnitch includes a Settings window with a **Start at login** toggle.

Open the app settings from the app while it is running. The toggle uses `SMAppService` and does not require you to create your own LaunchAgent plist.

This means you usually do not need a custom `~/Library/LaunchAgents/*.plist` file.

## Socket

WiFiSnitch listens on:

```text
~/Library/Caches/wifisnitch/wifisnitch.sock
```

You can override the socket path with the `WIFISNITCH_SOCKET` environment variable.

## CLI usage

Show help:

```sh
./dist/wifisnitchctl --help
```

Common examples:

```sh
./dist/wifisnitchctl
./dist/wifisnitchctl ssid
./dist/wifisnitchctl status
./dist/wifisnitchctl status --format=lines
./dist/wifisnitchctl wifi
./dist/wifisnitchctl network
./dist/wifisnitchctl services
./dist/wifisnitchctl auth
./dist/wifisnitchctl signal
./dist/wifisnitchctl debug
./dist/wifisnitchctl get wifi.ssid --format=text
./dist/wifisnitchctl get wifi.ssid,wifi.bssid,wifi.channel --format=lines
./dist/wifisnitchctl get wifi.snr,wifi.link_quality --format=lines
./dist/wifisnitchctl get network.vpn_display_name,network.vpn_type --format=lines
./dist/wifisnitchctl get network.ipv4_address,network.default_gateway --format=lines
./dist/wifisnitchctl get services.connected_details --format=text
./dist/wifisnitchctl ping
./dist/wifisnitchctl version
./dist/wifisnitchctl fields
./dist/wifisnitchctl formats
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
- `GET_SERVICES`
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
- `GET network.ipv4_address`
- `GET network.ipv6_address`
- `GET network.default_gateway`
- `GET network.dns_servers`
- `GET network.internet_reachable`
- `GET network.captive_portal`
- `GET network.vpn_count`
- `GET network.vpn_display_name`
- `GET network.vpn_type`
- `GET services.connected`
- `GET services.connected_count`
- `GET services.names`
- `GET services.connected_names`
- `GET services.connected_display_names`
- `GET services.connected_types`
- `GET services.connected_interfaces`
- `GET services.connected_details`
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
    "active_tunnel_interface": "utun6",
    "active_tunnel_interfaces": ["utun6"],
    "captive_portal": false,
    "default_gateway": "192.168.1.1",
    "dns_servers": ["1.1.1.1", "9.9.9.9"],
    "internet_reachable": true,
    "ipv4_address": "192.168.1.42",
    "ipv6_address": "fe80::1234",
    "primary_interface": "en0",
    "vpn_count": 1,
    "vpn_display_name": "Mullvad",
    "vpn_type": "tunnel"
  },
  "services": [
    {
      "connected": true,
      "display_name": "Mullvad",
      "interface": "utun6",
      "name": "Mullvad",
      "status": "Connected",
      "type": "tunnel"
    }
  ],
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

- `network.active_tunnel_interface` is a convenience field for the first active tunnel-like interface.
- `network.active_tunnel_interfaces` contains all currently visible tunnel-like interfaces.
- `network.internet_reachable` is a cheap reachability hint, not an active probe.
- `network.captive_portal` is a cheap heuristic, not a captive portal login check.
- `services.connected_details` is a compact line-oriented summary field.
- `GET_DEBUG` exposes extra internal state useful for troubleshooting.

## SketchyBar example

Show the current Wi-Fi name:

```lua
sbar.exec(os.getenv("HOME") .. "/.local/bin/wifisnitchctl get wifi.ssid --format=text", function(output)
  local ssid = output:gsub("^%s+", ""):gsub("%s+$", "")
  if ssid == "" or ssid == "EMPTY" then
    ssid = "WiFi"
  end
end)
```

Show Wi-Fi plus VPN info:

```lua
sbar.exec(
  os.getenv("HOME") .. "/.local/bin/wifisnitchctl get wifi.ssid,network.vpn_display_name,network.vpn_type --format=lines",
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
- `GET_SERVICES` returns the derived services payload.
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
