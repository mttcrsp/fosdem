declare -a arr=("iPad (7th generation)" "iPad Pro (11-inch) (2nd generation)" "iPad Pro (12.9-inch) (4th generation)") # "iPhone 8" "iPhone 8 Plus" "iPhone 11 Pro" "iPhone 11 Pro Max"

for i in "${arr[@]}"
do
  xcrun simctl boot "$i"
  xcrun simctl status_bar "$i" override --cellularBars 4 --time "9:41" --batteryLevel 100
  xcodebuild -scheme FOSDEM -sdk iphonesimulator -destination "name=$i" -only-testing UITests/ScreenshotTests/testScreenshots -derivedDataPath ./Build/ test | xcpretty
  xcparse screenshots $(find build/Logs/Test/*.xcresult/ | head -n 1) screenshots/
  rm -rf ./Build
  xcrun simctl shutdown "$i"
done
