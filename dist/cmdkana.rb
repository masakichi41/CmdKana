# Homebrew Cask テンプレート
# -------------------------------------------------------------------
# リリース時に CI (.github/workflows/release.yml) がこのファイルの
# version と sha256 を差し替え、tap リポジトリ（masakichi41/homebrew-tap）の
# Casks/cmdkana.rb へ自動 push します。編集はこのファイルに対して行い、
# tap 側を直接編集しないでください。詳しくは RELEASING.md を参照。
# -------------------------------------------------------------------
cask "cmdkana" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/masakichi41/CmdKana/releases/download/v#{version}/CmdKana-#{version}.dmg"
  name "CmdKana"
  desc "Switches input source by tapping the left or right Command key"
  homepage "https://github.com/masakichi41/CmdKana"

  # 新しい Release が出たら brew upgrade で検知できるようにする。
  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "CmdKana.app"

  uninstall quit: "net.ma41.CmdKana"

  zap trash: [
    "~/Library/Preferences/net.ma41.CmdKana.plist",
  ]

  caveats <<~EOS
    CmdKana はキー監視のために「アクセシビリティ」権限が必要です。
    初回起動時に次の場所で許可してください:
      システム設定 → プライバシーとセキュリティ → アクセシビリティ

    アンインストール後は、上記リストからも手動で削除してください。
  EOS
end
