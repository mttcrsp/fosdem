#!/bin/bash

# Make sure all depedencies were installed
if ! hash tuist 2>/dev/null; then
	echo "You need to install Tuist to continue

	https://github.com/tuist/tuist#install-%EF%B8%8F
	"
	exit 1
fi

if ! hash swiftformat 2>/dev/null; then
	echo "You need to install SwiftFormat to continue

	https://github.com/nicklockwood/SwiftFormat#command-line-tool
	"
	exit 1
fi

PROJECT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

( cd $PROJECT_DIR; tuist generate &>/dev/null )
