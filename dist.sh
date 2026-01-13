#!/bin/bash
set -e

# Build the app
./build.sh

# Create a zip for distribution
echo "Zipping application..."
rm -f BlinkReminder.zip
zip -r BlinkReminder.zip BlinkReminder.app

# Calculate SHA256
SHASUM=$(shasum -a 256 BlinkReminder.zip | awk '{print $1}')

echo "----------------------------------------"
echo "Distribution package created: BlinkReminder.zip"
echo "SHA256: $SHASUM"
echo "----------------------------------------"
echo "Next steps:"
echo "1. Create a new Release on GitHub."
echo "2. Upload 'BlinkReminder.zip' to the release."
echo "3. Copy the download URL of the zip file."
echo "4. Update 'Casks/blink-reminder.rb' with the URL and the SHA256 above."
