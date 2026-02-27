cask "blink-reminder" do
  version "1.0.7"
  sha256 "ed33399144e8489785aa8ead8c9e43029d17843bbadaae878ea7c3f2fcbea6c0"

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
