# Cisco 無線LANアクセスポイント技術調査レポート

調査日: 2026-03-16
目的: 学校法人コンピュータ総合学園 eduroam導入に向けたAP選定資料

---

## 1. 現行ラインナップ

Ciscoの無線LANアクセスポイントは大きく **Catalyst（オンプレミス管理）** と **Meraki（クラウド管理）** の2系統がある。
2025-2026年現在、CWシリーズ（デュアルモード）が両系統をまたぐ形で展開されている。

### 1.1 Wi-Fi 6 (802.11ax) モデル

| モデル | Wi-Fi規格 | ラジオ構成 | 最大クライアント数/AP | 用途 |
|--------|-----------|-----------|---------------------|------|
| **C9105AXI** | Wi-Fi 6 | 2x2 (2.4G) + 2x2 (5G) | 400 (200/radio) | 小規模・エントリー |
| **C9115AXI** | Wi-Fi 6 | 2x2 (2.4G) + 2x2 (5G) + BLE/IoT | 400 (200/radio) | ホスピタリティ・共用空間 |
| **C9120AXI** | Wi-Fi 6 | 4x4 (2.4G) + 4x4 (5G) + BLE | 400 (200/radio) | 中規模キャンパス |
| **C9130AXI** | Wi-Fi 6 | 4x4 (2.4G) + 4x4 (5G) + RF ASIC + BLE/IoT | 400 (200/radio) | 大規模・ミッションクリティカル |
| **C9136I** | Wi-Fi 6 | 4x4 (2.4G) + 4x4 (5G) + 専用スキャンラジオ | 1200 (400/radio) | 大規模エンタープライズ・高密度 |

### 1.2 Wi-Fi 6E (802.11ax 6GHz) モデル

| モデル | Wi-Fi規格 | ラジオ構成 | 用途 |
|--------|-----------|-----------|------|
| **CW9162I** | Wi-Fi 6E | 3x 2x2 (2.4G/5G/6G) | 6Eエントリー・コスト重視 |
| **CW9164I** | Wi-Fi 6E | 1x 2x2 + 2x 4x4 (2.4G/5G/6G) | 中〜大規模 |
| **CW9166I** | Wi-Fi 6E | 3x 4x4 (2.4G/5G/6G) + 環境センサー + IoT | 大規模・ミッションクリティカル |
| **CW9166D1** | Wi-Fi 6E | 3x 4x4 + 指向性アンテナ | 講堂・倉庫等の高天井環境 |

### 1.3 Wi-Fi 7 (802.11be) モデル

| モデル | Wi-Fi規格 | ラジオ構成 | 特徴 |
|--------|-----------|-----------|------|
| **CW9172I** | Wi-Fi 7 | トライバンド 2.4G/5G/6G | リテール・ヘルスケア・ブランチ |
| **CW9172H** | Wi-Fi 7 | トライバンド + 追加LANポート + BLE | ホスピタリティ・学生寮 |
| **CW9174I** | Wi-Fi 7 | トライバンド 10空間ストリーム、5Gbps uplink | オフィス・ヘルスケア・リテール |
| **CW9174E** | Wi-Fi 7 | 外部アンテナモデル | 倉庫・公共施設 |

> **補足**: CWシリーズはデュアルモードAPで、Catalyst（オンプレミスWLC管理）とMeraki（クラウド管理）のどちらのペルソナでも動作可能。

---

## 2. WPA2/WPA3-Enterprise (802.1X) 対応

### 2.1 対応状況

Catalyst 9100シリーズ（および後継CWシリーズ）は全モデルで以下に対応:

- **WPA2-Enterprise** (802.1X + AES-CCMP): 全モデル対応
- **WPA3-Enterprise** (802.1X + AES-CCMP-256/GCMP-256): IOS XE 16.12以降で対応
- **WPA3-Enterprise 192-bit mode** (CNSA Suite): IOS XE 17.x以降で対応
- **Transition Mode** (WPA2/WPA3混在): 対応（段階的移行に有用）

### 2.2 EAP方式について

Cisco APは802.1X認証においてEAPの「パススルー」として動作する。すなわち:

- **APはEAPメソッドを解釈しない** — EAPパケットをRADIUSサーバに中継するのみ
- EAP-TTLS/PAP、EAP-PEAP/MSCHAPv2、EAP-TLS等、RADIUSサーバがサポートする任意のEAP方式が利用可能
- **EAP-TTLS/PAPはAP側の制約なし** — WLCもmiddle manとして動作し、EAPプロセスに関与しない

### 2.3 EAP-TTLS/PAP動作可否

**結論: 動作可能**

Cisco Community公式の回答によれば、Catalyst 9800 WLCはEAPプロセスに対してmiddle manとして動作するため、EAP-TTLS/PAPでも問題は生じない。ただし以下の注意点がある:

- **クライアント側のサポート確認が必要**: Windows標準のサプリカントはEAP-TTLSをネイティブにサポートしていないため、eduroam CATなどの設定ツールが必要
- WLC側では「Local EAP」機能を使わない限り、EAP方式の制限はない
- FreeRADIUS側でEAP-TTLS/PAPを正しく設定していれば、AP/WLCは透過的に動作する

---

## 3. 集中管理機能

### 3.1 Catalyst 9800 Wireless LAN Controller (WLC)

| モデル | 管理AP数 | 最大クライアント数 | スループット | 形態 | 参考価格帯 |
|--------|---------|------------------|------------|------|-----------|
| **9800-L (Copper)** | 250 | 5,000 | — | アプライアンス | $7,000〜 |
| **9800-L (Fiber)** | 250 | 5,000 | — | アプライアンス | $7,000〜 |
| **9800-40** | 2,000 | 32,000 | 40 Gbps | アプライアンス | 要見積 |
| **9800-80** | 6,000 | 64,000 | 80 Gbps | アプライアンス | 要見積 |
| **9800-CL (Small)** | 1,000 | 16,000 | — | 仮想（VM） | ソフトウェアライセンス |
| **9800-CL (Large)** | 6,000 | 64,000 | — | 仮想（VM） | ソフトウェアライセンス |
| **EWC (Embedded)** | 50 | 1,000 | — | AP内蔵 | 追加コストなし |

#### EWC（Embedded Wireless Controller）

- Catalyst 9105/9115/9117シリーズのAPにWLC機能を内蔵
- 最大50AP、1,000クライアントまで管理可能
- **小規模導入ではDNAサブスクリプション不要**（スマートダッシュボードまたはモバイルアプリ管理のみの場合）
- 神戸電子専門学校規模（数十AP想定）であれば、EWCで十分な可能性あり

#### 本プロジェクトへの推奨

- **AP数が50台以下**: EWC（追加ハードウェア不要）
- **AP数が50〜250台**: 9800-L（コンパクトで管理しやすい）
- **AP数が250台超**: 9800-40 or 9800-CL

### 3.2 Meraki Dashboard

- **完全クラウド管理**: オンプレミスコントローラ不要
- ダッシュボードからSSID設定、RADIUS設定、VLAN設定が可能
- **Merakiライセンスが必須**（サブスクリプション制、後述）
- eduroam SSID設定、802.1X RADIUS認証、Hotspot 2.0設定をGUIで実施可能
- 管理台数上限は事実上なし（ライセンス数に依存）

### 3.3 Catalyst vs Meraki の選択基準

| 観点 | Catalyst + WLC | Meraki Dashboard |
|------|---------------|-----------------|
| 設定の自由度 | 高い（CLI/GUI） | 制限あり（GUIのみ） |
| RADIUS設定 | 詳細設定可能 | 基本設定のみ |
| Dynamic VLAN | 完全対応 | 対応（制約あり） |
| Passpoint/HS2.0 | CLI/GUIで詳細設定 | ダッシュボードから設定 |
| 運用コスト | WLCハード費用 + DNAライセンス | Merakiライセンスのみ |
| オフライン運用 | 可能 | 制限あり（ライセンス切れで機能停止） |
| eduroam実績 | 多数 | 龍谷大学等で実績あり |

---

## 4. VLAN対応

### 4.1 タグVLAN (802.1Q)

- Catalyst 9100シリーズ全モデル対応
- AP - スイッチ間はトランクポート（802.1Qタグ付き）で接続
- SSID毎に異なるVLAN IDを割り当て可能
- Merakiの場合も802.1Q対応スイッチのトランクポートに接続が必要

### 4.2 Dynamic VLAN (RADIUS属性による動的割り当て)

**Catalyst 9800 WLCで完全対応。** RADIUSサーバ（FreeRADIUS含む）からAccess-Acceptに以下の属性を含めることでVLAN動的割り当てが可能:

| RADIUS属性 | 属性番号 | 値 |
|-----------|---------|-----|
| Tunnel-Type | 64 | VLAN (13) |
| Tunnel-Medium-Type | 65 | 802 (6) |
| Tunnel-Private-Group-Id | 81 | VLAN ID（文字列として送信） |

#### 設定ポイント

1. **WLC側**: Policy Profileで「AAA Override」を有効化
2. **RADIUS側**: Access-Acceptに上記3属性をセットで返す
3. Tunnel-Private-Group-Idは文字列型（RFC2868準拠）
4. AirSpace-Interface-Name属性（ベンダー固有）でもVLAN指定可能

#### eduroamでの活用例

- eduroamユーザ → eduroam用VLAN（インターネットのみ）
- 学内ユーザ → 学内VLAN（学内リソースアクセス可）
- ゲストユーザ → ゲストVLAN（制限付きアクセス）

---

## 5. RADIUS連携

### 5.1 FreeRADIUS連携

Cisco公式ドキュメントにて「Authentication can be done using Cisco ISE, Cisco Catalyst Center, **Free RADIUS**, or any third-party RADIUS Server」と明記されており、FreeRADIUSは公式にサポートされる連携先。

#### Catalyst 9800 WLC での設定例（CLI）

```
! RADIUSサーバ定義
radius server FREERADIUS-1
 address ipv4 <FreeRADIUS-IP> auth-port 1812 acct-port 1813
 key <shared-secret>

! サーバグループ定義
aaa group server radius EDUROAM-RADIUS
 server name FREERADIUS-1

! 認証方式定義
aaa authentication dot1x EDUROAM-METHOD group EDUROAM-RADIUS

! WLAN（SSID）への適用
wlan eduroam 1 eduroam
 security dot1x authentication-list EDUROAM-METHOD

! Policy ProfileでAAA Override有効化（Dynamic VLAN用）
wireless profile policy EDUROAM-POLICY
 aaa-override
 vlan <default-vlan>
```

#### 設定のポイント

- **Shared Secret**: WLC側とFreeRADIUS側（clients.conf）で一致させる
- **CoA (Change of Authorization)**: FreeRADIUSからのCoAパケット受信設定も可能
- **フォールバック**: 複数RADIUSサーバをグループ化してロードバランシング・フェイルオーバーが可能
- **RADIUS DTLS**: IOS XE 17.4以降でRADSEC（RADIUS over DTLS）対応 — eduroamのproxy構成で有用

### 5.2 Meraki での RADIUS設定

1. Dashboard > Wireless > Access Control で SSID を選択
2. Security: WPA2-Enterprise または WPA3-Enterprise を選択
3. RADIUS servers にFreeRADIUSのIP、ポート、共有シークレットを設定
4. RADIUS accounting server も同様に設定

Merakiの場合、eduroam公式ドキュメント（documentation.meraki.com）に「Eduroam Authentication Integration with MR Access Points」という専用ガイドが存在する。

---

## 6. eduroam利用実績

### 6.1 日本の大学での採用事例

| 機関 | 採用製品 | 規模 | 備考 |
|------|---------|------|------|
| **龍谷大学** | Cisco Meraki AP 1,400台以上 + Catalyst L3スイッチ | 3キャンパス | eduroam SSID を含む複数SSID運用 |
| **同志社女子大学** | Cisco Meraki 無線ネットワーク | 全学 | 8,500名に多要素認証 |
| **東京工業大学** | Cisco Meraki | 全学 | 基幹ネットワーク改訂に伴い導入 |
| **東北大学** | （詳細不明、eduroam JP主要参加機関） | 全学 | eduroam JPの推進機関のひとつ |

### 6.2 eduroam JP公式の推奨・要件

eduroam JP（NII）が公開するアクセスポイント選定要件:

1. **必須要件**:
   - IEEE 802.1X EAP対応
   - WPA2 + AES（CCMP）対応（TKIPのみの製品は不可）

2. **推奨要件**:
   - **マルチSSID対応**: eduroam SSIDと自機関SSIDの同時運用
   - **集中管理型コントローラ対応**: コントローラタイプのAPシステム推奨
   - **SSID毎に異なるRADIUSサーバ指定可能**
   - **トンネル対応**: 無線LANトラフィックをコントローラに集約可能

3. **SSID名**: `eduroam`（小文字、eduroam JP規定）

**Cisco Catalyst/Merakiシリーズは上記要件を全て満たす。**

### 6.3 eduroam JPでの推奨状況

eduroam JPは特定ベンダーの推奨はしていないが、技術要件として挙げている項目（802.1X EAP、WPA2/AES、マルチSSID、集中管理型、SSID毎RADIUS指定）は全てCisco Catalyst/Merakiで対応可能。多くの参加機関がCisco製品を採用している実績がある。

---

## 7. 802.11k/v/r対応状況

### 7.1 概要

| 規格 | 機能 | Catalyst 9800対応 |
|------|------|------------------|
| **802.11k** | Radio Resource Management — 隣接AP情報をクライアントに提供 | 対応 |
| **802.11v** | BSS Transition Management — 最適なローミング先APを提案 | 対応 |
| **802.11r** | Fast BSS Transition (FT) — 高速ローミング（認証の事前ネゴシエーション） | 対応 |

### 7.2 Catalyst 9800 WLCでの対応

- IOS XE 16.10以降で802.11k/v/r全て対応
- **WLAN設定でSSID毎に有効/無効を選択可能**
- 802.11rは Over-the-DS（有線経由）と Over-the-Air の両方式に対応

### 7.3 eduroamでの注意事項

- **802.11r (Fast Transition)**: eduroam SSIDでは注意が必要。802.11r非対応の古いクライアントが接続できなくなる可能性がある。eduroam環境では多様なデバイスが接続するため、**FT Transition Mode**（802.11rと非FTの混在）の利用を推奨
- **802.11k/v**: eduroam環境でも問題なく有効化可能。ローミング品質の向上に寄与
- Catalyst 9800では802.11r、802.11k、802.11vそれぞれを個別にSSID単位で制御可能

---

## 8. Passpoint (Hotspot 2.0) 対応

### 8.1 対応状況

- **Catalyst 9800 WLC**: IOS XE 16.12以降でHotspot 2.0 / Passpoint対応
- **OpenRoaming**: IOS XE Amsterdam 17.2.1以降で対応
- **Meraki**: ダッシュボードからHotspot 2.0設定可能

### 8.2 eduroam + Passpoint / OpenRoaming

eduroamではPasspointを使った自動接続（プロファイルレスローミング）が推進されている。

#### Catalyst 9800での設定要素

1. 802.11u Information Element の有効化
2. Roaming Consortium OI の設定:
   - `001BC50460` — eduroam用 Roaming Consortium OI
3. NAI Realm の設定
4. WPA2-Enterprise（802.1X）SSIDへの紐付け

#### Meraki Dashboardでの設定

1. Wireless > Configure > Hotspot 2.0
2. SSIDを選択し、Operator Name を設定
3. Roaming Consortiums に `001BC50460`（eduroam）を追加

### 8.3 将来性

eduroamはOpenRoaming（Wireless Broadband Alliance）との統合を進めており、Passpoint対応APは今後の運用で優位。Cisco Catalyst/Merakiは両方とも対応しているため、将来のOpenRoaming展開にも備えられる。

---

## 9. 価格帯・ライセンス体系

### 9.1 Catalystシリーズ（AP + DNAライセンス）

#### AP本体価格（参考・リストプライス目安）

| モデル | 価格帯（USD参考） | 備考 |
|--------|------------------|------|
| C9105AXI | $300〜500 | エントリーモデル |
| C9120AXI | $800〜1,200 | 中規模向け |
| C9130AXI | $1,200〜1,800 | 大規模向け |
| CW9162I | $800〜1,200 | Wi-Fi 6E エントリー |
| CW9164I | $1,200〜1,600 | Wi-Fi 6E 中規模 |
| CW9166I | $1,600〜2,200 | Wi-Fi 6E ハイエンド |
| CW9172I/H | 要見積 | Wi-Fi 7 新モデル |
| CW9174I/E | 要見積 | Wi-Fi 7 ハイエンド |

> 注: 日本市場での実売価格はリストプライスの40-60%程度になることが多い。代理店見積が必要。

#### Cisco DNA サブスクリプション（必須）

Catalyst 9100シリーズAPの購入時、以下のいずれかのDNAライセンスの同時購入が**必須**:

| ライセンス | 3年 | 5年 | 7年 | 含まれる機能 |
|-----------|-----|-----|-----|-------------|
| **DNA Essentials** | $150〜300/AP | $200〜400/AP | $250〜500/AP | 基本自動化・アシュアランス・位置情報 |
| **DNA Advantage** | $300〜500/AP | $400〜700/AP | $500〜900/AP | SD-Access・高度なセキュリティ・高度な位置情報 |
| **DNA Premier** | — | — | — | Advantage + ISE Base + ISE Plus |

> **注意**: DNA Advantageの5年サブスクリプションがデフォルトで選択される。Essentialsで十分な場合は明示的に変更が必要。

#### プロモーション情報

- 3年以上のDNA Essentials購入で2年分無料
- 3年以上のDNA Advantage購入で1年分無料
（時期により変動、要確認）

### 9.2 Merakiシリーズ（AP + Merakiライセンス）

Merakiは**ライセンスが切れるとAPが動作しなくなる**点に特に注意。

| ライセンス | 1年 | 3年 | 5年 | 7年 | 10年 |
|-----------|-----|-----|-----|-----|------|
| MR Enterprise | $150/AP | $350/AP | $500/AP | $650/AP | $800/AP |
| MR Advanced | より高額 | — | — | — | — |

> 注: MRライセンスはモデル非依存（どのAPモデルでも同一ライセンス）。

### 9.3 WLC（コントローラ）コスト

| WLCモデル | 参考価格（USD） |
|-----------|---------------|
| 9800-L | $7,000〜10,000 |
| 9800-40 | $30,000〜50,000 |
| 9800-80 | $60,000〜100,000 |
| EWC（AP内蔵） | 追加コストなし |

### 9.4 隠れコスト

1. **DNAライセンス更新**: 期間満了後の更新費用（忘れがち）
2. **Merakiライセンス切れ**: ライセンス失効でAPが動作停止（最大のリスク）
3. **SmartNet保守**: ハードウェア保守は別契約
4. **PoEスイッチ**: AP給電用のPoE対応スイッチが必要（別途費用）
5. **ケーブリング**: Cat6A配線（Wi-Fi 6E/7のマルチギガビット対応に必要）
6. **ISEライセンス**: DNA Premierを選択しない場合、Cisco ISEは別途購入（ただしFreeRADIUS利用なら不要）

### 9.5 本プロジェクトでの概算

仮にAP 30台、Catalyst 9120 + EWC + DNA Essentials 3年の場合:

| 項目 | 概算（USD） |
|------|-----------|
| AP本体 (C9120AXI x 30) | $24,000〜36,000 |
| DNA Essentials 3年 (x 30) | $4,500〜9,000 |
| WLC (EWC利用で不要) | $0 |
| **合計** | **$28,500〜45,000** |

Wi-Fi 6E（CW9162I）の場合は AP本体が増額となり合計 $30,000〜50,000程度。

---

## 10. 総合評価・推奨

### 10.1 eduroam導入に対する適合性

| 評価項目 | 評価 | 備考 |
|---------|------|------|
| 802.1X / EAP対応 | A | 全モデル対応、EAP方式制約なし |
| EAP-TTLS/PAP | A | APはパススルー、FreeRADIUSとの組み合わせで動作確認済み |
| WPA2/WPA3-Enterprise | A | 両方対応、Transition Modeも可 |
| Dynamic VLAN | A | 完全対応（RADIUS属性による動的割り当て） |
| マルチSSID | A | 全モデル対応（eduroam + 学内SSID同時運用可） |
| 集中管理 | A | WLC/EWC/Meraki Dashboard選択可能 |
| FreeRADIUS連携 | A | 公式サポート、設定ドキュメントあり |
| 802.11k/v/r | A | 全対応、SSID毎に制御可能 |
| Passpoint/HS2.0 | A | 対応、eduroam OpenRoaming対応可能 |
| 国内実績 | A | 龍谷大学・東工大等、多数の大学で採用 |
| コスト | B | DNAライセンス必須がコスト増要因 |

### 10.2 本プロジェクトへの推奨構成

#### 推奨案1: コスト重視（小規模）
- **AP**: Catalyst CW9162I（Wi-Fi 6E エントリー）
- **WLC**: EWC（AP内蔵、50台以下）
- **ライセンス**: DNA Essentials 3年
- **メリット**: WLC不要、導入コスト最小、Wi-Fi 6E対応
- **留意点**: 管理台数50台まで

#### 推奨案2: バランス型（中規模）
- **AP**: Catalyst CW9164I（Wi-Fi 6E 中規模）
- **WLC**: Catalyst 9800-L
- **ライセンス**: DNA Essentials 5年
- **メリット**: 将来の拡張性、詳細な設定が可能
- **留意点**: WLC追加コスト

#### 推奨案3: クラウド管理型
- **AP**: CWシリーズ（Merakiペルソナ）
- **管理**: Meraki Dashboard
- **ライセンス**: MR Enterprise
- **メリット**: 管理の簡便さ、物理WLC不要
- **留意点**: ライセンス失効リスク、設定の自由度がやや低い

### 10.3 次のステップ

1. **Cisco代理店への見積依頼**: 正確な価格はパートナー経由でのみ入手可能
2. **Phase 5（AP統合・実機テスト）の計画**: 検証用APの貸出・購入検討
3. **ネットワーク設計**: VLAN設計、SSID設計、AP配置設計
4. **PoEスイッチの確認**: 既存スイッチのPoE対応状況確認

---

## 参考資料

### Cisco公式
- [Cisco Catalyst 9100 Access Points](https://www.cisco.com/site/us/en/products/networking/wireless/access-points/catalyst-9100-series/index.html)
- [Cisco Catalyst 9800 Series Wireless Controllers](https://www.cisco.com/site/us/en/products/networking/wireless/wireless-lan-controllers/catalyst-9800-series/index.html)
- [Catalyst 9800 WLC - 802.1X Authentication Configuration](https://www.cisco.com/c/en/us/support/docs/wireless/catalyst-9800-series-wireless-controllers/213919-configure-802-1x-authentication-on-catal.html)
- [Dynamic VLAN Assignment with ISE and Catalyst 9800 WLC](https://www.cisco.com/c/en/us/support/docs/wireless-mobility/wlan-security/217043-configure-dynamic-vlan-assignment-with-c.html)
- [802.11r/11k/11v Fast Roams on 9800 WLCs](https://www.cisco.com/c/en/us/support/docs/wireless/catalyst-9800-series-wireless-controllers/221671-understand-802-11r-11k-11v-fast-roams-on.html)
- [Hotspot 2.0 Configuration (9800 WLC)](https://www.cisco.com/c/en/us/td/docs/wireless/controller/9800/17-15/config-guide/b_wl_17_15_cg/m_hotspot-2.html)
- [Catalyst 9800 WLC RADIUS Configuration](https://www.cisco.com/c/en/us/support/docs/wireless/catalyst-9800-series-wireless-controllers/214490-configure-radius-and-tacacs-for-gui-and.html)
- [Embedded Wireless Controller Data Sheet](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9800-series-wireless-controllers/nb-o6-embded-wrls-cont-ds-cte-en.html)
- [WLC C9800 with EAP-TTLS/PAP (Community)](https://community.cisco.com/t5/wireless/wlc-c9800-with-eap-ttls-pap/td-p/4799226)
- [Wireless 9172 Series Data Sheet](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9100ax-access-points/wireless-9172-series-access-points-ds.html)
- [Wireless 9174 Series Data Sheet](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9100ax-access-points/wireless-9174-series-access-points-ds.html)
- [Catalyst 9162 Series Data Sheet](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9100ax-access-points/cat-9162-series-access-points-ds.html)
- [Catalyst 9166 Series Data Sheet](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9166-series-access-points/catalyst-9166-series-access-points-ds.html)
- [Client Limit Configuration (9800 WLC)](https://www.cisco.com/c/en/us/td/docs/wireless/controller/9800/17-15/config-guide/b_wl_17_15_cg/m_client_limit_ewlc.html)
- [WPA3 Configuration (9800 WLC)](https://www.cisco.com/c/en/us/td/docs/wireless/controller/9800/16-12/config-guide/b_wl_16_12_cg/wpa3.html)
- [DNA Software Subscriptions Ordering Guide](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9100ax-access-points/guide-c07-742134.html)
- [Catalyst 9800 Series FAQ](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9800-series-wireless-controllers/nb-06-cat9800-ser-wirel-faq-ctp-en.html)

### Cisco Meraki
- [Eduroam Authentication Integration with MR Access Points](https://documentation.meraki.com/MR/Encryption_and_Authentication/Eduroam_Authentication_Integration_with_MR_Access_Points)
- [Hotspot 2.0 Configuration Example (Meraki)](https://documentation.meraki.com/MR/Other_Topics/Hotspot_2.0_Configuration_Example)
- [Meraki Access Control](https://documentation.meraki.com/MR/Access_Control_jp)
- [MR License Guide](https://documentation.meraki.com/Platform_Management/Product_Information/Licensing/Meraki_MR_License_Guide)

### eduroam JP / NII
- [eduroam JP - アクセスポイントの選定における注意事項](https://www.eduroam.jp/for_admin/370)
- [eduroam JP サービス技術基準・運用基準](https://www.eduroam.jp/sites/default/files/2022-12/%E5%9B%BD%E7%AB%8B%E6%83%85%E5%A0%B1%E5%AD%A6%E7%A0%94%E7%A9%B6%E6%89%80%20eduroam%20JP%E3%82%B5%E3%83%BC%E3%83%93%E3%82%B9%E6%8A%80%E8%A1%93%E5%9F%BA%E6%BA%96%E3%83%BB%E9%81%8B%E7%94%A8%E5%9F%BA%E6%BA%96.pdf)
- [eduroam導入のチェックポイント](https://www.eduroam.jp/sites/default/files/inline-files/eduroam-checkpoints.pdf)

### eduroam + Passpoint / OpenRoaming
- [GEANT - Roaming on Passpoint-based network infrastructure](https://wiki.geant.org/pages/viewpage.action?pageId=133763844)
- [GEANT - Meraki OpenRoaming configuration snippet](https://wiki.geant.org/pages/viewpage.action?pageId=713752655)
- [eduroam + WPA3-Enterprise + Security](https://markhoutz.com/2024/03/20/eduroam-wpa3-enterprise-security/)

### 導入事例
- [龍谷大学 - Cisco Meraki導入事例](https://meraki.cisco.com/ja/customers/higher-education/ryukoku_daigaku)
- [東京工業大学 - Cisco Meraki導入事例](https://meraki.cisco.com/ja-jp/customers/titech/)

### 価格参考
- [Cisco Global Price List (IT Price)](https://itprice.com/cisco-gpl/catalyst%209800)
- [Comprehensive Comparison of Cisco 9800 Series WLC](https://techblog.kbrosistechnologies.com/a-comprehensive-comparison-of-cisco-9800-series-wlc-choosing-the-right-controller-for-your-enterprise/)
