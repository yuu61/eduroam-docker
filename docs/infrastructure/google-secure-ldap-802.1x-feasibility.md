# Google Workspace Secure LDAP × 802.1X認証 技術調査

## 1. 調査目的

Google Workspace Secure LDAP を FreeRADIUS のバックエンド認証源として使用し、802.1X（WPA2/WPA3-Enterprise）認証を実現できるか検証する。

## 2. 結論

**利用可能。ただし EAP-TTLS/PAP（またはEAP-TTLS/GTC）限定で、クォータ等の運用制約がある。**

本プロジェクトの Phase 2 設計（`mods-available/ldap_google` による Google Workspace Secure LDAP 接続）は技術的に実現可能である。既に EAP-TTLS/PAP を採用しているため、認証方式の変更は不要。

## 3. 認証方式の互換性

### 3.1 Google Secure LDAP が無効化している認証メカニズム

Google Secure LDAP は以下の SASL 認証メカニズムを明示的に無効化している:

- DIGEST-MD5
- CRAM-MD5
- **NTLM**
- GSSAPI

これにより、NTハッシュの取得が不可能であり、MSCHAPv2 ベースの認証方式は使用できない。

### 3.2 認証方式別の対応状況

| EAP方式 | 内部認証 | 利用可否 | 理由 |
|---------|---------|---------|------|
| EAP-TTLS | PAP | **可** | TTLSトンネル内で平文パスワードを送信 → FreeRADIUS が LDAP bind で検証 |
| EAP-TTLS | GTC | **可** | PAP と同様の仕組み。macOS/iOS で推奨 |
| PEAP | MSCHAPv2 | **不可** | NTハッシュが必要だが Google LDAP は提供しない |
| EAP-TLS | （証明書） | 対象外 | クライアント証明書認証であり LDAP バックエンドとは無関係 |

### 3.3 認証フロー

```
サプリカント → AP → FreeRADIUS
                      │
                      ├─ 外部EAP: EAP-TTLS トンネル確立
                      │
                      └─ 内部認証: PAP（平文パスワード）
                            │
                            └─ FreeRADIUS が Google Secure LDAP に
                               TLSクライアント証明書で接続し LDAP bind
                               → 成功/失敗を返却
```

## 4. 技術要件

### 4.1 Google Workspace 側

| 要件 | 詳細 |
|------|------|
| 対応エディション | Business Plus / Enterprise / Education Fundamentals 以上 |
| LDAPクライアント設定 | 管理コンソールでFreeRADIUS用のLDAPクライアントを追加し、クライアント証明書（.crt / .key）を発行 |
| アクセス権限 | ユーザー認証情報の確認権限を付与 |
| TLSバージョン | TLS 1.2 以上必須 |

### 4.2 FreeRADIUS 側

| 要件 | 詳細 |
|------|------|
| LDAPモジュール | `rlm_ldap` でGoogle Secure LDAP（ldap.google.com:636）に接続 |
| TLSクライアント証明書 | Google管理コンソールで発行した証明書を `tls` セクションで指定 |
| EAP設定 | EAP-TTLS を有効化し、内部トンネルで PAP を使用 |
| キャッシュ | `cache_auth` モジュールの導入を推奨（クォータ対策） |

## 5. 運用上の制約

### 5.1 クォータ制限

#### 5.1.1 公式クォータ値

| 項目 | 制限値 | 備考 |
|------|--------|------|
| bind クエリ | **4 QPS / 顧客** | 全ドメイン共有（kobedenshi.ac.jp + kic.ac.jp で合算） |
| search クエリ | 非公開（別途制限あり） | bind とは別に計測される |
| 日次制限 | 明確な記載なし | Google公式ドキュメントは「daily quotas」に言及しているが、具体的な日次上限値は非公開。実質的には QPS 制限がボトルネック |
| クォータ増加申請 | 正式なプロセスなし | Google Workspace サポートへの個別相談のみ |

- bind と search は**別々に計測**される。超過時は `ADMIN_LIMIT_EXCEEDED`（LDAP エラーコード 11）が返却される
- クォータは**顧客（組織）単位**で共有。複数の LDAP クライアントを登録した場合も合算される

#### 5.1.2 802.1X 認証におけるクエリ消費量

1回の EAP-TTLS/PAP 認証で FreeRADIUS が Google LDAP に発行するクエリ:

| 操作 | クエリ種別 | 回数 |
|------|-----------|------|
| ユーザー DN 検索 | search | 1 |
| パスワード検証（LDAP bind） | bind | 1 |
| **合計** | | **2クエリ/認証** |

#### 5.1.3 再認証の発生頻度

802.1X では以下のタイミングで RADIUS 再認証が発生し、Google LDAP へのクエリが発生する:

| トリガー | 頻度 | 説明 |
|---------|------|------|
| 初回認証 | 接続時1回 | ユーザーが WiFi に接続 |
| セッションタイムアウト | デフォルト **3600秒（1時間）** | RADIUS の Session-Timeout 属性で制御。AP 側の設定で変更可能 |
| AP 間ローミング | 移動時 | PMKSA キャッシュがない AP への移動時に完全再認証が発生 |
| ネットワーク復旧 | 障害後 | 回線断→復旧時に全端末が一斉に再認証を試行（**バースト**） |

**PMKSA キャッシュによる軽減**: 同一 AP への再接続や 802.11r（Fast BSS Transition）対応環境では、キャッシュされた PMK を使用して RADIUS 再認証をスキップできる。ただし、異なる AP への初回接続では完全な EAP 認証が必要。

#### 5.1.4 規模別のクォータ消費試算

前提条件:
- 1認証 = 2クエリ（search 1 + bind 1）
- 再認証間隔 = 3600秒（デフォルト）
- PMKSA キャッシュなし（最悪ケース）

**定常状態（ユーザーが接続済みで1時間ごとに再認証）**:

| 同時接続数 | 再認証/時 | 必要QPS（均等分散時） | 4 QPS で足りるか |
|-----------|----------|---------------------|----------------|
| 100人 | 200クエリ/時 | 0.06 QPS | **余裕** |
| 500人 | 1,000クエリ/時 | 0.28 QPS | **余裕** |
| 1,000人 | 2,000クエリ/時 | 0.56 QPS | **余裕** |
| 3,000人 | 6,000クエリ/時 | 1.67 QPS | **余裕** |
| 5,000人 | 10,000クエリ/時 | 2.78 QPS | **余裕** |
| 7,200人 | 14,400クエリ/時 | 4.00 QPS | **上限** |

**バーストシナリオ（全端末が同時に認証を試行）**:

| 同時認証数 | 必要クエリ | 4 QPS での処理時間 | リスク |
|-----------|----------|-------------------|--------|
| 10人 | 20 | 5秒 | 低 |
| 50人 | 100 | 25秒 | 低（認証遅延あり） |
| 100人 | 200 | 50秒 | 中（体感的な遅延） |
| 500人 | 1,000 | 250秒（約4分） | **高**（タイムアウトの可能性） |
| 1,000人 | 2,000 | 500秒（約8分） | **危険**（大量の認証失敗） |

> **神戸電子 + KIC の規模感**: 両校合わせて学生・教職員が数千人規模と仮定した場合、定常状態では問題ないが、**授業開始時の一斉接続**や**ネットワーク障害復旧後のバースト**が最大のリスク。

#### 5.1.5 クォータ緩和策

| 対策 | 効果 | 実装難度 | 詳細 |
|------|------|---------|------|
| **FreeRADIUS 認証キャッシュ** | 高 | 低 | `cache_auth` モジュールで認証結果をキャッシュし、Google LDAP への問い合わせを削減 |
| **LDAP DN キャッシュ** | 中 | 低 | ユーザー DN をキャッシュし、search クエリを削減（bind のみ発行） |
| **検索スコープの最適化** | 低〜中 | 低 | base DN を `ou=Users` 等に絞り、不要な search を削減 |
| **PMKSA キャッシュ / 802.11r** | 高 | 中 | AP 側の設定で RADIUS 再認証自体をスキップ |
| **Session-Timeout の延長** | 中 | 低 | 再認証間隔を 3600秒 → 7200〜14400秒に延長 |
| **認証キューイング** | 中 | 高 | バースト時にリクエストを平滑化するキューを実装 |

##### FreeRADIUS `cache_auth` モジュールの推奨設定

FreeRADIUS 標準の `cache_auth` モジュールは3つのキャッシュインスタンスを提供する:

| インスタンス | 用途 | 推奨TTL | キー |
|-------------|------|---------|------|
| `cache_auth_accept` | 認証成功結果のキャッシュ | **7200秒（2時間）** | MD5(ユーザー名 + パスワード) |
| `cache_auth_reject` | 認証失敗結果のキャッシュ | **3600秒（1時間）** | MD5(Calling-Station-Id + ユーザー名 + パスワード) |
| `cache_ldap_user_dn` | ユーザー DN のキャッシュ | **86400秒（24時間）** | Stripped-User-Name |

- `cache_auth_accept` により、キャッシュ有効期間中の再認証では Google LDAP への問い合わせが**完全にスキップ**される
- `cache_ldap_user_dn` により、キャッシュヒット時は search クエリが不要になり、**bind のみ**で認証が完了する（1認証 = 1クエリに削減）
- ドライバは `rlm_cache_rbtree`（インメモリ赤黒木）を使用。FreeRADIUS 再起動時にキャッシュは消失する

##### キャッシュ適用後のクォータ消費試算（1,000人同時接続）

| シナリオ | cache_auth | cache_ldap_user_dn | Google LDAPクエリ/時 | 必要QPS |
|---------|-----------|-------------------|---------------------|---------|
| キャッシュなし | - | - | 2,000 | 0.56 |
| DN キャッシュのみ | - | 有効 | 1,000（bind のみ） | 0.28 |
| 認証キャッシュ有効（TTL 2h） | 有効 | 有効 | **0**（キャッシュヒット） | **0** |
| バースト（500人同時・キャッシュミス） | ミス | 有効 | 500（bind のみ） | 瞬間 500 / 4 = 125秒 |
| バースト（500人同時・キャッシュなし） | ミス | ミス | 1,000 | 瞬間 1000 / 4 = 250秒 |

> **推奨**: `cache_auth_accept` + `cache_ldap_user_dn` の両方を有効化する。定常状態ではクォータ消費をほぼゼロにでき、バースト時の影響も半減する。

### 5.2 WLC 側の RADIUS 再認証削減機能

WLC（Wireless LAN Controller）側で RADIUS 再認証をスキップする機能を活用すれば、Google Secure LDAP へのクエリを大幅に削減できる。以下は主要ベンダーの対応状況。

#### 5.2.1 高速ローミング技術の概要

| 技術 | 標準規格 | 仕組み | RADIUS再認証 |
|------|---------|--------|-------------|
| **PMKSA Caching** | IEEE 802.11i | クライアントが以前接続した AP の PMK をキャッシュし、再接続時に再利用 | **スキップ**（同一APへの再接続時のみ） |
| **OKC（Opportunistic Key Caching）** | 非標準（業界デファクト） | WLC が PMK を管理下の全 AP に配布。未訪問の AP でも 4-way handshake のみで接続可能 | **スキップ** |
| **802.11r（FT: Fast BSS Transition）** | IEEE 802.11r | PMK-R0 → PMK-R1 → PTK の3層鍵階層で、ローミング時に4フレーム交換のみで遷移 | **スキップ** |
| **802.11k** | IEEE 802.11k | AP がネイバーリストを提供し、クライアントのスキャン時間を短縮（認証自体には関与しない） | 関与しない |
| **802.11v（BSS-TM）** | IEEE 802.11v | AP がクライアントに最適な AP への遷移を勧告（負荷分散・省電力） | 関与しない |

> **クォータ削減への効果**: OKC / 802.11r が有効な環境では、初回認証時のみ RADIUS（→ Google LDAP）への問い合わせが発生し、AP 間ローミング時の再認証は**完全にスキップ**される。これにより、ローミングに起因するクォータ消費がゼロになる。

#### 5.2.2 ベンダー別対応状況

##### Cisco Catalyst 9800

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching（SKC） | **非推奨** | 無効 | Catalyst 9800 では deprecated。OKC / 802.11r を使用 |
| OKC | **対応** | **有効** | 初回 EAP 認証後、全 AP で 4-way handshake のみ。FT/CCKM 有効化時は自動無効 |
| 802.11r（FT） | **対応** | **有効**（Adaptive） | Over-the-Air / Over-the-DS 両対応。Adaptive モードではレガシー端末との互換性を維持 |
| 802.11k | **対応** | 有効 | ネイバーリスト提供でスキャン時間短縮 |
| 802.11v（BSS-TM） | **対応** | 有効 | 負荷分散・省電力 |
| Session-Timeout | 設定可能 | 1800秒（旧）/ 43200秒（新） | 推奨: **86400秒（1日）** に延長。0 は非推奨（ローミング不具合の原因） |

**特記事項**:
- OKC と 802.11r（Adaptive）がデフォルト有効のため、**追加設定なしで RADIUS 再認証がローミング時にスキップ**される
- Session-Timeout を延長することで、定期的な完全再認証の頻度も削減可能

##### Cisco Meraki

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching | **対応** | **有効** | 全 AP で自動有効。同一 AP への再接続時に使用 |
| OKC | **対応** | **有効** | 全 AP で自動有効。Windows・一部 Android が対応 |
| 802.11r（FT） | **対応** | **無効** | `Configure > Access control` から手動有効化。NAT mode / L3 roaming では利用不可 |
| Adaptive 802.11r | **対応** | - | WPA2 のみ対応。WPA3 では自動的に Enabled に変更 |
| 802.11k | **対応** | 有効 | ネイバーリスト提供 |
| 802.11v（BSS-TM） | **対応** | **有効**（MR29.1+） | 負荷ベースの AP 推奨 |

**特記事項**:
- **802.11r はデフォルト無効**のため、クォータ削減には手動有効化が必要
- OKC はデフォルト有効なので、OKC 対応端末（Windows 等）ではローミング時の再認証はスキップされる
- CoA（Change of Authorization）有効時は高速ローミングが無効化される制約があったが、MR32.1.x + ISE 3.3 Patch 5 以降で共存可能に

##### Aruba（HPE Aruba Networking）

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching | **対応** | 有効 | 標準的な PMK キャッシュ |
| OKC | **対応** | **無効** | 手動有効化が必要。KMS（Key Management Service）が PMK を管理下 AP に配布 |
| 802.11r（FT） | **対応** | **有効** | MDID（Mobility Domain ID）の設定を推奨。AP クラスタ間での鍵共有 |
| 802.11k | **対応** | 推奨（有効化） | 高速 AP 発見のために 802.11r と併用推奨 |

**特記事項**:
- 802.11r がデフォルト有効のため、**追加設定なしで RADIUS 再認証がローミング時にスキップ**される
- MDID を適切に設定することで、大規模キャンパスでの高速ローミングが最適化される
- KMS が集中的に鍵を管理するため、コントローラベースの構成と相性が良い

##### Juniper Mist

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching | **対応** | **ローカルのみ** | AP 間での PMK 共有なし。同一 AP への再接続時のみ有効 |
| OKC | **対応** | **無効** | 手動有効化。クラウド経由で隣接 AP に PMKID を配布。iOS 非対応 |
| 802.11r（FT） | **対応** | **無効** | Security セクションから手動有効化。WPA2: Default/.11r、WPA3: Default/OKC/.11r |
| FT Over-the-DS | **対応** | 無効 | Zebra 端末等の互換性オプション |

**特記事項**:
- **デフォルトではローカル PMKSA キャッシュのみ**で、AP 間ローミング時に完全再認証が発生する
- クォータ削減には **802.11r または OKC の手動有効化が必須**
- WPA2 では OKC が選択不可（WPA3 のみ）。WPA2 環境では 802.11r を推奨
- 設定変更時に AP 無線がリセットされ、接続中のクライアントが一時切断される点に注意

#### 5.2.3 ベンダー比較サマリ

| 機能 | Catalyst 9800 | Meraki | Aruba | Juniper Mist |
|------|:------------:|:------:|:-----:|:------------:|
| OKC デフォルト | **有効** | **有効** | 無効 | 無効 |
| 802.11r デフォルト | **有効**（Adaptive） | 無効 | **有効** | 無効 |
| 追加設定なしで RADIUS 再認証スキップ | **可** | **可**（OKC対応端末のみ） | **可** | **不可** |
| Session-Timeout 推奨値 | 86400秒 | RADIUS設定依存 | - | - |
| オンプレWLC | **可** | 不可（クラウド管理） | **可** | 不可（クラウド管理） |

#### 5.2.4 クォータ削減効果の総合評価

WLC 側の高速ローミング機能と FreeRADIUS 側のキャッシュを組み合わせた場合の効果:

| レイヤー | 対策 | 削減対象 | 効果 |
|---------|------|---------|------|
| **WLC（L2）** | OKC / 802.11r | AP 間ローミング時の再認証 | ローミング時の RADIUS クエリ = **0** |
| **WLC（L2）** | Session-Timeout 延長 | 定期再認証の頻度 | 3600秒→86400秒で **24分の1** に削減 |
| **RADIUS（L7）** | cache_auth_accept | Session-Timeout 満了時の再認証 | キャッシュヒット時は Google LDAP クエリ = **0** |
| **RADIUS（L7）** | cache_ldap_user_dn | ユーザー DN 検索 | search クエリ = **0**（bind のみに削減） |

> **結論**: WLC の OKC/802.11r + FreeRADIUS の cache_auth を併用すれば、Google Secure LDAP へのクエリは**初回認証時と cache_auth の TTL 満了時のみ**に限定される。4 QPS のクォータ制限は、神戸電子 + KIC の規模では実質的に問題にならない。

### 5.3 可用性

| リスク | 影響 | 対策 |
|--------|------|------|
| Google Cloud 障害 | 全ユーザーの WiFi 認証が不能 | 認証キャッシュで障害中のローミングを緩和。根本的なフォールバックは困難 |
| インターネット回線断 | FreeRADIUS → Google LDAP 間の通信不能 | 同上 |
| 証明書期限切れ | LDAPクライアント証明書が期限切れになると接続不能 | 管理コンソールで定期的に証明書を更新 |

### 5.4 サプリカント（端末）側の設定

| OS | EAP方式 | 内部認証 | 備考 |
|----|---------|---------|------|
| Windows | EAP-TTLS | PAP | OS標準では EAP-TTLS 非対応。レジストリ変更またはサードパーティサプリカントが必要 |
| macOS / iOS | EAP-TTLS | GTC または PAP | 構成プロファイルで配布推奨 |
| Android | EAP-TTLS | PAP | 手動設定可能。CA証明書の検証設定に注意 |
| ChromeOS | EAP-TTLS | PAP | 管理コンソールからポリシー配布可能 |

## 6. eduroam 固有の考慮事項

### 6.1 クォータとローミング

eduroam ではローミングユーザーの認証リクエスト量が予測しづらい。ただし、自機関（IdP）の認証リクエストのみが Google LDAP に到達するため、SP としてのトラフィックは影響しない。

クォータへの影響:
- **自機関ユーザーが他機関を訪問**: 訪問先 SP → FLR → 自機関 IdP → Google LDAP（クォータ消費あり）
- **他機関ユーザーが自機関を訪問**: 自機関 SP → FLR → 他機関 IdP（Google LDAP は無関係）
- ローミング先での再認証頻度は Session-Timeout と AP 設定に依存する

### 6.2 IdP 可用性要件

eduroam JP の運用ポリシーとして IdP の可用性が求められる。Google Cloud への依存が許容されるか、eduroam JP の運用ガイドラインを確認すべき。

### 6.3 他機関の事例

FortiAuthenticator + Google Workspace Secure LDAP での 802.1X 認証は Fortinet 公式ドキュメントに掲載されており、企業・教育機関での採用実績がある。

## 7. 実装時の注意事項（Phase 2 向け）

1. Google 管理コンソールで Secure LDAP サービスを有効化し、FreeRADIUS 用の LDAP クライアントを追加
2. 発行されたクライアント証明書を `docker/freeradius/raddb/certs/` に配置（`.gitignore` 済み）
3. `mods-available/ldap_google` の `tls` セクションでクライアント証明書を指定
4. `eduroam-inner-tunnel` の ldap モジュール参照を `ldap` → `ldap_google` に変更
5. 認証キャッシュモジュールの導入を検討
6. クォータ消費量の監視体制を構築

## 8. 調査情報源

- [About the Secure LDAP service - Google Workspace](https://support.google.com/a/answer/9048516?hl=en)
- [Secure LDAP service: Error code descriptions - Google Workspace](https://support.google.com/a/answer/9167101?hl=en) — クォータ制限値（4 QPS）の公式記載
- [Troubleshooting the Secure LDAP service - Google Workspace](https://support.google.com/a/answer/10788888?hl=en)
- [FAQs: Secure LDAP service - Google Workspace](https://support.google.com/a/answer/9100761?hl=en)
- [Connect LDAP clients to Secure LDAP - Google Workspace](https://support.google.com/a/answer/9089736?hl=en)
- [WPA-Enterprise with RADIUS and Google Workspace - Ketho](https://ketho.github.io/2024/01/31/google-workspace-ldap/) — cache_auth 実装例あり
- [802.1X with FortiAuthenticator and Google Workspace - Fortinet](https://docs.fortinet.com/document/fortiauthenticator/6.5.0/cookbook/253168/802-1x-authentication-using-fortiauthenticator-with-google-workspace-user-database)
- [FreeRADIUS with Google LDAP for 802.1X - SecureW2](https://www.securew2.com/blog/freeradius-with-google-ldap)
- [FreeRADIUS rlm_cache module - FreeRADIUS Wiki](https://wiki.freeradius.org/modules/Rlm_cache)
- [Session-Timeout, RADIUS and PMK caching - Cisco Community](https://community.cisco.com/t5/wireless/session-timeout-radius-and-pmk-caching/td-p/2983309)
- [Catalyst 9800: A Primer on Enterprise WLAN Roaming - Cisco](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9800-series-wireless-controllers/cat9800-ser-primer-enterprise-wlan-guide.html)
- [Understand 802.11r/11k/11v Fast Roams on 9800 WLCs - Cisco](https://www.cisco.com/c/en/us/support/docs/wireless/catalyst-9800-series-wireless-controllers/221671-understand-802-11r-11k-11v-fast-roams-on.html)
- [OKC on Catalyst 9800 - Cisco](https://www.cisco.com/c/en/us/td/docs/wireless/controller/9800/17-6/config-guide/b_wl_17_6_cg/m_okc.html)
- [Roaming Technologies - Cisco Meraki](https://documentation.meraki.com/Wireless/Design_and_Configure/Architecture_and_Best_Practices/Roaming_Technologies)
- [Configuring Support for 802.11r and OKC - Aruba](https://arubanetworking.hpe.com/techdocs/Instant_810_WebHelp/Content/instant-ug/wlan-ssid-conf/conf-fast-roam.htm)
- [RSSI, Roaming, and Fast Roaming - Juniper Mist](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/topic-map/rssi-fast-roaming.html)

## 9. 調査日

2026-03-17
