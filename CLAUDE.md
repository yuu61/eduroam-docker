# CLAUDE.md

## プロジェクト概要

学校法人コンピュータ総合学園（神戸電子専門学校・神戸情報大学院大学）へのeduroam導入に向けた技術検証環境。
FreeRADIUS + Google Workspace Secure LDAP による EAP-TTLS/PAP 認証を Docker で構築する。

## 技術スタック

- **RADIUS**: FreeRADIUS 3.2.6（公式Dockerイメージベース）
- **LDAP**: OpenLDAP 1.5.0（Phase 1テスト用）、Google Workspace Secure LDAP（Phase 2本番）
- **認証方式**: EAP-TTLS/PAP（Google WorkspaceがNTハッシュ非対応のため唯一の選択肢）
- **コンテナ**: Docker Compose（freeradius, openldap, test-client の3サービス）

## ディレクトリ構造

```
docker/                         # Docker環境
  .env.example                  # 環境変数テンプレート（.envにコピーして使用）
  docker-compose.yml            # 3サービス構成（freeradius, openldap, test-client）
  freeradius/
    Dockerfile                  # ストックFreeRADIUSにカスタム設定を上書き
    raddb/
      clients.conf              # RADIUSクライアント定義
      proxy.conf                # realm routing設定
      policy.d/filter           # ポリシーフィルタ定義
      mods-available/eap        # EAP-TTLS/PAP設定
      mods-available/ldap       # OpenLDAP接続（Phase 1）
      mods-available/ldap_google # Google Workspace LDAP（Phase 2、未有効化）
      sites-available/eduroam            # 外部EAPトンネル
      sites-available/eduroam-inner-tunnel # 内部認証（LDAP検索→PAP）
      certs/                    # TLS証明書（git-ignored、generate-certs.shで生成）
  openldap/ldif/                # LDAPスキーマ・テストユーザーデータ
  test-client/
    Dockerfile                  # radtest/eapol_testクライアント
    scripts/
      eapol_test.conf           # EAP-TTLS/PAP テスト設定
      test-all.sh               # 全テスト自動実行スクリプト
scripts/                        # セットアップ・証明書生成スクリプト
  setup.sh                      # 初期セットアップ（.env作成 + 証明書生成 + ビルド）
  generate-certs.sh             # 自己署名CA・サーバ証明書生成
docs/                           # 技術ドキュメント
  application/                  # eduroam JP 申請手続き
  infrastructure/               # インフラ・技術設計
    architecture.md             # システム構成設計
    deployment-strategy.md      # 拠点別展開戦略（財務分析・L8リスク含む）
    freeradius3-setup.md        # FreeRADIUS設定リファレンス
    google-secure-ldap-802.1x-feasibility.md  # Google LDAP実現性調査
    virtualization-comparison.md # 仮想化基盤比較
  ap/                           # アクセスポイント調査
    existing-ap-survey.md       # 既存AP棚卸し調査結果
    vendor-survey.md            # ベンダー比較概要
    vendors/                    # ベンダー別詳細評価
      aruba-hpe.md / cisco-catalyst-meraki.md / juniper-mist.md / ubiquiti-unifi.md
  UPKI/                         # NII UPKI証明書関連ドキュメント
plans/                          # 実装計画
```

## よく使うコマンド

```bash
make setup          # 初期セットアップ（.env作成 + 証明書生成 + Dockerビルド）
make certs          # 証明書生成のみ
make build          # Dockerイメージ再ビルド
make up             # 環境起動（バックグラウンド）
make up-debug       # 環境起動（フォアグラウンド、ログ表示）
make down           # 環境停止
make restart        # 環境再起動（設定変更の反映に使用）
make logs           # FreeRADIUSログ表示
make logs-all       # 全サービスログ表示
make test           # デフォルトテスト（= test-radtest）
make test-radtest   # radtestでPAP認証テスト
make test-eapol     # eapol_testでEAP-TTLS/PAP認証テスト
make test-all       # 全テスト一括実行（test-all.sh経由）
make ldap-search    # OpenLDAPのユーザー確認
make clean          # 環境+ボリューム削除
make clean-certs    # 証明書削除
```

## 設定変更時のワークフロー

FreeRADIUSの設定ファイルはdocker-compose.ymlで個別マウントしている。
設定変更後は `make restart` で反映される（リビルド不要）。

Dockerfile自体を変更した場合は `make build && make up` が必要。

## テスト用認証情報

`docker/.env` で管理。`docker/.env.example` をコピーして値を設定する。

| 項目 | 環境変数 | 備考 |
|------|---------|------|
| RADIUS shared secret | `RADIUS_SECRET` | |
| LDAP組織名 | `LDAP_ORGANISATION` | `Kobe Denshi` |
| LDAPドメイン | `LDAP_DOMAIN` | `kobedenshi.ac.jp` |
| LDAP admin password | `LDAP_ADMIN_PASSWORD` | |
| LDAP Base DN | `LDAP_BASE_DN` | `dc=kobedenshi,dc=ac,dc=jp` |
| テストユーザー | `TEST_USER` | |
| テストパスワード | `TEST_PASSWORD` | |

Phase 2以降で追加される環境変数（`.env.example`にコメントアウトで記載済み）:
- **Phase 2**: `GOOGLE_LDAP_CERT_FILE`, `GOOGLE_LDAP_KEY_FILE`, `GOOGLE_LDAP_USER`, `GOOGLE_LDAP_PASS`
- **Phase 4**: `FLR_SERVER_1`, `FLR_SERVER_2`, `FLR_SECRET`

## FreeRADIUS設定の注意事項

- ストックの`radiusd.conf`を使用（カスタム版は持たない）。標準モジュール（pap, suffix, attr_filter等）はストックイメージのものをそのまま利用。
- `mods-enabled/`と`sites-enabled/`のシンボリックリンクはDockerfile内で管理。ホスト側の`mods-enabled/`、`sites-enabled/`ディレクトリは使わない。
- Phase切替時は`eduroam-inner-tunnel`内のldapモジュール参照を`ldap`→`ldap_google`に変更する。

## 検証フェーズ

- **Phase 1**: ローカル検証（OpenLDAP） ← 現在
- **Phase 2**: Google Workspace Secure LDAP接続
- **Phase 3**: Proxy検証（モックFLR）
- **Phase 4**: eduroam JP接続（NII登録後）
- **Phase 5**: AP統合・実機テスト

## UPKI電子証明書（本番用サーバ証明書）

eduroam本番運用ではNII UPKI電子証明書発行サービスのサーバ証明書をRADIUSサーバに使用する。

### 申請主体

- **申請機関**: 学校法人コンピュータ総合学園（利用規程 第2条第2号に該当）
- **該当根拠**: 神戸情報大学院大学（大学）を設置する学校法人であること
- **注意**: 神戸電子専門学校は専修学校であり、単独では申請資格を満たさない

### 申請に必要な体制

| 役割 | 要件 |
|------|------|
| 機関責任者 | 課長職以上または准教授相当以上の常勤教職員（1名） |
| 登録担当者 | 機関責任者から任命（複数可、証明書発行・失効の審査業務を担当） |
| 利用管理者 | 証明書の秘密鍵の管理責任者（常勤教職員） |

### 証明書の主な仕様・制約

| 項目 | 内容 |
|------|------|
| 費用 | 有償（構成員数＝常勤教員・研究者の合計で算定、学生は含まない） |
| 申請から利用開始 | **最短40日**（前々月20日までに押印済み書類が必要） |
| 有効期間 | **396日間**（指定不可、年次更新が必要） |
| 鍵長 | RSA 2048bit |
| FQDN | ドメイン申請書記載のドメインで申請（IPアドレス不可） |
| 対象ドメイン | `kobedenshi.ac.jp` と `kic.ac.jp`（法人名義で複数ドメイン管理可能） |
| 継続意思確認 | 年度ごと（2〜3月頃）。**怠ると全証明書が失効** |
| RADIUSサーバ利用 | 可能だがサポート対象外 |

### ドメイン審査方法（3択）

1. **メール認証**: `admin@`/`administrator@`/`webmaster@`/`hostmaster@`/`postmaster@<ドメイン>`のいずれかで受信
2. **DNSメール認証**: `_validation-contactemail.<ドメイン>` TXTレコードにメールアドレスを登録
3. **DNS認証**: 認証局指定のランダム値をTXTレコードに登録

### CSR作成時のDNルール

```
C  = JP（固定）
ST = Hyogo（都道府県ローマ字、機関ごとに固定）
L  = Kobe-shi（市区町村ローマ字、機関ごとに固定）
O  = 機関名英語表記（サービス参加申請時に登録）
CN = サーバのFQDN（例: radius.kobedenshi.ac.jp, radius.kic.ac.jp）
```

### 証明書発行フロー

1. 利用管理者が鍵ペア・CSRを作成
2. TSVファイルを作成し登録担当者へ送付
3. 登録担当者が本人確認後、支援システムへアップロード
4. 利用管理者に発行通知メール → 証明書取得URLからダウンロード（有効期限30日）

### 関連ドキュメント

詳細は `docs/UPKI/` 配下を参照:
- `UPKI-eduroam申請資格調査.md` — 申請主体の整理とeduroam JPへの確認事項
- `国立情報学研究所UPKI電子証明書発行サービス利用規程.md` — 利用規程全文
- `証明書申請・管理ガイド.md` — 参加申請→発行前審査→証明書管理の統合ガイド
- `サーバ証明書インストールマニュアル_OpenLDAP編.md` — OpenLDAPへの証明書インストール手順
- `UPKI証明書FAQ要約.md` — eduroam関連のFAQ要約

## 拠点別状況と展開戦略

2拠点でインフラ成熟度が大きく異なる。詳細は `docs/infrastructure/deployment-strategy.md` を参照。

| 拠点 | AP構成 | 導入難易度 | 戦略 |
|------|--------|-----------|------|
| **KIC（大学院）** | Aruba統一、WLC管理、SINET/IPv6 | 低 | SSID追加 + RADIUS統合。先行導入して実績を作る |
| **神戸電子（専門学校）** | 4社混在、37 SSID乱立、WLCなし | 高 | KIC実績をテコに法人総務トップダウンで展開 |

- **展開順序**: 2拠点同時並行が基本方針。問題発生時はKIC→神戸電子のカナリアリリースにフォールバック
- **KIC側キーパーソン**: インフラ整備した教授（Discord 1hopで連絡可能）。困ったら相談する
- **L8リスク**: 専門学校側は学科・建物ごとに管理者が異なり、ボトムアップでの合意形成が困難。法人総務からの指示でバイパスする方針

## ドキュメント記述ルール

`docs/` 配下のドキュメントは**常に最新の状態**を記述する。バージョン管理はgitに任せる。

- **禁止**: 「調査日」「作成日」「取得日」「改訂履歴」などのタイムスタンプをドキュメント内に記載しない
- **禁止**: 「以前は〜としていたが」「旧版では〜」「〜に変更した」「〜に修正」など、ドキュメント自体の変更経緯を記述しない
- **禁止**: 「調査報告」「〜を調査した」のような過去形の報告文体。現在の事実として記述する
- **許可**: 出典データの基準日（`2025年5月1日現在`等）、証拠の実施日（`nmapスキャン（2025-10-14）`等）は事実の根拠として記載してよい
- **許可**: 第三者の歴史的事実（「理化学研究所は以前〜だったが移行した」等）はそのまま記載してよい

## シークレット管理

証明書（`certs/`）と`.env`は`.gitignore`で除外済み。
全てのシークレット（RADIUS共有シークレット、LDAPパスワード、テストユーザーパスワード）は`docker/.env`で管理する。
FreeRADIUS設定ファイルでは`$ENV{VAR}`構文で環境変数を参照する。
Google Workspace関連のシークレットはPhase 2で`.env`経由で管理する。
