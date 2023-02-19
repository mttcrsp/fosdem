export PATH := /opt/homebrew/bin/:$(PATH)

generate_project:
	xcodegen

run_mockolo:
	if [ ! -f "Mocks" ]; then \
		mkdir Mocks/ && \
		touch Mocks/Mockolo.swift; \
	fi; \
	mockolo \
		--sourcedirs Sources/ \
		--destination Mocks/Mockolo.swift \
		--testable-imports Fosdem \
		--mock-final \
		--enable-args-history

run_swiftformat::
	if [ -z "$(IS_CI)" ]; then \
		swiftformat .; \
	fi

run_swiftgen:
	if [ ! -f "Sources/Derived" ]; then \
		mkdir Sources/Derived; \
	fi; \
	swiftgen run strings Resources/* \
		-t structured-swift5 \
		-o Sources/Derived/Strings.swift
	swiftgen run xcassets Resources/* \
		-t swift5 \
		-o Sources/Derived/Assets.swift

test:
	xcodebuild \
		-scheme FOSDEM \
		-destination 'platform=iOS Simulator,OS=16.2,name=iPhone 8 Plus' \
		test | xcbeautify
