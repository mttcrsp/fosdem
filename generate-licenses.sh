if ! hash license-plist 2>/dev/null; then
  echo "You need to install LicensePlist to continue

  https://github.com/mono0926/LicensePlist#homebrew-also-recommended
  "
  exit 1
fi

PROJECT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

( cd $PROJECT_DIR \
  license-plist \
    --output-path Resources/Licenses \
    --prefix Licenses \
    --suppress-opening-directory \
    &>/dev/null )
