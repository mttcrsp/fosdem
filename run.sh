#!/bin/bash

# Make sure all depedencies were installed
if ! hash xcodegen 2>/dev/null; then
	echo "You need to install XcodeGen to continue

	https://github.com/yonaskolb/XcodeGen/#installing
	"
	exit 1
fi

if ! hash swiftformat 2>/dev/null; then
	echo "You need to install SwiftFormat to continue

	https://github.com/nicklockwood/SwiftFormat#command-line-tool
	"
	exit 1
fi

if ! hash license-plist 2>/dev/null; then
	echo "You need to install LicensePlist to continue

	https://github.com/mono0926/LicensePlist#homebrew-also-recommended
	"
	exit 1
fi

PROJECT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

# Generate Xcode project via Xcodegen
( cd $PROJECT_DIR; xcodegen &>/dev/null )

# Generate licences files via LicensePlist
( cd $PROJECT_DIR \
	license-plist \
		--output-path Resources/Licenses \
		--prefix Licenses \
		--suppress-opening-directory \
		&>/dev/null )

