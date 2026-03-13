APP_BIN=agent/WiFiSnitch.app/Contents/MacOS/WiFiSnitch
CLI_BIN=cli/wifisnitchctl
AGENT_SRC=agent/WiFiSnitch.swift
CLI_SRC=cli/wifisnitchctl.swift

.PHONY: build app cli clean run

build: app cli

app:
	swiftc -O \
		-framework Cocoa \
		-framework CoreLocation \
		-framework CoreWLAN \
		$(AGENT_SRC) \
		-o $(APP_BIN)
	chmod +x $(APP_BIN)

cli:
	swiftc -O $(CLI_SRC) -o $(CLI_BIN)
	chmod +x $(CLI_BIN)

run: build
	open agent/WiFiSnitch.app

clean:
	rm -f $(APP_BIN)
	rm -f $(CLI_BIN)
