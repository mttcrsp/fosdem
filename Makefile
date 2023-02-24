export PATH := /opt/homebrew/bin/:$(PATH)

generate_project:
	xcodegen

run_mockolo:
	if [ ! -f "App/Mocks" ]; then \
		mkdir App/Mocks/ && \
		touch App/Mocks/Mockolo.swift; \
	fi; \
	mockolo \
		--sourcedirs App/Sources/ \
		--destination App/Mocks/Mockolo.swift \
		--testable-imports Fosdem \
		--mock-final \
		--enable-args-history

run_swiftformat::
	if [ -z "$(IS_CI)" ]; then \
		swiftformat .; \
	fi

run_swiftgen:
	if [ ! -f "App/Sources/Derived" ]; then \
		mkdir App/Sources/Derived; \
	fi; \
	swiftgen run strings App/Resources/* \
		-t structured-swift5 \
		-o App/Sources/Derived/Strings.swift
	swiftgen run xcassets App/Resources/* \
		-t swift5 \
		-o App/Sources/Derived/Assets.swift

test:
	xcodebuild \
		-scheme FOSDEM \
		-destination 'platform=iOS Simulator,OS=16.2,name=iPhone 8 Plus' \
		test | xcbeautify
