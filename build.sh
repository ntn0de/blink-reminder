#!/bin/bash

APP_NAME="BlinkReminder"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
VERSION="${1:-1.0.5}"

# Create directory structure
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Generate Icon if missing
if [ ! -f "BlinkReminder.icns" ]; then
    echo "Generating Icon..."
    # Generate base 1024x1024 icon
    swift GenerateIcon.swift
    
    if [ -f "icon.png" ]; then
        mkdir -p BlinkReminder.iconset
        
        # Standard sizes
        sips -z 16 16     icon.png --out BlinkReminder.iconset/icon_16x16.png
        sips -z 32 32     icon.png --out BlinkReminder.iconset/icon_16x16@2x.png
        sips -z 32 32     icon.png --out BlinkReminder.iconset/icon_32x32.png
        sips -z 64 64     icon.png --out BlinkReminder.iconset/icon_32x32@2x.png
        sips -z 128 128   icon.png --out BlinkReminder.iconset/icon_128x128.png
        sips -z 256 256   icon.png --out BlinkReminder.iconset/icon_128x128@2x.png
        sips -z 256 256   icon.png --out BlinkReminder.iconset/icon_256x256.png
        sips -z 512 512   icon.png --out BlinkReminder.iconset/icon_256x256@2x.png
        sips -z 512 512   icon.png --out BlinkReminder.iconset/icon_512x512.png
        sips -z 1024 1024 icon.png --out BlinkReminder.iconset/icon_512x512@2x.png
        
        # Convert to icns
        iconutil -c icns BlinkReminder.iconset
        
        # Cleanup
        rm icon.png
        rm -rf BlinkReminder.iconset
        echo "Icon generated successfully."
    else
        echo "Warning: GenerateIcon.swift failed or did not produce icon.png"
    fi
fi

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
    <string>$VERSION</string>
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

