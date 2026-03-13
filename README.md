# WiFiSnitch

WiFiSnitch is a small macOS agent that exposes Wi-Fi and generic network tunnel status over a local Unix socket.

It exists because recent macOS versions often hide the current SSID from normal shell scripts. WiFiSnitch runs as a bundled app in user context, requests the required permission, and makes the result available to local tools like SketchyBar.

## Features

- current SSID
- Wi-Fi interface name
- Wi-Fi power state
- RSSI
- noise
- transmit rate
- generic active tunnel detection
- active tunnel interface
- location authorization state
- local Unix socket API
- small CLI client

## Install from release

Download these release assets:

- `WiFiSnitch.app.zip`
- `wifisnitchctl`
- `io.github.gi8lino.wifisnitch.plist`

Unpack the app and move everything into place:

```sh
mkdir -p ~/.local/bin
mkdir -p ~/Library/LaunchAgents

sudo ditto -x -k WiFiSnitch.app.zip /Applications
cp wifisnitchctl ~/.local/bin/
cp io.github.gi8lino.wifisnitch.plist ~/Library/LaunchAgents/
chmod +x ~/.local/bin/wifisnitchctl
```

The LaunchAgent plist assumes the app is installed here:

```text
/Applications/WiFiSnitch.app
```

Load it:

```sh
launchctl bootout gui/$(id -u)/io.github.gi8lino.wifisnitch 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/io.github.gi8lino.wifisnitch.plist
```

Start the app once if needed:

```sh
open /Applications/WiFiSnitch.app
```

Then test it:

```sh
~/.local/bin/wifisnitchctl status | jq
```

## Permissions

WiFiSnitch needs location permission to read the current Wi-Fi network name.

If the permission prompt does not appear or you want to reset it:

```sh
tccutil reset Location io.github.gi8lino.wifisnitch
open /Applications/WiFiSnitch.app
```

Then allow location access in:

**System Settings → Privacy & Security → Location Services**

You can verify the current state with:

```sh
~/.local/bin/wifisnitchctl get auth.location_authorized --format=text
```

## Build from source

Build everything:

```sh
make build
```

Or build manually:

```sh
swiftc agent/*.swift -o agent/WiFiSnitch.app/Contents/MacOS/WiFiSnitch \
  -framework Cocoa \
  -framework CoreLocation \
  -framework CoreWLAN \
  -framework SystemConfiguration
chmod +x agent/WiFiSnitch.app/Contents/MacOS/WiFiSnitch
sudo cp -r agent/WiFiSnitch.app /Applications
pkill -x WiFiSnitch
open /Applications/WiFiSnitch.app

swiftc -O cli/wifisnitchctl.swift -o cli/wifisnitchctl
chmod +x cli/wifisnitchctl
cp cli/wifisnitchctl ~/.local/bin/
```

Then test the client:

```sh
./cli/wifisnitchctl status | jq
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
./cli/wifisnitchctl --help
```

Common examples:

```sh
./cli/wifisnitchctl
./cli/wifisnitchctl ssid
./cli/wifisnitchctl status
./cli/wifisnitchctl status --format=lines
./cli/wifisnitchctl wifi
./cli/wifisnitchctl network
./cli/wifisnitchctl services
./cli/wifisnitchctl signal
./cli/wifisnitchctl get wifi.ssid --format=text
./cli/wifisnitchctl get wifi.ssid,wifi.rssi,wifi.tx_rate --format=lines
./cli/wifisnitchctl get network.active_tunnel_interface --format=text
./cli/wifisnitchctl get network.active_tunnel_interfaces --format=lines
./cli/wifisnitchctl ping
./cli/wifisnitchctl version
./cli/wifisnitchctl fields
./cli/wifisnitchctl formats
./cli/wifisnitchctl debug
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

Field queries:

- `GET wifi.ssid`
- `GET wifi.interface`
- `GET wifi.power`
- `GET wifi.rssi`
- `GET wifi.noise`
- `GET wifi.tx_rate`
- `GET network.primary_interface`
- `GET network.active_tunnel_interface`
- `GET network.active_tunnel_interfaces`
- `GET services.connected`
- `GET services.names`
- `GET services.connected_names`
- `GET services.connected_interfaces`
- `GET auth.location_authorized`

Formats:

- `text`
- `json`
- `lines`

## Output shape

`GET_STATUS` returns a small default payload:

```json
{
  "auth": {
    "location_authorized": true
  },
  "network": {
    "active_tunnel_interface": "utun6",
    "active_tunnel_interfaces": ["utun6"],
    "primary_interface": "utun6"
  },
  "wifi": {
    "interface": "en0",
    "noise": -90,
    "power": true,
    "rssi": -63,
    "ssid": "ExampleWiFi",
    "tx_rate": 780
  }
}
```

Notes:

- `network.active_tunnel_interface` is a convenience field for the primary active tunnel-like interface.
- `network.active_tunnel_interfaces` contains currently visible tunnel-like interfaces.
- `GET_SERVICES` exposes a larger derived service list if you want more detail.
- `GET_DEBUG` exposes extra internal/debug information.

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

Example with generic tunnel detection:

```lua
sbar.exec(
  os.getenv("HOME") .. "/.local/bin/wifisnitchctl get wifi.ssid,network.active_tunnel_interfaces --format=lines",
  function(output)
    -- parse output here
  end
)
```

## Launch at login

`io.github.gi8lino.wifisnitch.plist` is the LaunchAgent definition for macOS.

It starts WiFiSnitch automatically in your logged-in user session, which is important because the app needs to run in user context.

Install it like this:

```sh
mkdir -p ~/Library/LaunchAgents
cp io.github.gi8lino.wifisnitch.plist ~/Library/LaunchAgents/
```

Load it:

```sh
launchctl bootout gui/$(id -u)/io.github.gi8lino.wifisnitch 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/io.github.gi8lino.wifisnitch.plist
```

Unload it:

```sh
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/io.github.gi8lino.wifisnitch.plist
```

## Notes

- WiFiSnitch is an agent app with `LSUIElement`.
- It must run in the logged-in user session.
- The first launch may trigger the macOS location permission prompt.
- The CLI is a thin socket client.
- `GET_SSID` returns `OK <ssid>` or `EMPTY`.
- `GET_STATUS` returns the default compact payload as JSON.
- `GET_SERVICES` returns a larger derived services payload.
- `GET_DEBUG` returns extra internal state useful for troubleshooting.
- `--socket` overrides the socket path for the CLI.
- `WIFISNITCH_SOCKET` overrides the socket path for both the app and the CLI.

## Rebuild

```sh
rm -f cli/wifisnitchctl
rm -f agent/WiFiSnitch.app/Contents/MacOS/WiFiSnitch

swiftc agent/*.swift -o agent/WiFiSnitch.app/Contents/MacOS/WiFiSnitch \
  -framework Cocoa \
  -framework CoreLocation \
  -framework CoreWLAN \
  -framework SystemConfiguration

swiftc -O cli/wifisnitchctl.swift -o cli/wifisnitchctl

chmod +x cli/wifisnitchctl
chmod +x agent/WiFiSnitch.app/Contents/MacOS/WiFiSnitch
```

## License

MIT
