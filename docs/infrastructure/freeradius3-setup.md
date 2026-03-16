# FreeRADIUS 3 の導入

出典: [NII学術認証推進室 Wiki](https://nii-auth.atlassian.net/wiki/spaces/NIIninsho/pages/44271134)
取得日: 2026-03-16

## 改訂履歴

- 2015.6.29 初出
- 2015.7.1 更新
- 2015.7.31 更新
- 2017.2.7 更新
- 2020.7.22 更新
- 2022.8.22 更新
- 2023.3.8 更新
- 2025.2.21 更新

## 概要

本ドキュメントでは、[FreeRADIUS](https://www.freeradius.org) 3 を用いて eduroam 対応の RADIUS サーバ (proxy および IdP 機能) を構築する方法について説明する。

## 想定環境

- **対象バージョン**: FreeRADIUS 3.2.0
  - 注意: FreeRADIUS 3.0.25 以前には TLS 処理の不具合があるため、3.2.0 以降が必須
- **用途**: 機関ドメイン example.ac.jp のトップレベルサーバ (RADIUS proxy)、小規模 IdP としても利用可能
- **認証方式**: PEAP/EAP-TTLS 両用 (MS-CHAPv2)
- **インストール先**: `/usr/local/freeradius/3.2.0/`
- **設定ファイル**: `/usr/local/freeradius/3.2.0/etc/raddb/`
- **サーバ証明書**: FreeRADIUS による自動作成後、正規証明書に入替

## FreeRADIUSの導入手順

### 1. 開発環境の準備

FreeRADIUS ビルドに必要なライブラリ (openssl、taloc など) をあらかじめ導入する。

### 2. ソースコードのダウンロード

https://www.freeradius.org/ からソースパッケージをダウンロードする。

### 3. ビルドとインストール

```bash
$ tar zxf freeradius-server-3.2.0.tar.gz
$ cd freeradius-server-3.2.0
$ ./configure --prefix=/usr/local/freeradius/3.2.0
$ make
# make install
```

**注意**: make まで一般ユーザで実行可、`make install` は root 権限が必要。

## FreeRADIUSの設定

### 1. テンプレートの展開

設定ファイルテンプレート `raddb-3.2.0-eduroamJP.tgz` をダウンロードし、適切なディレクトリで展開する。

```bash
# cd /usr/local/freeradius/3.2.0/etc
# tar zxpf raddb-3.2.0-eduroamJP.tgz
```

### 2. 変更が必要な設定ファイル

#### radiusd.conf

認証ログを残すため `auth = yes` に設定する。

#### proxy.conf

- `<JP serverX addr>` と `<JP secret key>` に eduroam JP の登録時に決定されたアドレスと共通鍵を設定
- realm の `example` を自機関名に変更
- 機関レルム (例: example.ac.jp) に末尾がマッチするレルムはすべて機関側の RADIUS proxy で終端する必要がある
- 機関内別の RADIUS IdP への転送は IdP1/IdP2 設定例を参照
- オプション `status_check = status-server` は相手サーバの死活監視用。接続問題時は外してみること

#### clients.conf

- `<JP serverX addr>` と `<JP secret key>` に eduroam JP の登録時に決定されたアドレスと共通鍵を設定
- 機関内無線 LAN コントローラや他の RADIUS proxy をこのファイルに記述することでアクセスを許可

#### mods-available/eap

FreeRADIUS が自動作成した証明書で動作確認後、正規サーバ証明書に入替える。以下を設定する：

- `private_key_password`
- `private_key_file`
- `certificate_file`
- `ca_file`

UPKI 電子証明書発行サービスなどが利用可能。

**注意**: 公共 CA から発行された証明書を使用する場合、プライベート CA 証明書を端末に導入する手間を回避できるが、サーバ証明書のドメイン名確認を端末で設定する必要がある。

**注意2**: EAP-TLS クライアント認証フェーズでは公共 CA を使用しないこと。サンプルではこの機能が無効にコメントアウトされている。

#### mods-config/files/authorize

基本的に空のままにする。テストアカウントや少人数のアカウントはこのファイルに記述可能。

#### sites-available/nonexistent, sites-enabled/nonexistent

FreeRADIUS パッケージに含まれないファイル。機関に存在しないレルム受信時にエラーを返すための virtual server 定義。サンプル tar ファイルのものをコピーし、Example University を自機関名に変更する。

#### policy.d/filter

FreeRADIUS 3.x 系の一部に "reject mixed case" という不正なルールが有効になっているものがある。このルールがコメントアウト（無効化）されていることを確認すること。FreeRADIUS 3.2.0 では最初から無効になっているはず。

※eduroam のアカウントはユーザ名が case sensitive（大文字小文字を区別）、レルム名が case insensitive（大小区別しない）。

## 動作確認

### 1. テストアカウントの登録

`mods-config/files/authorize` にテスト用アカウントを書き込む。

### 2. Debug モード起動

```bash
# /usr/local/freeradius/3.2.0/sbin/radiusd -fxx -l stdout
```

- root で実行する
- オプション `-fxx -l stdout` でデーモンではなく通常プロセスとして動作

### 3. テストコマンド実行

```bash
# export PATH=$PATH:/usr/local/freeradius/3.2.0/bin
# radtest ユーザ名@example.ac.jp パスワード localhost 1 testing123
# radtest -t mschap ユーザ名@example.ac.jp パスワード localhost 1 testing123
# radtest -t mschap ユーザ名@example.ac.jp パスワード localhost:18120 1 testing123
```

- radiusd 起動失敗時は設定を見直す
- 認証成功時には "Access-Accept" が表示される
- 最後のコマンドは inner-tunnel 確認用。失敗時は実際の端末認証も失敗する

### 4. 本運用への移行

正常動作確認後、オプション `-fxx -l stdout` なしで radiusd を起動し、OS スタートアップファイルに追記してシステム起動時に自動起動するよう設定する。

**重要**: 動作確認後は必ずテスト用アカウントを削除し、radiusd を再起動すること。

## eduroam JP参加時の注意事項

認証連携がうまく動作しない例が散見されるため、問い合わせ前に以下を確認すること：

- **RADIUSサーバ上のFirewall**: ポート 1812/udp を開放する
- **機関のFirewall**: ポート 1812/udp を開放する
- **共通鍵の正確性**: RADIUSソフトウェアやアプライアンスにより最大長や利用可能字種が異なる。環境に合った鍵を申請書に記入する
- **レルム転送処理**: 自機関レルム付き認証要求を eduroam JP に転送しないこと。特に正規表現使用時は注意が必要。負荷軽減のため、レルムなし認証要求も転送しないこと
