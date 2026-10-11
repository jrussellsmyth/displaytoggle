cask "displaytoggle" do
  version "1.0.0"
  sha256 :no_check # Replace with sha256 of the release DMG (e.g. `shasum -a 256 DisplayToggle.dmg`)

  url "https://github.com/jrussellsmyth/displaytoggle/releases/download/v#{version}/DisplayToggle.dmg"
  name "DisplayToggle"
  desc "Lightweight macOS menu bar tool to quickly toggle the primary display"
  homepage "https://github.com/jrussellsmyth/displaytoggle"

  depends_on macos: ">= :sequoia"

  app "DisplayToggle.app"

  zap trash: [
    "~/Library/Preferences/com.displaytoggle.DisplayToggleApp.plist",
  ]
end
