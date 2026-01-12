cask "blink-reminder" do
  version "1.0"
  sha256 "REPLACE_WITH_SHA256_FROM_DIST_SH"

  url "https://github.com/ntn0de/blink-reminder/releases/download/v#{version}/BlinkReminder.zip"
  name "BlinkReminder"
  desc "Eye strain reduction tool"
  homepage "https://github.com/ntn0de/blink-reminder"

  app "BlinkReminder.app"

  uninstall quit: "com.agamtech.blinkreminder"

  zap trash: [
    "~/Library/Application Support/com.agamtech.blinkreminder",
    "~/Library/Preferences/com.agamtech.blinkreminder.plist",
  ]
end
