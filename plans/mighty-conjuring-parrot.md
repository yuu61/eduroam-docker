# eduroam導入 技術検証環境 実装計画

## Context

学校法人コンピュータ総合学園（神戸電子専門学校・神戸情報大学院大学）にeduroamを導入するため、FreeRADIUS + Google Workspace Secure LDAP による検証環境をDockerで構築する。IT部門への提案に必要な技術的裏付けを得ることが目的。

## 認証方式の決定: EAP-TTLS/PAP

| 要素 | EAP-TTLS/PAP | PEAP/MSCHAPv2 |
|------|-------------|---------------|
| Google Workspace LDAP | **対応** (LDAP bind) | 非対応 (NTハッシュ不可) |
| Azure AD | **対応** (ROPC等) | 非対応 (NTハッシュ不可) |
| Windows | Win8+で対応 | ネイティブ対応 |
| macOS/iOS/Android | ネイティブ対応 | ネイティブ対応 |

→ Google Workspace/Azure ADいずれもNTハッシュを提供できないため、**EAP-TTLS/PAPが唯一の現実的選択肢**。

## アーキテクチャ

```
[端末] → 802.1X/EAP → [AP] → RADIUS → [FreeRADIUS (IdP+SP)]
                                              │
                         ┌──────────────────────┤
                         ↓                      ↓
              @kobedenshi.ac.jp          他大学realm
              Google Workspace           eduroam JP FLR
              Secure LDAP (認証)         (proxy転送)
```

## プロジェクト構造

```
eduroam_project/
├── docker/
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── freeradius/
│   │   ├── Dockerfile
│   │   └── raddb/
│   │       ├── radiusd.conf
│   │       ├── clients.conf
│   │       ├── proxy.conf
│   │       ├── mods-available/
│   │       │   ├── eap                  # EAP-TTLS/PAP設定
│   │       │   ├── ldap_google          # Google Workspace LDAP
│   │       │   └── ldap                 # ローカルテスト用OpenLDAP
│   │       ├── mods-enabled/            # シンボリックリンク
│   │       ├── sites-available/
│   │       │   ├── eduroam              # 外部トンネル
│   │       │   └── eduroam-inner-tunnel # 内部トンネル(認証処理)
│   │       ├── sites-enabled/
│   │       ├── certs/                   # サーバー証明書(git-ignored)
│   │       └── policy.d/
│   ├── openldap/
│   │   └── ldif/
│   │       ├── base.ldif
│   │       └── test-users.ldif
│   └── test-client/
│       ├── Dockerfile
│       └── scripts/                     # eapol_test等のテストスクリプト
├── scripts/
│   ├── setup.sh
│   └── generate-certs.sh
├── docs/                                # 技術ドキュメント
├── plans/
├── .gitignore
├── Makefile
└── README.md
```

## 主要設定ファイル

### FreeRADIUS EAP設定 (`mods-available/eap`)
- `default_eap_type = ttls`
- TTLS内部認証: PAP
- TLS 1.2以上を強制
- 自己署名証明書(検証時)→ 本番ではCA発行証明書

### Google Workspace Secure LDAP (`mods-available/ldap_google`)
- サーバー: `ldaps://ldap.google.com:636`
- クライアント証明書認証 + アクセス認証情報
- ユーザー検索フィルタ: `(mail=%{Stripped-User-Name})`
- 認証方式: LDAP bind（パスワード検証）

### Proxy設定 (`proxy.conf`)
- `realm kobedenshi.ac.jp` → ローカル認証（IdP）
- `realm DEFAULT` → eduroam JP FLRへ転送（SP）
- `realm NULL` → 拒否
- FLRサーバーはfail-overプール構成

### Inner Tunnel (`sites-available/eduroam-inner-tunnel`)
- 自realmのみ認証を許可
- LDAP検索 → LDAP bindで認証
- テスト時はOpenLDAP、本番はGoogle Workspace LDAP

## Docker環境

| サービス | 用途 | ポート |
|---------|------|--------|
| `freeradius` | RADIUSサーバー | 1812/udp, 1813/udp |
| `openldap` | ローカルテスト用LDAP | 389, 636 |
| `test-client` | radtest/eapol_testクライアント | - |

## 検証フェーズ

### Phase 1: ローカル検証（OpenLDAP）
- FreeRADIUS + OpenLDAP でEAP-TTLS/PAP動作確認
- `radtest` と `eapol_test` で認証テスト
- 外部依存なしで基本動作を検証

### Phase 2: Google Workspace LDAP接続
- Google Admin Console でSecure LDAP有効化
- クライアント証明書取得・配置
- 実アカウントでの認証テスト

### Phase 3: Proxy検証
- モックFLRサーバーで他realm転送を確認

### Phase 4: eduroam JP接続
- NII参加登録→FLRサーバー情報取得
- 実際のeduroam階層に接続
- 正式なサーバー証明書取得

### Phase 5: AP統合
- APにRADIUSクライアント設定
- SSID `eduroam` 追加
- 実機テスト

## セキュリティ考慮事項
- シークレットは`.env`と`secrets/`に格納（git-ignored）
- 外部Identity: `anonymous@kobedenshi.ac.jp`を使用
- TLS 1.2以上を強制
- auth_goodpass=noでパスワードログ防止
- pre-proxy属性フィルタリング

## リスク
- Google Workspace Education Fundamentalsの場合、Secure LDAPが使えない可能性（Education Plus/Standardで対応）
- WindowsのEAP-TTLS/PAP設定にはプロファイル配布が必要
- NII登録に時間がかかるため早期着手が望ましい

## 検証方法
1. `cp docker/.env.example docker/.env` で環境変数ファイルを作成・編集
2. `docker compose up` で環境起動
3. `make test-radtest` でPAP認証テスト
4. `make test-eapol` でEAP-TTLS/PAP認証テスト
5. FreeRADIUS `-X` ログで `Access-Accept` / `Access-Reject` を確認
