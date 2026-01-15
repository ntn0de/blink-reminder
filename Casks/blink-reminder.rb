cask "blink-reminder" do
      version "1.0.6"  
      sha256 "e725289856dc71421d24d0a502c8a736234bb4373d9a27fa5509f9b8d163da50"

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
