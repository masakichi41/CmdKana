# Homebrew Cask テンプレート
# -------------------------------------------------------------------
# これは tap リポジトリ（masakichi41/homebrew-tap）の Casks/cmdkana.rb に
# 置くファイルの雛形です。本体リポジトリでは配布しません（管理用の控え）。
#
# リリースごとに version と sha256 を更新します。
# sha256 は Release ページ本文の「Homebrew Cask 用 SHA-256」に出力されます。
# 詳しい手順は RELEASING.md を参照してください。
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
