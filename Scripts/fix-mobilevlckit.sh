#!/bin/bash

SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
PROJECT_DIR=$SCRIPT_DIR/..

# Workaround for missing Info.plist file in MobileVLCKit
cp \
	$PROJECT_DIR/Resources/Info-MobileVLCKit.plist \
	$PROJECT_DIR/Carthage/Build/iOS/MobileVLCKit.framework/

mv \
	$PROJECT_DIR/Carthage/Build/iOS/MobileVLCKit.framework/Info-MobileVLCKit.plist \
	$PROJECT_DIR/Carthage/Build/iOS/MobileVLCKit.framework/Info.plist
