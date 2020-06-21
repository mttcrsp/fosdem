declare -a arr=("iPhone 8" "iPhone 8 Plus" "iPhone 11 Pro" "iPhone 11 Pro Max" "iPad (7th generation)" "iPad Pro (11-inch) (2nd generation)" "iPad Pro (12.9-inch) (4th generation)")

for i in "${arr[@]}"
do
  xcrun simctl boot "$i"
  xcrun simctl status_bar "$i" override \
    --batteryLevel 100 \
    --cellularBars 4 \
    --time "9:41"
done

xcodebuild \
  -scheme FOSDEM \
  -sdk iphonesimulator \
  -derivedDataPath ./Build/ \
  -destination "name=iPhone 8" \
  -destination "name=iPhone 8 Plus" \
  -destination "name=iPhone 11 Pro" \
  -destination "name=iPhone 11 Pro Max" \
  -destination "name=iPad (7th generation)" \
  -destination "name=iPad Pro (11-inch) (2nd generation)" \
  -destination "name=iPad Pro (12.9-inch) (4th generation)" \
  -only-testing UITests/ScreenshotTests/testScreenshots \
  test | xcpretty

find ./Build/Logs/Test -name \*.xcresult -maxdepth 1 -exec xcparse screenshots {} ./Screenshots \;

for i in "${arr[@]}"
do
  xcrun simctl shutdown "$i"
done
