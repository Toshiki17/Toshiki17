# 中飛車道場（iPhoneアプリ）

中飛車の定跡を自分で指して身につける将棋学習ツール「中飛車道場」を、iPhoneアプリにしたものです。使い方は [docs/manual.md](docs/manual.md) を参照してください。

## 中身

| 場所 | 内容 |
| --- | --- |
| `web/nakabisha_sp.html` | 元のスマホ版HTML（アプリの中身。直すのはこのファイル） |
| `web/nakabisha.html` | 元のPC版HTML（アプリには入れていません） |
| `ios/` | iOSアプリ（SwiftUI + WKWebView）。`ios/www/` は下のスクリプトで作る同梱用ファイル |
| `appstore/` | App Store に載せる文面（`metadata.md`）とスクリーンショット |
| `docs/privacy.md` | プライバシーポリシー |
| `.github/workflows/ios.yml` | Mac上でのビルド確認と、App Store Connect へのアップロード |

アプリはHTMLを端末内から読み込むだけなので、オフラインで動きます。クリア記録と腕試しの成績はアプリ内に保存されます。

HTMLを直したら、次を実行して `ios/www/` を作り直し、コミットします。

```sh
python3 scripts/build_web.py
```

## App Store に公開する手順

### 1. 準備（最初の1回だけ）

1. [Apple Developer Program](https://developer.apple.com/jp/programs/) に登録する（年会費がかかります）。
2. [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) の「Identifiers」で、App ID を作る。Bundle ID は `io.github.toshiki17.nakabishadojo`。
   別のIDにしたいときは `ios/project.yml` の `PRODUCT_BUNDLE_IDENTIFIER` も合わせて変えます。
3. [App Store Connect](https://appstoreconnect.apple.com/) の「アプリ」→「＋」→「新規App」で、プラットフォーム iOS、名前「中飛車道場」、言語「日本語」、上のBundle ID、SKU `nakabishadojo` を入力して作る。

### 2. ビルドをアップロードする

Mac があるかどうかで、AとBのどちらかを選びます。

#### A. Mac と Xcode を使う

```sh
brew install xcodegen
cd ios && xcodegen generate
open NakabishaDojo.xcodeproj
```

1. ターゲット「NakabishaDojo」→「Signing & Capabilities」で、Team に自分の開発者アカウントを選ぶ。
2. 実機のiPhoneをつないで ▶ で動作を確かめる。
3. メニューの Product → Archive。終わったら Organizer で「Distribute App」→「App Store Connect」→「Upload」。

#### B. Mac なしで GitHub Actions を使う

1. App Store Connect の「ユーザとアクセス」→「統合」→「App Store Connect API」で、アクセス「Admin」のキーを作り、`.p8` ファイルをダウンロードする（ダウンロードは1回しかできません）。
2. このリポジトリの Settings → Secrets and variables → Actions に、次の4つを登録する。

   | 名前 | 値 |
   | --- | --- |
   | `ASC_KEY_ID` | キーID（10桁） |
   | `ASC_ISSUER_ID` | 同じ画面の上部にある Issuer ID |
   | `ASC_KEY_P8` | `.p8` ファイルの中身（`-----BEGIN PRIVATE KEY-----` から最後まで） |
   | `APPLE_TEAM_ID` | [メンバーシップの詳細](https://developer.apple.com/account#MembershipDetailsCard) にあるチーム ID（10桁） |

3. Actions タブ →「iOS」→「Run workflow」を押す。署名とアップロードまで自動で行います。ビルド番号は実行するたびに増えます。

### 3. TestFlight で確かめる

アップロードから十数分で、App Store Connect の「TestFlight」タブにビルドが出ます。iPhoneに「TestFlight」アプリを入れ、自分を内部テスターに加えると、ストア公開前に実機で試せます。

### 4. 審査に出す

App Store Connect のアプリのページで、次を入力して「審査用に追加」→「審査へ提出」を押します。入力する文面は [appstore/metadata.md](appstore/metadata.md) にまとめてあります。

- スクリーンショット：`appstore/screenshots/` の3枚（6.9インチ用）
- 説明・キーワード・サポートURL・プライバシーポリシーURL
- Appのプライバシー：「データの収集なし」
- 年齢制限：すべて「なし」（4+）
- 価格：無料
- ビルド：アップロードしたもの

審査はふつう1〜2日で終わり、承認されると App Store に公開されます。

## 開発メモ

- 同梱ページは `app://local/index.html` という独自スキームで読み込んでいます。`file://` で開くより、localStorage（記録）が確実に残るためです。
- フォント（しっぽり明朝 B1・Zen角ゴシック New、SIL Open Font License）は、ページで使う文字を含む部分だけを同梱しています。
- アイコンは `design/icon.html`、スクリーンショットは `scripts/render_screenshots.js` から Playwright で書き出せます。
