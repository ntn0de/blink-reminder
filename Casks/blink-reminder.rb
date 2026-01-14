cask "blink-reminder" do
  version "1.0.5"
  sha256 "d190177e81edfa1ed56dd00537e81e212fc5e01bf5c063830886575de6042c4e"

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
