cask "cmdkana" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/masakichi41/CmdKana/releases/download/v#{version}/CmdKana-#{version}.dmg"
  name "CmdKana"
  desc "Switches input source by tapping the left or right Command key"
  homepage "https://github.com/masakichi41/CmdKana"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "CmdKana.app"

  uninstall quit: "net.ma41.CmdKana"

  zap trash: [
    "~/Library/Preferences/net.ma41.CmdKana.plist",
  ]
end
