APP_NAME=WiFiSnitch
APP_TARGET=.build/release/WiFiSnitchAgent
CLI_TARGET=.build/release/wifisnitchctl
APP_BUNDLE=dist/$(APP_NAME).app
APP_BIN=$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
CLI_BIN=dist/wifisnitchctl
PLIST=$(APP_BUNDLE)/Contents/Info.plist

.PHONY: build app cli bundle run clean

build:
	swift build -c release

app: build

cli: build

bundle: build
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp $(APP_TARGET) $(APP_BIN)
	chmod +x $(APP_BIN)
	/usr/bin/plutil -create xml1 $(PLIST)
	/usr/bin/plutil -replace CFBundleName -string $(APP_NAME) $(PLIST)
	/usr/bin/plutil -replace CFBundleDisplayName -string $(APP_NAME) $(PLIST)
	/usr/bin/plutil -replace CFBundleIdentifier -string com.example.wifisnitch $(PLIST)
	/usr/bin/plutil -replace CFBundleVersion -string 1.0.0 $(PLIST)
	/usr/bin/plutil -replace CFBundleShortVersionString -string 1.0.0 $(PLIST)
	/usr/bin/plutil -replace CFBundleExecutable -string $(APP_NAME) $(PLIST)
	/usr/bin/plutil -replace CFPackageType -string APPL $(PLIST)
	/usr/bin/plutil -replace LSUIElement -bool YES $(PLIST)
	/usr/bin/plutil -replace NSLocationWhenInUseUsageDescription -string "WiFiSnitch needs location access to read the current Wi-Fi SSID." $(PLIST)

	cp $(CLI_TARGET) $(CLI_BIN)
	chmod +x $(CLI_BIN)

run: bundle
	open $(APP_BUNDLE)

clean:
	rm -rf .build dist
