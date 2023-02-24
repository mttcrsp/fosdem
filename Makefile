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
	if [ ! -f "Modules/MapFeature/Mocks" ]; then \
		mkdir Modules/MapFeature/Mocks/ && \
		touch Modules/MapFeature/Mocks/Mockolo.swift; \
	fi; \
	mockolo \
		--sourcedirs Modules/MapFeature/Sources/ \
		--destination Modules/MapFeature/Mocks/Mockolo.swift \
		--testable-imports MapFeature \
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
	swiftgen run xcassets App/Resources/* ; \
		-t swift5 \
		-o App/Sources/Derived/Assets.swift ; \
	if [ ! -f "Modules/MapFeature/Sources/Derived" ]; then \
		mkdir Modules/MapFeature/Sources/Derived; \
	fi; \
	swiftgen run strings Modules/MapFeature/Resources/* \
		-t structured-swift5 \
		-o Modules/MapFeature/Sources/Derived/Strings.swift \
		--param publicAccess ;

test:
	xcodebuild \
		-scheme FOSDEM \
		-destination 'platform=iOS Simulator,OS=16.2,name=iPhone 8 Plus' \
		test | xcbeautify
