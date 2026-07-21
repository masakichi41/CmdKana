# リリース手順

CmdKana を GitHub Releases（署名・公証済み DMG）と Homebrew Cask で配布するための手順書です。

配布の流れは次のとおりです。

```
git tag v1.0.0 && git push origin v1.0.0
        │
        ▼
 GitHub Actions (.github/workflows/release.yml)
  ├─ Developer ID 証明書を一時キーチェーンへ
  ├─ xcodebuild archive → export（Developer ID 署名）
  ├─ create-dmg で DMG を作成
  ├─ notarytool で公証 → stapler で綴じ込み
  ├─ SHA-256 を計算
  ├─ Release を作成し DMG を添付
  └─ Sparkle appcast を生成し gh-pages へ公開
        │
        ├─▶ アプリ内アップデート: 各 CmdKana が appcast を見て自動更新（Sparkle）
        │
        ▼
 Homebrew tap (masakichi41/homebrew-tap)
  └─ brew install --cask masakichi41/tap/cmdkana
```

ビルド・署名・公証はすべて GitHub Actions（`macos-26` ランナー）上で自動実行されます。手元の Mac で署名作業をする必要はありません。

---

## 前提条件

- **Apple Developer Program（年間 $99）に加入していること。**
  Developer ID Application 証明書と公証（notarization）は、有料の Developer Program でのみ利用できます。

---

## 初回セットアップ（一度だけ）

### A. Developer ID Application 証明書を用意する

配布用アプリの署名に使う証明書です。手元の Mac にあるのは開発用の「Apple Development」証明書なので、配布用の「Developer ID Application」を新しく作ります。

1. Xcode を開き、**Settings → Accounts** で自分の Apple ID を選択
2. **Manage Certificates…** をクリック
3. 左下の **＋** → **Developer ID Application** を選んで作成
   - （Web からでも可: [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates) → ＋ → Developer ID Application）
4. **キーチェーンアクセス.app** を開く
5. 「ログイン」キーチェーン → 「自分の証明書」カテゴリで
   **Developer ID Application: （あなたの名前）** を探す
6. それを右クリック → **書き出す…** → ファイル形式 **個人情報交換 (.p12)** で保存
   - 書き出し時に **パスワードを設定**（このパスワードを後で Secret に登録します）

> 秘密鍵ごと書き出すため、`.p12` は秘密情報です。GitHub Secrets 以外には置かないでください。

`.p12` を base64 文字列に変換してクリップボードへコピー:

```sh
base64 -i ~/Desktop/DeveloperID.p12 | pbcopy
```

→ これが Secret `DEVELOPER_ID_CERT_P12_BASE64` の値になります。

### B. App Store Connect API キーを用意する（公証用）

公証ツール `notarytool` の認証に使います。Apple ID + パスワードより安全で、CI 向けの推奨方式です。

1. [App Store Connect](https://appstoreconnect.apple.com/) → **ユーザーとアクセス** → **統合（Integrations）** タブ → **App Store Connect API**
2. **チーム鍵（Team Keys）** で新しいキーを生成
   - アクセス権（Role）は **Developer** で十分です
3. **`.p8` ファイルをダウンロード**（※ダウンロードは一度きり。無くしたら作り直し）
4. その画面に表示される **Key ID**（10 桁前後）と、上部の **Issuer ID**（UUID 形式）を控える

`.p8` を base64 文字列に変換してクリップボードへコピー:

```sh
base64 -i ~/Downloads/AuthKey_XXXXXXXXXX.p8 | pbcopy
```

→ これが Secret `APPLE_API_KEY_P8_BASE64` の値になります。

### C. Team ID を確認する

[developer.apple.com/account](https://developer.apple.com/account) → **Membership details** に表示される **Team ID**（10 桁の英数字）を控えます。
これが Secret `APPLE_TEAM_ID` の値です。

> ⚠️ ステップ A で作った証明書と同じチームの Team ID を使ってください。

### D. GitHub Secrets を登録する

リポジトリの **Settings → Secrets and variables → Actions → New repository secret** で、以下の 7 つを登録します。

| Secret 名 | 値 | 取得元 |
|---|---|---|
| `DEVELOPER_ID_CERT_P12_BASE64` | `.p12` を base64 化した文字列 | ステップ A |
| `DEVELOPER_ID_CERT_PASSWORD`   | `.p12` 書き出し時に設定したパスワード | ステップ A |
| `KEYCHAIN_PASSWORD`            | 任意の文字列（CI 用の一時キーチェーン用。何でもよい） | 自分で決める |
| `APPLE_API_KEY_P8_BASE64`      | `.p8` を base64 化した文字列 | ステップ B |
| `APPLE_API_KEY_ID`             | API キーの Key ID | ステップ B |
| `APPLE_API_ISSUER_ID`          | API の Issuer ID | ステップ B |
| `APPLE_TEAM_ID`                | Team ID（10 桁） | ステップ C |
| `SPARKLE_ED_PRIVATE_KEY`       | Sparkle の EdDSA 秘密鍵（base64 文字列） | ステップ F |

### E. Homebrew tap リポジトリを作る

Homebrew の「tap」は、ただの GitHub リポジトリです。**名前を必ず `homebrew-tap`** にします（`brew` が `homebrew-` の接頭辞を補完するため）。

1. GitHub で **public** リポジトリ `masakichi41/homebrew-tap` を作成
2. その中に `Casks/cmdkana.rb` を作成
   - 本リポジトリの [`dist/cmdkana.rb`](dist/cmdkana.rb) を雛形としてコピー
   - 最初のリリース後に `version` と `sha256` を実際の値へ更新（後述）

これで利用者は次のコマンドでインストールできます:

```sh
brew install --cask masakichi41/tap/cmdkana
```

### F. Sparkle 署名鍵を用意する（アプリ内アップデート用）

Sparkle はダウンロードした更新の改ざんを防ぐため、Apple の署名とは**別の** EdDSA 鍵で appcast に署名します。

1. Sparkle 配布物を取得して鍵生成ツールを実行します:

   ```sh
   curl -L -o Sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.9.2/Sparkle-2.9.2.tar.xz
   tar -xf Sparkle.tar.xz
   ./bin/generate_keys
   ```

   - 秘密鍵は macOS の**キーチェーンに保存**され、**公開鍵が標準出力に表示**されます。
2. 表示された公開鍵を `CmdKana/Info.plist` の `SUPublicEDKey` に貼り付けます（初期値 `REPLACE_WITH_SPARKLE_PUBLIC_ED_KEY` を置き換え）。
3. CI 用に秘密鍵をエクスポートし、その中身を Secret `SPARKLE_ED_PRIVATE_KEY` に登録します:

   ```sh
   ./bin/generate_keys -x sparkle_private_key.txt
   # sparkle_private_key.txt の中身を Secret に登録 → 登録後はファイルを削除
   ```

> ⚠️ `SUPublicEDKey` が初期値のままだと、配布したアプリは更新の署名を検証できません。必ず実鍵に置き換えてから最初のリリースを行ってください。

### G. GitHub Pages を有効化する（appcast のホスティング）

appcast.xml は CI が `gh-pages` ブランチへ公開します。リポジトリの **Settings → Pages** で **Source: Deploy from a branch**、**Branch: `gh-pages` / `(root)`** を選んで有効化してください。
これで `https://masakichi41.github.io/CmdKana/appcast.xml`（= `Info.plist` の `SUFeedURL`）が配信されます。

> `gh-pages` ブランチは最初のリリース時に CI が自動作成します。Pages の有効化はそのブランチが作られた後でも構いません。

---

## リリースのやり方（毎回）

1. **バージョンを決める**（例: `1.0.0`）。`MARKETING_VERSION` はタグから自動で注入されるので、`project.pbxproj` を手で書き換える必要はありません。
2. **タグを打って push する**:

   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. GitHub Actions の **Release** ワークフローが自動で走り、署名・公証済み DMG を添付した Release が作られます（数分かかります。Actions タブで進捗を確認）。**同時に Sparkle の appcast が生成され `gh-pages` へ公開**されます（ステップ F・G 設定後に有効。未設定の間は appcast 生成だけ自動スキップされ、DMG リリースは通常どおり作られます）。
4. 作成された Release の本文に表示される **`Homebrew Cask 用 SHA-256`** をコピーします。
5. tap リポジトリの `Casks/cmdkana.rb` を更新:
   - `version "1.0.0"` をタグに合わせる
   - `sha256 "..."` を 4. でコピーした値に差し替える
   - コミットして push
6. 動作確認:

   ```sh
   brew update
   brew install --cask masakichi41/tap/cmdkana
   ```

> ステップ 5（Cask 更新）は、慣れてきたら GitHub Actions から tap リポジトリへ自動 push することもできます（要 Personal Access Token）。まずは手動で運用するのが確実です。

---

## トラブルシューティング

- **公証が失敗する**: Actions のログに出る submission ID を使い、ローカルで詳細を確認できます。

  ```sh
  xcrun notarytool log <submission-id> \
    --key AuthKey_XXXXXXXXXX.p8 --key-id <KEY_ID> --issuer <ISSUER_ID>
  ```

  よくある原因: Hardened Runtime 無効、署名が Developer ID でない、`--timestamp` 欠如（本ワークフローでは設定済み）。

- **署名でキーチェーンのパスワードを聞かれて固まる**: `set-key-partition-list` が漏れていないか確認（本ワークフローでは設定済み）。

- **`Developer ID Application` が見つからない**: ステップ A の証明書が正しく `.p12`（秘密鍵込み）で書き出され、`DEVELOPER_ID_CERT_P12_BASE64` に登録されているか確認。

- **Team ID 不一致エラー**: `APPLE_TEAM_ID` が、証明書を発行したチームの Team ID と一致しているか確認。

- **`brew install` でハッシュ不一致**: Cask の `sha256` が Release のものと一致しているか確認。
