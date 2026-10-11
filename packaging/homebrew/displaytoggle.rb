cask "displaytoggle" do
  version "1.0.0"
  # Replace with sha256 checksum of the release DisplayToggle.dmg (e.g. from DisplayToggle.dmg.sha256)
  sha256 "REPLACE_WITH_RELEASE_DMG_SHA256"

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
