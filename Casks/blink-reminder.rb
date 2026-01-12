cask "blink-reminder" do
  version "1.0.1"
  sha256 "d83dc998c9d35a42bce61c0227b1207bb5d382b704d8150dea4fb8d008cfb3c2"

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
