#!/bin/bash

APP_NAME="BlinkReminder"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Create directory structure
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy Icon
if [ -f "BlinkReminder.icns" ]; then
    cp "BlinkReminder.icns" "$RESOURCES/AppIcon.icns"
fi

# Create Info.plist
cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.agamtech.blinkreminder</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Compile the Swift code
swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -target arm64-apple-macosx12.0 \
    -parse-as-library \
    BlinkReminder.swift \
    -o "$MACOS/$APP_NAME"

# Ad-hoc codesign to help with permissions/notifications
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Build complete: $APP_BUNDLE"

