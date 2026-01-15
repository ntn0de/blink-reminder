cask "blink-reminder" do
      version "1.0.6"  
      sha256 "1033d2b882bc6ca4ea31fa0303da68f3775e69abf03acd4a8dcbfb97dd3004f0"

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

  caveats <<~EOS
    If BlinkReminder is already running, you may need to quit it from the menu bar
    and relaunch it for the changes to take effect.
  EOS
end
