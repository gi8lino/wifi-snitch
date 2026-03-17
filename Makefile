APP_NAME := WiFiSnitch
APP_TARGET := .build/release/WiFiSnitchAgent
CLI_TARGET := .build/release/wifisnitchctl
APP_BUNDLE := dist/$(APP_NAME).app
APP_BIN := $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
CLI_BIN := dist/wifisnitchctl
PLIST := $(APP_BUNDLE)/Contents/Info.plist

VERSION_PREFIX ?= v
LATEST_TAG := $(shell git tag --list '$(VERSION_PREFIX)*' --sort=-v:refname | head -n 1)
VERSION := $(shell if [ -n "$(LATEST_TAG)" ]; then printf '%s\n' "$(LATEST_TAG)" | sed 's/^$(VERSION_PREFIX)//'; else printf '%s\n' '0.0.0'; fi)

.PHONY: prepare-version build app cli bundle run clean patch minor major tag push help

##@ Build

prepare-version:
	@printf '%s\n' 'import Foundation' > shared/BuildInfo.swift
	@printf '%s\n' '' >> shared/BuildInfo.swift
	@printf '%s\n' '/// Build-time version information shared by the app and CLI.' >> shared/BuildInfo.swift
	@printf '%s\n' 'public enum BuildInfo {' >> shared/BuildInfo.swift
	@printf '%s\n' '    /// The application version embedded at build time.' >> shared/BuildInfo.swift
	@printf '%s\n' '    public static let appVersion = "$(VERSION)"' >> shared/BuildInfo.swift
	@printf '%s\n' '}' >> shared/BuildInfo.swift

build: prepare-version
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
	/usr/bin/plutil -replace CFBundleVersion -string $(VERSION) $(PLIST)
	/usr/bin/plutil -replace CFBundleShortVersionString -string $(VERSION) $(PLIST)
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

##@ Tagging

patch: ## Create a new patch release (x.y.Z+1)
	@NEW_VERSION=$$(printf '%s\n' "$(VERSION)" | awk -F. '{printf "%d.%d.%d", $$1, $$2, $$3+1}') && \
	git tag "$(VERSION_PREFIX)$${NEW_VERSION}" && \
	echo "Tagged $(VERSION_PREFIX)$${NEW_VERSION}"

minor: ## Create a new minor release (x.Y+1.0)
	@NEW_VERSION=$$(printf '%s\n' "$(VERSION)" | awk -F. '{printf "%d.%d.0", $$1, $$2+1}') && \
	git tag "$(VERSION_PREFIX)$${NEW_VERSION}" && \
	echo "Tagged $(VERSION_PREFIX)$${NEW_VERSION}"

major: ## Create a new major release (X+1.0.0)
	@NEW_VERSION=$$(printf '%s\n' "$(VERSION)" | awk -F. '{printf "%d.0.0", $$1+1}') && \
	git tag "$(VERSION_PREFIX)$${NEW_VERSION}" && \
	echo "Tagged $(VERSION_PREFIX)$${NEW_VERSION}"

tag: ## Show latest tag
	@echo "Latest tag: $(LATEST_TAG)"
	@echo "Version: $(VERSION)"

push: ## Push tags to remote
	git push --tags

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)
