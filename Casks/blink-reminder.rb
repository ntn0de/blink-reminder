cask "blink-reminder" do
  version "1.0.3"
  sha256 "b59b37e87368eeba1f25f73fd0261ac555f03aab355758c16c55d6c03aa89dfa"

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
