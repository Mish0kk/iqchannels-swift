# iqchannels-swift
.PHONY: build test lint verify doctor

SCHEME := iqchannels-swift
SIM ?= iPhone 15

build:
	xcodebuild -quiet -scheme $(SCHEME) -destination 'generic/platform=iOS Simulator' build

test:
	xcodebuild -quiet test -scheme $(SCHEME) -destination 'platform=iOS Simulator,name=$(SIM)'

lint:
	@command -v swiftlint >/dev/null 2>&1 || { echo "swiftlint not installed: brew install swiftlint (or run /init-swift)"; exit 1; }
	swiftlint lint --strict

verify: build test

doctor:
	bash ../scripts/doctor.sh --swift
