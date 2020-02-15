#!/bin/bash

# Make sure all depedencies were installed
if ! hash xcodegen 2>/dev/null; then
	echo "You need to install XcodeGen to continue

	https://github.com/yonaskolb/XcodeGen/#installing
	"
	exit 1
fi

if ! hash carthage 2>/dev/null; then
	echo "You need to install Carthage to continue

	https://github.com/Carthage/Carthage#installing-carthage
	"
	exit 1
fi

PROJECT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

# Download all dependencies via Carthage
if [ ! -d $PROJECT_DIR/Carthage ]; then
	(cd $PROJECT_DIR; carthage update --platform ios)
fi

# Generate Xcode project via Xcodegen
(cd $PROJECT_DIR; xcodegen)

# Workaround for missing Info.plist file in MobileVLCKit
cp \
	$PROJECT_DIR/Resources/Info-MobileVLCKit.plist \
	$PROJECT_DIR/Carthage/Build/iOS/MobileVLCKit.framework/

mv \
	$PROJECT_DIR/Carthage/Build/iOS/MobileVLCKit.framework/Info-MobileVLCKit.plist \
	$PROJECT_DIR/Carthage/Build/iOS/MobileVLCKit.framework/Info.plist
