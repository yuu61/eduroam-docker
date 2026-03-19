# アクセスポイント ベンダー調査

eduroam導入に向けた無線LANアクセスポイントの技術調査。
対象: Cisco, Aruba (HPE), Juniper (Mist), Ubiquiti UniFi, YAMAHA WLX, Buffalo AirStation Pro

調査日: 2026-03-16

---

## 5ベンダー総合比較

| 項目 | Cisco Catalyst/Meraki | Aruba (HPE) | Juniper Mist | Ubiquiti UniFi | YAMAHA WLX | Buffalo AirStation Pro |
|------|----------------------|-------------|-------------|----------------|------------|----------------------|
| WPA2-Enterprise | 対応 | 対応 | 対応 | 対応 | 対応 | 対応 |
| WPA3-Enterprise | 対応 | 対応 | 対応 | 対応（Wi-Fi 6+） | 対応 | 対応（Wi-Fi 6世代） |
| EAP-TTLS/PAP | 動作する（パススルー） | 動作する（パススルー） | 動作する（パススルー） | 動作する（パススルー） | 動作する | 動作する |
| 802.11k/v/r | 全対応（SSID毎制御可） | 全対応（ClientMatch独自技術あり） | 全対応（k/vデフォルト有効） | 全対応（r は独自実装） | Wi-Fi 6世代で対応 | Wi-Fi 6世代で対応 |
| OKC/FTデフォルト有効 | **OKC+FT(Adaptive)** | OKCのみ（FT手動） | **FT有効**（OKC手動） | いずれも手動 | 不明 | 不明 |
| Dynamic VLAN | 完全対応 | 完全対応（VSAあり） | 完全対応 | 対応 | 記載なし | 記載なし |
| Passpoint/HS2.0 | 対応（OpenRoaming含む） | 対応（OpenRoaming含む） | 対応（OpenRoaming含む） | 対応（v8.4+） | 未対応 | 未対応 |
| FreeRADIUS連携 | 公式サポート | 実績多数 | 実績あり | 実績多数 | 標準RADIUSでOK | 技術的に問題なし |
| eduroam実績 | 龍谷大学、東工大等多数 | 東京大学理学系、慶應、駿河台等多数 | 東京大学（7,500台）、追手門学院等 | GEANT wikiに設定ガイドあり | 確認できず | 確認できず |
| GEANT公式ガイド | Meraki設定ガイドあり | CBP-79公式ガイドあり | Mist Edge eduroamガイドあり | OpenRoaming設定スニペットあり | なし | なし |
| 集中管理 | WLC/EWC/Meraki Dashboard | Central/Controller/IAP | Mist Cloud（AI駆動） | UniFi Network App（無料） | クラスター（128台） | WLS-ADT（別売SW、3,000台） |
| **オンプレWLC** | **9800-L/40/80/CL/EWC** | **Mobility Controller/Central On-Prem** | **不可**（クラウド必須） | **セルフホスト可** | 仮想コントローラ（簡易） | なし（監視SWのみ） |
| 管理台数上限 | EWC: 50台、9800-L: 250台 | Central: 実質無制限 | クラウド: 実質無制限 | セルフホスト: 実質無制限 | 128台/クラスター | 3,000台 |
| ライセンス | DNA必須（サブスクリプション） | Central Foundation推奨 | Wi-Fi Assurance必須 | **不要** | 不要 | 不要 |
| AP単価目安 | Wi-Fi 6: $800-1,200 | Wi-Fi 6: $600-800 | Wi-Fi 6E: $500-1,200 | Wi-Fi 7: **$99-299** | 7.2-12.8万円 | 2.9-9.9万円 |
| 30台5年TCO概算 | $28,500-50,000 | $25,000-45,000 | $25,000-40,000 | **$5,670** | — | — |

### eduroam導入適合性ランキング

| ランク | ベンダー | 理由 |
|--------|---------|------|
| **S** | **Aruba** | eduroam実績最多級、GEANT公式ガイド（CBP-79）、Passpoint/OpenRoaming完全対応、国内代理店（HCNET等）充実 |
| **S** | **Cisco** | eduroam実績豊富、Meraki専用eduroamガイド、Passpoint対応、ただしコスト高 |
| **A** | **Juniper Mist** | 東大7,500台の実績、AI駆動管理、Mist Edge eduroam公式サポート、クラウド依存が懸念 |
| **A** | **Ubiquiti** | GEANT設定ガイドあり、圧倒的低コスト、Passpoint対応、ただしサポート体制が弱い |
| **B** | **YAMAHA** | 技術要件は充足、eduroam実績なし、国内ベンダーで安心感あり |
| **B** | **Buffalo** | 技術要件は充足、eduroam実績なし、既存環境の流用に向く |

### ベンダー別詳細レポート

- [Cisco Catalyst / Meraki](vendors/cisco-catalyst-meraki.md)
- [Aruba (HPE)](vendors/aruba-hpe.md)
- [Juniper Mist](vendors/juniper-mist.md)
- [Ubiquiti UniFi](vendors/ubiquiti-unifi.md)

---

## Cisco Catalyst / Meraki

### 現行ラインナップ

Catalystシリーズ（オンプレミス管理）とMeraki（クラウド管理）の2系統。CWシリーズは両方のペルソナで動作可能。

#### Wi-Fi 6

| モデル | ラジオ構成 | 最大クライアント/AP | 用途 |
|--------|-----------|---------------------|------|
| **C9105AXI** | 2x2 + 2x2 | 400 | エントリー |
| **C9120AXI** | 4x4 + 4x4 + BLE | 400 | 中規模キャンパス |
| **C9130AXI** | 4x4 + 4x4 + RF ASIC | 400 | 大規模 |
| **C9136I** | 4x4 + 4x4 + スキャンラジオ | 1,200 | 高密度 |

#### Wi-Fi 6E

| モデル | ラジオ構成 | 用途 |
|--------|-----------|------|
| **CW9162I** | 3x 2x2 (2.4/5/6GHz) | エントリー |
| **CW9164I** | 2x2 + 2x 4x4 | 中〜大規模 |
| **CW9166I** | 3x 4x4 + センサー | 大規模 |

#### Wi-Fi 7

| モデル | 特徴 |
|--------|------|
| **CW9172I/H** | トライバンド、ブランチ・寮向け |
| **CW9174I/E** | 10空間ストリーム、5Gbps uplink |

### WPA2/WPA3-Enterprise

- 全モデル対応。WPA3-Enterprise（192-bit含む）はIOS XE 17.x以降
- **EAP-TTLS/PAP**: APはEAPパススルーとして動作。EAP方式を解釈しない。FreeRADIUS側の設定のみで動作
- Cisco Community公式で動作確認済み

### 集中管理

| 管理方式 | 管理AP数 | 特徴 |
|---------|---------|------|
| **EWC（AP内蔵）** | 50台 | 追加ハードウェア不要、小規模最適 |
| **9800-L** | 250台 | アプライアンス、$7,000〜 |
| **9800-40** | 2,000台 | 中〜大規模 |
| **9800-CL** | 1,000-6,000台 | 仮想（VM） |
| **Meraki Dashboard** | 制限なし | クラウド管理、ライセンス失効でAP停止リスク |

### VLAN

- タグVLAN: 全機種対応
- **Dynamic VLAN: 完全対応**。AAA Override有効化でRADIUS属性（Tunnel-Type/Medium-Type/Private-Group-Id）による動的割り当て

### RADIUS連携

公式ドキュメントでFreeRADIUS連携を明示的にサポート。Catalyst 9800 WLC CLI設定例あり。
RADIUS DTLS（RadSec）はIOS XE 17.4以降で対応。

### eduroam実績

| 機関 | 製品 | 規模 |
|------|------|------|
| 龍谷大学 | Meraki 1,400台+ | 3キャンパス |
| 同志社女子大学 | Meraki | 全学 |
| 東京工業大学 | Meraki | 全学 |

### Passpoint / OpenRoaming

- Catalyst 9800: IOS XE 16.12以降でHotspot 2.0対応、17.2.1以降でOpenRoaming対応
- Meraki: ダッシュボードから設定可能
- eduroam RCOI `001BC50460` の設定が可能

### 価格・ライセンス

- **DNAサブスクリプション必須**（AP購入時に同時購入）
- DNA Essentials 3年: $150-300/AP、DNA Advantage 5年: $400-700/AP
- **Merakiライセンス失効でAP動作停止**（重大リスク）
- 30台（C9120 + EWC + DNA Essentials 3年）概算: **$28,500〜45,000**（約430万〜680万円）

---

## Aruba (HPE Aruba Networking)

### 現行ラインナップ

#### Campus AP（eduroam推奨）

| シリーズ | Wi-Fi規格 | MIMO | 最大速度 | 最大クライアント/Radio | 参考価格(USD) |
|----------|-----------|------|----------|----------------------|--------------|
| **730 Series** (Wi-Fi 7) | 802.11be | 2x2 x3 | 9.3-14.4 Gbps | 512 | $1,370-1,996 |
| **650 Series** (Wi-Fi 6E) | 802.11ax | 4x4 x3 | 7.8 Gbps | 512 | $2,020-2,635 |
| **630 Series** (Wi-Fi 6E) | 802.11ax | 2x2 x3 | 3.9 Gbps | 512 | ~$1,395 |
| **500 Series** (Wi-Fi 6) | 802.11ax | 2x2~8x8 | 1.49-5.4 Gbps | 256 | $600-800 |

#### Instant On（SMB向け）— eduroamに不適

- 最大25台/サイト、Dynamic VLAN限定的、Hotspot 2.0非対応、CLI不可
- **eduroam用途には必ずCampus APを選択すること**

### WPA2/WPA3-Enterprise

- 全Campus APで対応。WPA3-Enterprise（CNSA 192-bit含む）はAOS 10以降
- **EAP-TTLS/PAP**: AP側は「WPA2-Enterprise」選択のみ。EAP方式指定不要。Google Workspace LDAP + FreeRADIUS構成で動作確認済み

### 集中管理

| 管理方式 | 特徴 |
|---------|------|
| **Aruba Central（クラウド）** | SaaS、ZTP対応、AIOps、実質無制限 |
| **Central On-Premises** | オンプレミス版あり |
| **Mobility Controller（AOS 8）** | ハードウェアWLC、7205: 256AP、7220: 1,024AP |
| **IAP（コントローラレス）** | Virtual Controller方式、最大128台クラスタ |

- AOS 10ではController不要の構成が可能（Central + APのみ）

### VLAN

- タグVLAN: 全Campus AP対応
- **Dynamic VLAN: 完全対応**。標準RADIUS属性 + Aruba VSA（Aruba-User-Vlan）の両方に対応
- eduroamユーザの認証前/認証後ロール分離が可能

### RADIUS連携

- FreeRADIUSとの連携は広く実績あり
- IAP構成: Virtual ControllerのIPをNASクライアントとして登録（個別AP登録不要）
- ClearPassは本プロジェクトでは不要（FreeRADIUS使用）

### eduroam実績

**eduroamにおいて最も実績のあるベンダーの一つ。** GEANTからCBP-79公式ガイドが提供されている。

| 機関 | 導入内容 | パートナー |
|------|---------|-----------|
| 東京大学 理学系研究科 | AP-125 x250台、6000 Controller | HCNET |
| 慶應義塾大学 | 全学導入 | HPE Aruba公式事例 |
| 駿河台大学 | Wi-Fi 6 AP、最大2,000同時接続 | HCNET |
| 大阪府立大学 | 認証分離（学生/教職員/来訪者） | HCNET |
| 神戸大学 | AP約400台 | — |

国内代理店: **HCNET**（最大手、大学向け実績多数）、日立ソリューションズ、マクニカ、SB C&S

### Passpoint / OpenRoaming

- Campus AP全モデルでHotspot 2.0 Release 1/2対応
- OpenRoaming対応、GEANTにCLI設定スニペットあり
- **Instant Onは非対応**

### 802.11k/v/r + 独自技術

- 802.11k/v/r: 全Campus APで対応
- **ClientMatch**: Aruba独自のクライアント誘導技術（802.11k/vを補完）
- **OKC**: 802.11rの代替として利用可能
- eduroamでは802.11rはtransition mode推奨（多様なクライアント対応）

### 価格・ライセンス

- Central Foundation（事実上必須、AOS 10時）: APあたり数千〜1万円/年
- AOS 8 + Controller構成ならサブスクリプション不要
- 20台（AP-635 + Central Foundation 3年）概算: **585〜685万円**（設計・導入費含む）

---

## Juniper Mist

### 現行ラインナップ

#### Wi-Fi 7

| モデル | 用途 | 最大データレート | PoE要件 |
|--------|------|------------------|---------|
| **AP47** | 屋内フラッグシップ | 6GHz: 11.5Gbps | 802.3bt |
| **AP37/AP36** | 屋内ハイエンド | 17.98 Gbps | 802.3bt |
| **AP66/AP66D** | 屋外 | 6GHz: 5.8Gbps | 802.3bt、IP67 |

#### Wi-Fi 6E

| モデル | 用途 | PoE要件 | 特徴 |
|--------|------|---------|------|
| **AP45** | 屋内ハイエンド | 802.3bt | フラッグシップWi-Fi 6E |
| **AP34** | 屋内ミドル | Dynamic PoE (20.9W) | コスパ重視 |
| **AP24** | 屋内エントリー | 802.3af | 既存PoEスイッチ流用可 |

#### Wi-Fi 6

| モデル | 備考 |
|--------|------|
| **AP43** | ハイエンド |
| **AP32** | スタンダード、**東京大学で約7,500台導入** |

- 同時接続: 各ラジオ最大128クライアント、AP全体256〜384クライアント

### WPA2/WPA3-Enterprise

- 全モデル対応。WPA3-Enterprise 192-bitも対応（ただしEAP-TLS必須、802.11r使用不可）
- **EAP-TTLS/PAP**: パススルーモードで動作確認済み。公式ドキュメントにEAP-TTLSクライアント設定ガイドあり

### 集中管理（Mist Cloud / Mist AI）

- **完全クラウドベース管理**: 物理コントローラ不要
- **AIエンジン「Marvis」**: プロアクティブなトラブルシューティング、自然言語クエリ
- 管理台数: **制限なし**（ライセンス数による）。東大7,500台を一元管理
- **完全オンプレミスは不可**: クラウド接続必須
- **Mist Edge**: データプレーンのみローカル処理。RADIUS Proxy機能あり（eduroam連携で重要）

### VLAN

- タグVLAN: 完全対応
- **Dynamic VLAN: 完全対応**。Tunnel-Private-Group-Id（標準方式）とAirespace-Interface-Name方式の2種

### RADIUS連携

- FreeRADIUS連携実績あり
- eduroam構成: **Mist Edge Proxy経由が推奨**（RADIUS Proxy + IdP分離）
- CoA（Change of Authorization）対応、ポート3799

### eduroam実績

**Juniper公式でMist Edge Proxy for eduroamを文書化。**

| 機関 | 規模 | 備考 |
|------|------|------|
| **東京大学** | AP32 x7,500台、3キャンパス | ピーク18,000同時接続 |
| **追手門学院大学** | 340台 | EXスイッチ170台、SRXゲートウェイ |
| University of Oxford | 5年計画で全学展開中 | eduroam/OWL SSID |
| University of Plymouth | 900台+ | 3週間で交換完了 |

### Passpoint / OpenRoaming

- 対応（ファームウェア0.8.21116以降）
- RadSecサポート、AP証明書プロビジョニング可能
- OpenRoaming Passpoint設定にも対応

### 802.11k/v/r

- 802.11k/v: **デフォルト有効**
- 802.11r: WLANごとに手動有効化。Hybrid/Mixed mode対応（非対応クライアントと共存可能）

### 価格・ライセンス

- **Wi-Fi Assuranceサブスクリプション必須**（APはライセンスなしでは動作しない）
- AP単価: エントリーAP24 $500-800、ミドルAP34 $800-1,200、ハイエンドAP45/47 $1,500-3,000
- サブスクリプション: $150-300/AP/年（Wi-Fi Assurance）
- eduroam構成ではMist Edgeの追加購入が必要（ME-X1: 500AP対応、ME-VM: 仮想版）
- 国内販売代理店: ソフトバンク、日立ソリューションズ、ネットワンパートナーズ、ジェイズ・コミュニケーション

---

## Ubiquiti UniFi

### 現行ラインナップ

#### Wi-Fi 7

| モデル | バンド | アップリンク | 同時接続 | 価格(USD) |
|--------|--------|-------------|---------|-----------|
| **U7 Lite** | デュアル(2.4/5) | 2.5GbE | 300+ | **$99** |
| **U7 Pro** | トライバンド(2.4/5/6) | 2.5GbE | 300+ | **$189** |
| **U7 Pro Max** | トライバンド | 2.5GbE | 300+ | $279 |
| **U7 Pro XG** | トライバンド | 10GbE | 300+ | $199 |
| **U7 Pro XGS** | トライバンド | 10GbE RJ45 | 300+ | $299 |

#### Wi-Fi 6/6E

| モデル | バンド | 価格(USD) |
|--------|--------|-----------|
| U6 Lite | デュアル | $99 |
| U6 Pro | デュアル(4x4) | $159 |
| U6 Enterprise | トライバンド(6E) | $279 |

### WPA2/WPA3-Enterprise

- 全モデル対応。WPA3-EnterprisはWi-Fi 6以降
- **EAP-TTLS/PAP**: パススルーで動作。GitHubに実構成ガイド（unifi-okta-radius-eap-ttls）あり

### 集中管理（UniFi Network Application）

- **ライセンス費用: 完全無料**
- セルフホスト（Linux）で実質無制限のAP管理
- Cloud Key Gen2+: 40台まで、UDM-SE: 大規模向け
- セルフホスト要件: Ubuntu 23.04+ / Debian 12+、Podman 4.3.1+、メモリ2GB+

### VLAN

- タグVLAN: 全モデル対応
- **Dynamic VLAN: 対応**。RADIUS属性（Tunnel-Type/Medium-Type/Private-Group-Id）で動的割り当て
- 「RADIUS assigned VLAN」オプションをGUIで有効化

### RADIUS連携

- FreeRADIUSとの組み合わせで多数の実績
- **RadSec（RADIUS over TLS）**: UniFi Network 8.4+で対応（ポート2083）
- APは自身のIPをNAS-IP-Addressとして送信（サブネット指定が管理しやすい）

### eduroam実績

- GEANTの公式wikiにUniFi向けOpenRoaming設定スニペットが掲載
- 大学での採用: Mount St. Mary's University（米国）等
- **日本国内の大学でのeduroam利用実績は限定的**

### Passpoint / OpenRoaming

- UniFi Network 8.4.54以降で対応
- GEANT公式wikiにeduroam OpenRoaming設定手順あり
- Roaming Consortium OI `001BC50460` の設定が可能

### 802.11k/v/r

- 802.11k/v: 対応（WiFi設定で有効化）
- 802.11r: **Ubiquiti独自実装**（Fast Roaming）— 約90%のローミング改善、後方互換性あり
- 純粋な802.11rではないが実用上問題なし

### 価格・ライセンス

- **ライセンス不要 — 最大の優位性**
- AP単価: $99〜$299（他ベンダーの1/3〜1/10）
- 30台5年TCO: **約$5,670**（Cisco Merakiの約1/7）

### エンタープライズ用途の制約

- サポートはコミュニティベース中心（24/7エンタープライズサポートなし）
- 100台超の大規模管理ではAruba/Ciscoに劣る
- WIDs/WIPs等の高度なセキュリティ機能が限定的
- コントローラHA（冗長構成）のサポートが限定的
- 明確なSLA保証なし

---

## YAMAHA WLX シリーズ

### 現行ラインナップ

| 型番 | Wi-Fi規格 | 802.11k/v/r | 同時接続 | 内蔵RADIUS | 価格（税込） | 管理方式 |
|------|-----------|-------------|---------|-----------|-------------|---------|
| **WLX323** | Wi-Fi 6E (ax) | 全対応 | 270台 | 1,000件 | 127,600円 | クラスター/YNO |
| **WLX322** | Wi-Fi 6 (ax) | 全対応 | 170台 | 1,000件 | 103,400円 | クラスター/YNO |
| **WLX222** | Wi-Fi 6 (ax) | 全対応 | 140台 | 1,000件 | 71,500円 | クラスター/YNO |
| WLX413 | Wi-Fi 6 (ax) | 全対応 | 500台 | 4,000件 | — | クラスター/YNO |
| WLX313 | Wi-Fi 5 (ac Wave2) | **非対応** | 150台 | 300件 | — | グループ型（旧方式） |

- WLX413は生産完了品。
- WLX313は802.11k/v/r非対応かつ旧管理方式のため、ローミングが重要な環境では不向き。

### WPA2-Enterprise (802.1X) 対応

全機種対応。対応EAP方式（外部RADIUSサーバー利用時）:
- EAP-TLS、EAP-TTLS/MSCHAPv2、PEAPv0/EAP-MSCHAPv2、PEAPv1/EAP-GTC
- EAP-SIM / EAP-AKA（WLX322/WLX413/WLX323）
- EAP-AKA' / EAP-FAST（WLX322）

eduroamで使用するEAP-TTLS/PAPについて: APはEAP-TTLSの外側トンネルのみ関与し、内部認証方式（PAP/MSCHAPv2）はRADIUSサーバー側の処理。EAP-TTLS対応があれば問題なく動作する。

### 集中管理機能（クラスター管理）

仮想コントローラー方式。専用ハードウェアコントローラーは不要。

- 同一L2ネットワーク上のAP群から自動的に「リーダーAP」を選出
- リーダーAPが仮想コントローラーとして動作し、設定を全APに配信
- リーダー障害時は約5分で他のAPが自動昇格（フェイルオーバー）
- 1クラスターあたり最大 **128台**（WLX322/WLX323/WLX413がリーダーの場合）
- WLX222/WLX322/WLX323/WLX413の混在クラスターが可能（WLX313は互換性なし）
- YNO（Yamaha Network Organizer）によるクラウド管理にも対応

### VLAN対応

- タグVLAN (IEEE 802.1Q): 全機種対応、VLAN ID 1-4094
- マルチSSID: 最大16個（WLX323）
- Dynamic VLAN（RADIUS属性による動的割り当て）: **公式ドキュメントに明示的な記載なし**

### eduroam利用実績

公式ドキュメント・eduroam JP公式サイトのいずれにも、WLXシリーズのeduroam利用実績の記載は確認できず。
技術要件（WPA2-Enterprise、外部RADIUS連携、マルチSSID、タグVLAN）は全て満たしている。

---

## Buffalo AirStation Pro シリーズ

### 現行ラインナップ

| 型番 | Wi-Fi規格 | 802.11k/v/r | 同時接続 | マルチSSID | 参考価格 |
|------|-----------|-------------|---------|-----------|---------|
| **WAPM-AXETR** | Wi-Fi 6E (ax) | 全対応 | 768台 (256x3) | 最大48個 | 約99,420円 |
| **WAPM-AX8R** | Wi-Fi 6 (ax) | 全対応 | 512台 (256x2) | 最大32個 | 約86,800円 |
| **WAPM-AX4R** | Wi-Fi 6 (ax) | 全対応 | 256台 (128x2) | 最大32個 | 約57,000円 |
| WAPM-AX4 | Wi-Fi 6 (ax) | 対応 | 128台 | — | 約29,742円 |
| WAPM-2133TR | Wi-Fi 5 (ac) | **非対応** | 384台 (3バンド) | 最大48個 | 約24,423円 |
| WAPM-2133R | Wi-Fi 5 (ac) | **非対応** | 256台 | 最大32個 | 約54,780円 |
| WAPM-1266R | Wi-Fi 5 (ac) | **非対応** | 256台 | — | 約25,811円 |
| WAPM-1266WDPR | Wi-Fi 5 (ac) | **非対応** | — | — | 約63,162円 (屋外) |
| WAPM-1266WDPRA | Wi-Fi 5 (ac) | **非対応** | — | — | 約89,100円 (IP55防塵防水) |

### WPA2-Enterprise (802.1X) 対応

全モデル対応。対応セキュリティモード:
- WPA2 Enterprise (WPA2-EAP AES)
- WPA/WPA2 Enterprise (mixed mode)
- WPA3 Enterprise（Wi-Fi 6世代: WAPM-AX4R, AX8R, AXETR）
- WPA3 Enterprise 192-bit Security（同上）

対応EAP方式: TLS / TTLS / PEAP。EAP-TTLS/PAPはAPとしてはトンネリングをRADIUSサーバに中継するだけなので問題なし。

### 集中管理機能（WLS-ADT）

別売のWindows管理ソフトウェア（USBメモリで配布）。

- 最大 **3,000台** のAP管理が可能
- 死活監視（PING監視 + メールアラート）
- ファームウェア一括更新・設定バックアップ/リストア
- 不正AP検出
- 自動電波調整（チャンネル・送信出力の最適化）
- SNMP v1/v2c/v3対応

注意: WLS-ADTは管理・監視ソフトウェアであり、トラフィック集約型WLCではない。各APは自律型（Autonomous）として動作する。

### VLAN対応

- タグVLAN (802.1Q): 全機種対応、最大32個（WAPM-2133TRは48個）、VID 1-4096
- ポートベースVLAN: 対応
- Dynamic VLAN（RADIUS属性による動的割り当て）: **公式ドキュメントに記載なし**

### RADIUS連携の動作確認済み製品

| ベンダー | 製品名 |
|---------|--------|
| エイチ・シー・ネットワークス | Account@Adapter+ V7 |
| SingleID | SingleIDクラウドRADIUS |
| ソリトンシステムズ | OneGate |
| ソリトンシステムズ | NetAttest EPS |
| ペンティオ | SecureW2 |
| YEデジタル | NetSHAKER W-NAC |

FreeRADIUSとの公式動作確認はないが、標準RADIUSプロトコルを使用するため技術的には問題ない。

### eduroam利用実績

公式ページ・製品ページ・設定事例ページのいずれにもeduroamの記載は確認できず。
大規模大学ではCisco、Aruba(HPE)、Juniper(Mist)の採用が多い傾向にある。

---

## オンプレミスWLC比較

eduroam運用ではオンプレミスにWLC（Wireless LAN Controller）を設置できる構成が好ましい。インターネット障害時にも管理プレーンが機能し続けること、ライセンス失効によるAP停止リスクがないことが理由。

### オンプレミスWLC対応状況

| ベンダー | オンプレWLC | 形態 | クラウド管理（併用） | 評価 |
|---------|-----------|------|-------------------|------|
| **Cisco** | Catalyst 9800-L/40/80/CL、EWC（AP内蔵） | アプライアンス / VM / AP内蔵 | Meraki Dashboard（別系統） | **最適** |
| **Aruba** | Mobility Controller 7205/7210/7220/7240（AOS 8）、Central On-Premises | アプライアンス / オンプレSaaS | Aruba Central (SaaS) | **最適** |
| **Ubiquiti** | UniFi Network Application（セルフホスト） | ソフトウェア（Linux VM） | UDM / Cloud Key | **対応** |
| YAMAHA | クラスター管理（リーダーAP＝仮想コントローラ） | AP間分散（専用HW不要） | YNO | 簡易的 |
| Juniper Mist | **不可** — Mist Edgeはデータプレーンのみ、管理プレーンはクラウド必須 | — | Mist Cloud（必須） | **不適** |
| Buffalo | **不可** — WLS-ADTは監視ソフトのみ、WLC機能なし | — | なし | **不適** |

### Cisco Catalyst 9800 WLC

オンプレミスWLCの最も成熟した選択肢。

| モデル | 形態 | 管理AP数 | 最大クライアント数 | 参考価格 |
|--------|------|---------|-------------------|---------|
| **EWC** | AP内蔵 | 50台 | 1,000 | 追加コストなし |
| **9800-L** | アプライアンス | 250台 | 5,000 | $7,000〜 |
| **9800-40** | アプライアンス | 2,000台 | 32,000 | 要見積 |
| **9800-80** | アプライアンス | 6,000台 | 64,000 | 要見積 |
| **9800-CL** | 仮想（VM） | 1,000-6,000台 | 16,000-64,000 | ソフトウェアライセンス |

- EWCはC9105/9115/9117に内蔵。小規模（50台以下）であれば専用WLCハードウェア不要
- 9800-Lは$7,000程度で250台まで管理可能。中規模の教育機関に最適
- IOS XE上で動作し、CLI/GUI両方から詳細設定が可能
- 802.11k/v/rをSSID単位で制御可能
- RADIUS DTLS（RadSec）対応（IOS XE 17.4以降）
- インターネット障害時もWLCとAP間の管理は完全にローカルで動作

### Aruba Mobility Controller

AOS 8系でのオンプレミス管理。AOS 10ではGatewayと呼称変更。

| モデル | 管理AP数 | ポート構成 | 参考価格 |
|--------|---------|-----------|---------|
| **7205** | 256台 | 2x 10GbE + 4x Dual Media | 100万円前後 |
| **7210** | 512台 | 4x 10GbE + 2x Dual Media | 150〜200万円 |
| **7220** | 1,024台 | 2x 40GbE + 8x 10GbE | 要見積 |
| **7240/7240XM** | 2,048台 | 4x 40GbE + 8x 10GbE | 要見積 |

- AOS 8 + Controller構成なら**Centralサブスクリプション不要**でオンプレ完結
- Central On-Premises: Aruba Centralのオンプレミス版も存在（VMware上にデプロイ）
- IAP（Instant AP）モード: コントローラレスでVirtual Controller方式（128台クラスタ、追加HW不要）
- ClientMatch（独自ローミング最適化）はController配下で最も効果的に動作
- GEANTのCBP-79ガイドはController構成を前提に記述されている

### Ubiquiti UniFi Network Application

ソフトウェアベースのオンプレミスコントローラ。

| ホスティング方式 | 管理台数 | 要件 | コスト |
|----------------|---------|------|--------|
| **セルフホスト（Linux VM）** | 実質無制限 | Ubuntu 23.04+ / Debian 12+、Podman 4.3.1+、メモリ2GB+ | VPSコストのみ |
| Cloud Key Gen2+ | 40台 | 専用ハードウェア | $199 |
| UDM-SE | 大規模 | ゲートウェイ内蔵 | $499 |

- **ライセンス費用完全不要** — ソフトウェア自体が無料
- セルフホストならサーバ上でコントローラが常時稼働し、クラウド依存なし
- ただし、Cisco/Arubaに比べて高度な設定（RF最適化、WIDs等）は限定的
- HA（冗長構成）のサポートが限定的
- エンタープライズサポートがコミュニティベース中心

### YAMAHA クラスター管理

WLCとは異なるが、AP間で自律的に管理機能を分担する方式。

- リーダーAPが仮想コントローラとして機能（専用ハードウェア不要）
- 設定配信・同期はL2ネットワーク内で自動
- リーダー障害時は約5分で自動昇格（フェイルオーバー）
- 128台/クラスターの上限あり
- 専用WLCの機能（トラフィック集約、高度なRF管理等）は持たない
- eduroamのSSID配信・RADIUS設定の一括管理には十分だが、ローミング最適化はWLCほど高度ではない

### Juniper Mist — オンプレ管理不可

- **管理プレーンが完全クラウド依存**。インターネット障害時は設定変更・監視が不能
- Mist Edgeはデータプレーン（ユーザートラフィック）のみローカル処理
- APはクラウドへの常時接続を前提としており、接続断時は既存設定で動作継続するが管理不能
- オンプレミスWLCを重視する場合、**Juniper Mistは候補から外れる**

### オンプレWLC観点での推奨

| 規模 | 第1候補 | 第2候補 | 備考 |
|------|--------|--------|------|
| 小規模（〜50台） | **Cisco EWC** | Ubiquiti セルフホスト | EWCは追加HW不要、Ubiquitiは最安 |
| 中規模（50〜250台） | **Cisco 9800-L** | **Aruba 7205** | 両方とも実績十分 |
| 中〜大規模（250台+） | **Aruba 7210/7220** | Cisco 9800-40/CL | Arubaはサブスクなしで運用可（AOS 8） |

---

## ローミングに関する注意事項

### 802.11k/v/rの制約

802.11k/v/rはIEEE標準規格だが、実際に機能するには共通の管理プレーン（WLC/クラスター）が必要。

- **802.11k（Neighbor Report）**: 近隣AP情報はWLC/コントローラーが管理・配布する。管理ドメインが異なるAPの情報は配信されない。
- **802.11v（BSS Transition）**: ローミング先APの提案にはAP情報の共有が前提。異なる管理ドメインのAPは提案対象にならない。
- **802.11r（Fast BSS Transition）**: PMK（鍵情報）のAP間共有が必要。異なるWLC/クラスター間ではPMKを共有できない。

### マルチベンダー環境での影響

- 異なるベンダー間: 802.11k/v/rは一切機能しない。完全にクライアント自律判断。
- 同一ベンダーでもWi-Fi 5世代は802.11k/v/r非対応。
- クライアント自律のフル再認証でも、EAP-TTLS/PAPは比較的軽量で体感1〜2秒程度。

### eduroamでの802.11r利用の注意

- 802.11rは古いクライアントとの互換性問題がある
- eduroamのように多様なデバイスが接続する環境では **transition mode（混在モード）** を推奨
- 802.11k/vは互換性リスクが低く、有効化を推奨

### 用途別影響度

| 用途 | 影響 |
|------|------|
| Web閲覧・メール | ほぼ気にならない |
| ファイルダウンロード | TCP再送で吸収 |
| VoIP・ビデオ通話 | 途切れが起きうる |
| リアルタイムゲーム | 切断扱いになりうる |

### 緩和策

- 棟内で同一ベンダーが揃っていれば、棟内は高速ローミング可能（Wi-Fi 6世代の場合）
- 棟間移動は屋外歩行を伴うため、再接続遅延が目立ちにくい
- RADIUSサーバの応答速度を速く保つ（ローカル設置、LDAPクエリ最適化）

---

## WLC側のRADIUS再認証削減機能

Google Workspace Secure LDAP をバックエンドに使用する場合、LDAP クォータ制限（bind 4 QPS/顧客）が存在する。
WLC 側の高速ローミング・キャッシュ機能を活用することで、RADIUS 再認証（= Google LDAP へのクエリ）を大幅に削減できる。

詳細な試算は [Google Secure LDAP 技術調査](../infrastructure/google-secure-ldap-802.1x-feasibility.md) を参照。

### 高速ローミング技術の概要

| 技術 | 標準規格 | 仕組み | RADIUS再認証 | クライアント対応 |
|------|---------|--------|-------------|----------------|
| **PMKSA Caching** | IEEE 802.11i | 以前接続した AP の PMK をキャッシュし再接続時に再利用 | **スキップ**（同一APのみ） | ほぼ全端末 |
| **OKC** | 非標準（デファクト） | WLC が PMK を管理下の全 AP に配布。未訪問 AP でも 4-way handshake のみ | **スキップ** | Windows、一部Android。**iOS非対応** |
| **802.11r（FT）** | IEEE 802.11r | PMK-R0→R1→PTK の3層鍵階層。4フレーム交換のみでローミング | **スキップ** | iOS、Android、Windows（新しめ） |
| **802.11k** | IEEE 802.11k | AP がネイバーリストを提供、スキャン時間短縮 | 関与しない | 広く対応 |
| **802.11v（BSS-TM）** | IEEE 802.11v | AP が最適なローミング先を勧告 | 関与しない | 広く対応 |

> **ポイント**: OKC と 802.11r が有効な環境では、初回認証時のみ RADIUS → Google LDAP クエリが発生し、AP 間ローミング時の再認証は**完全にスキップ**される。

### ベンダー別の高速ローミング対応（デフォルト設定）

#### Cisco Catalyst 9800

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching（SKC） | 非推奨 | 無効 | Catalyst 9800 では deprecated |
| **OKC** | **対応** | **有効** | 初回 EAP 後、全 AP で 4-way handshake のみ。FT/CCKM 有効化時は自動無効 |
| **802.11r（FT）** | **対応** | **有効（Adaptive）** | Over-the-Air / Over-the-DS 両対応。Adaptive でレガシー端末との互換性維持 |
| 802.11k | 対応 | 有効 | ネイバーリスト提供 |
| 802.11v（BSS-TM） | 対応 | 有効 | 負荷分散 |
| Session-Timeout | 設定可 | 1800秒（旧）/ 43200秒（新） | **推奨: 86400秒（1日）**。0 は非推奨（ローミング不具合の原因） |

**評価**: OKC + 802.11r Adaptive がデフォルト有効で、**追加設定なしで RADIUS 再認証がローミング時にスキップ**される。最も手厚い実装。

#### Cisco Meraki

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching | **対応** | **有効** | 全 AP で自動有効 |
| **OKC** | **対応** | **有効** | 全 AP で自動有効。Windows・一部 Android が対応 |
| **802.11r（FT）** | **対応** | **無効** | `Configure > Access control` から手動有効化。NAT mode / L3 roaming では利用不可 |
| Adaptive 802.11r | 対応 | — | WPA2 のみ。WPA3 では自動 Enabled |
| 802.11k | 対応 | 有効 | ネイバーリスト |
| 802.11v（BSS-TM） | 対応 | **有効**（MR29.1+） | 負荷ベースの AP 推奨 |

**注意**: CoA（Change of Authorization）有効時は高速ローミングが無効化される制約があったが、MR32.1.x + ISE 3.3 Patch 5 以降で共存可能に。

**評価**: OKC デフォルト有効で OKC 対応端末は再認証スキップ可能。802.11r は手動有効化が必要。

#### Aruba（HPE Aruba Networking）

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching | **対応** | 有効 | 標準 PMK キャッシュ |
| OKC | **対応** | **無効** | 手動有効化が必要。KMS が PMK を管理下 AP に配布 |
| **802.11r（FT）** | **対応** | **有効** | MDID（Mobility Domain ID）の設定を推奨 |
| 802.11k | 対応 | 推奨（有効化） | 802.11r と併用推奨 |
| ClientMatch | 対応 | 有効 | Aruba独自のクライアント誘導技術 |

**評価**: 802.11r デフォルト有効で、**追加設定なしで RADIUS 再認証スキップ**。MDID を適切に設定することで大規模キャンパスでの高速ローミングを最適化。

#### Juniper Mist

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching | **対応** | **ローカルのみ** | AP 間の PMK 共有なし。同一 AP への再接続時のみ |
| OKC | **対応** | **無効** | 手動有効化。クラウド経由で隣接 AP に PMKID 配布。**iOS 非対応** |
| 802.11r（FT） | **対応** | **無効** | Security セクションから手動有効化 |
| FT Over-the-DS | 対応 | 無効 | Zebra 端末等の互換性オプション |

**制約**:
- WPA2 では OKC 選択不可（Default / .11r のみ）。WPA3 では Default / OKC / .11r から選択可
- 設定変更時に AP 無線がリセットされ、接続中のクライアントが一時切断

**評価**: **デフォルトではローカル PMKSA キャッシュのみ**で AP 間ローミング時に完全再認証が発生。クォータ削減には手動設定が必須。

#### Ubiquiti UniFi

| 機能 | 対応 | デフォルト | 備考 |
|------|------|-----------|------|
| PMKSA Caching | **対応** | 有効 | 標準 PMK キャッシュ |
| OKC | 不明 | — | 明示的な OKC 対応の記載なし |
| Fast Roaming（独自） | **対応** | 有効化可 | 802.11r ベースの Ubiquiti 独自実装。約90%のローミング改善 |
| 802.11k/v | 対応 | 設定で有効化 | — |

**評価**: 独自 Fast Roaming で実用的なローミング改善は可能だが、OKC 対応が不明確。エンタープライズ向け WLC ほどの細かい制御はできない。

#### YAMAHA WLX / Buffalo AirStation Pro

| 機能 | YAMAHA WLX | Buffalo AirStation Pro |
|------|-----------|----------------------|
| PMKSA Caching | Wi-Fi 6世代で対応 | Wi-Fi 6世代で対応 |
| OKC | 不明（記載なし） | 不明（記載なし） |
| 802.11r | Wi-Fi 6世代で対応 | Wi-Fi 6世代で対応 |
| WLC による鍵配布 | 非対応（クラスター管理は簡易的） | 非対応（WLC機能なし） |

**評価**: 802.11r 対応はあるが、WLC による集中的な鍵管理がないため、OKC のような AP 間 PMK 共有は期待できない。ローミング時の RADIUS 再認証スキップは 802.11r 対応端末に限定される。

### ベンダー比較サマリ（RADIUS 再認証削減の観点）

| 機能 | Catalyst 9800 | Meraki | Aruba | Juniper Mist | UniFi | YAMAHA | Buffalo |
|------|:------------:|:------:|:-----:|:------------:|:-----:|:------:|:-------:|
| OKC デフォルト有効 | **有** | **有** | 無 | 無 | 不明 | 不明 | 不明 |
| 802.11r デフォルト有効 | **有（Adaptive）** | 無 | **有** | 無 | 無 | — | — |
| 追加設定なしで再認証スキップ | **可** | **可**（OKC端末のみ） | **可** | **不可** | 限定的 | 限定的 | 限定的 |
| Session-Timeout 延長 | **推奨86400秒** | RADIUS依存 | 設定可 | 設定可 | 設定可 | 設定可 | 設定可 |

### Google Secure LDAP クォータとの関係

WLC 側の高速ローミング機能と FreeRADIUS 側の `cache_auth` を組み合わせた場合:

| レイヤー | 対策 | 削減対象 | 効果 |
|---------|------|---------|------|
| **WLC** | OKC / 802.11r | AP 間ローミング時の RADIUS 再認証 | Google LDAP クエリ = **0** |
| **WLC** | Session-Timeout 延長 | 定期再認証の頻度 | 3600秒→86400秒で **24分の1** |
| **FreeRADIUS** | cache_auth_accept | Session-Timeout 満了時の再認証 | キャッシュヒット時の Google LDAP クエリ = **0** |
| **FreeRADIUS** | cache_ldap_user_dn | ユーザー DN 検索 | search クエリを削減（bind のみ） |

> **結論**: Cisco Catalyst 9800 または Aruba であれば、デフォルト設定で OKC/802.11r による再認証スキップが機能し、FreeRADIUS の cache_auth と併用することで Google Secure LDAP の 4 QPS 制限は実運用上問題にならない。Juniper Mist は手動設定が必須、YAMAHA/Buffalo は WLC 機能の制約から効果が限定的。

### 参考資料（ローミング・高速ローミング）

- [Catalyst 9800: A Primer on Enterprise WLAN Roaming - Cisco](https://www.cisco.com/c/en/us/products/collateral/wireless/catalyst-9800-series-wireless-controllers/cat9800-ser-primer-enterprise-wlan-guide.html)
- [Understand 802.11r/11k/11v Fast Roams on 9800 WLCs - Cisco](https://www.cisco.com/c/en/us/support/docs/wireless/catalyst-9800-series-wireless-controllers/221671-understand-802-11r-11k-11v-fast-roams-on.html)
- [OKC on Catalyst 9800 - Cisco](https://www.cisco.com/c/en/us/td/docs/wireless/controller/9800/17-6/config-guide/b_wl_17_6_cg/m_okc.html)
- [Roaming Technologies - Cisco Meraki](https://documentation.meraki.com/Wireless/Design_and_Configure/Architecture_and_Best_Practices/Roaming_Technologies)
- [Configuring Support for 802.11r and OKC - Aruba](https://arubanetworking.hpe.com/techdocs/Instant_810_WebHelp/Content/instant-ug/wlan-ssid-conf/conf-fast-roam.htm)
- [RSSI, Roaming, and Fast Roaming - Juniper Mist](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/topic-map/rssi-fast-roaming.html)
- [Session-Timeout, RADIUS and PMK caching - Cisco Community](https://community.cisco.com/t5/wireless/session-timeout-radius-and-pmk-caching/td-p/2983309)

---

## コスト比較（AP 30台想定）

### イニシャルコスト（初期導入費用）

導入時に発生する一括費用の概算。1 USD ≈ 150円換算。

| 項目 | Cisco Catalyst (C9120+EWC) | Aruba (AP-500+7205, AOS 8) | Juniper Mist (AP34) | UniFi (U7 Pro) | YAMAHA (WLX322) | Buffalo (WAPM-AX4R) |
|------|---------------------------|---------------------------|--------------------|-----------------|-----------------|--------------------|
| AP本体（30台） | 360〜540万円 | 270〜360万円 | 360〜540万円 | **約85万円** | 約310万円 | 約171万円 |
| WLC/管理基盤 | 0円（EWC内蔵） 〜105万円（9800-L） | 約100万円（7205） | 0円（クラウド管理） | 0円（セルフホスト） | 0円（クラスター管理） | 別売SW（WLS-ADT） |
| 必須ライセンス | 68〜135万円（DNA Essentials 3年） | 0円（AOS 8構成時） | 68〜135万円（Wi-Fi Assurance初年） | **0円** | 0円 | 0円 |
| **イニシャル合計** | **約430〜780万円** | **約370〜460万円** | **約430〜675万円** | **約85万円** | **約310万円** | **約175万円** |

- **最安**: Ubiquiti（約85万円）— 桁違いに安いが、サポート体制が弱い
- **国産最安**: Buffalo（約175万円）— eduroam実績なし、WLC機能なし
- **コスパ良**: YAMAHA（約310万円）— eduroam実績なし、クラスター管理で簡易的
- **実績重視**: Aruba AOS 8構成（約370〜460万円）— サブスクなしでオンプレ完結、eduroam実績最多級
- **最も高機能**: Cisco（約430〜780万円）— DNAサブスクリプション必須でコスト高

### 5年運用TCO（AP＋ライセンス）

| 項目 | Cisco (C9120+EWC) | Aruba (AP-635+Central) | Juniper (AP34+Mist) | UniFi (U7 Pro) | YAMAHA (WLX322) | Buffalo (WAPM-AX4R) |
|------|-------------------|----------------------|--------------------|-----------------|-----------------|--------------------|
| AP本体 | $24,000-36,000 | $41,850 | $24,000-36,000 | **$5,670** | 約310万円 | 約171万円 |
| WLC/コントローラ | $0 (EWC) | $0 (Central) | $0 (Cloud) | $0 (セルフホスト) | $0 (クラスター) | — |
| ライセンス (5年) | $4,500-9,000 | 約60万円 | $22,500-45,000 | **$0** | $0 | $0 |
| 設計・導入 | 要見積 | 要見積 | 要見積 | 自前可 | 自前可 | 自前可 |
| **AP+ライセンス合計** | **$28,500-45,000** | **約500-685万円** | **$46,500-81,000** | **$5,670** | **約310万円** | **約171万円** |

※ 為替レート・代理店割引・教育機関向け割引により大幅に変動。正確な価格は見積もりが必要。設計・導入費（SIer費用）、PoEスイッチ、ケーブリング費用は別途。

---

## 現状の課題

- 学内の既存APはWi-Fi 4/5世代が大半で、802.11k/v/r対応機種が極めて少ない（Wi-Fi 6はELECOM 1台のみ確認）
- ベンダーが4社混在（YAMAHA, Buffalo, ICOM, ELECOM）— 統一管理が困難
- オープン/暗号化なしのSSIDが2件存在（SHOKUINSHITSU, WAVEMASTER-0）— セキュリティリスク
- 802.11g/a + TKIP の極めて古いAP（SOFTBUNYA34）が稼働中
- 既存APの正確な機種は管理画面/SNMPでの確認が必要（BSSIDベースの推定のみ）

> 詳細な調査結果は [既存AP調査](existing-ap-survey.md) を参照

## 今後のアクション

1. ~~各棟のAP機種リストを入手し、WPA2-Enterprise対応を確認する~~ → 北野校舎4F付近は調査済み。他の棟・階でも同様のスキャンを実施する
2. YAMAHA APの正確な機種を管理画面またはSNMPで特定する
3. eduroamは既存APのWPA2-Enterprise対応で導入可能（AP更新は別タイムライン）
4. AP更新計画時に、ベンダー統一と802.11k/v/r対応を考慮する
5. 代理店への見積もり依頼（教育機関向け割引の確認）
6. PoEスイッチの既存対応状況を確認する
7. オープンネットワーク（SHOKUINSHITSU, WAVEMASTER-0）のセキュリティ改善

---

## 参考資料

### Cisco
- [Catalyst 9100 Access Points](https://www.cisco.com/site/us/en/products/networking/wireless/access-points/catalyst-9100-series/index.html)
- [Catalyst 9800 WLC](https://www.cisco.com/site/us/en/products/networking/wireless/wireless-lan-controllers/catalyst-9800-series/index.html)
- [Meraki eduroam Integration](https://documentation.meraki.com/MR/Encryption_and_Authentication/Eduroam_Authentication_Integration_with_MR_Access_Points)
- [Dynamic VLAN with ISE and 9800 WLC](https://www.cisco.com/c/en/us/support/docs/wireless-mobility/wlan-security/217043-configure-dynamic-vlan-assignment-with-c.html)
- [WLC C9800 with EAP-TTLS/PAP (Community)](https://community.cisco.com/t5/wireless/wlc-c9800-with-eap-ttls-pap/td-p/4799226)

### Aruba
- [GEANT CBP-79: eduroam + Aruba Controller + ClearPass](https://archive.geant.org/projects/gn3/geant/services/cbp/Documents/cbp-79_guide_to_configuring_eduroam_using_the_aruba_wireless_controller_and_clearpass.pdf)
- [GEANT: Aruba eduroam Wiki](https://wiki.geant.org/display/H2eduroam/aruba)
- [GEANT: ArubaOS OpenRoaming configuration snippets](https://wiki.geant.org/display/H2eduroam/ArubaOS+(stand-alone)+OpenRoaming+configuration+snippets)
- [AOS 10 Roaming TechDocs](https://arubanetworking.hpe.com/techdocs/aos/aos10/services/roaming/)
- [Hotspot 2.0 TechDocs](https://arubanetworking.hpe.com/techdocs/ArubaOS_8.12.0_Web_Help/Content/arubaos-solutions/hotspot/hosp2.htm)

### Juniper Mist
- [Mist Edge Proxy for eduroam](https://www.juniper.net/documentation/us/en/software/mist/mist-access/topics/topic-map/mist-edge-proxy-eduroam.html)
- [802.1X WLAN設定](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/topic-map/radius-configuration.html)
- [Dynamic VLAN設定](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/task/mist-dynamic-vlans.html)
- [東京大学 Mist導入事例](https://www.juniper.net/us/en/customers/the-university-of-tokyo-case-study.html)
- [Passpoint設定](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/task/passpoint.html)

### Ubiquiti UniFi
- [UniFi WiFi Tech Specs](https://techspecs.ui.com/unifi/wifi)
- [RADIUS Server設定](https://help.ui.com/hc/en-us/articles/360015268353-Configuring-a-RADIUS-Server-in-UniFi)
- [Passpoint設定](https://help.ui.com/hc/en-us/articles/25473982758551-Setting-Up-Passpoint-on-UniFi-Network)
- [GEANT: UniFi OpenRoaming configuration snippet](https://wiki.geant.org/pages/viewpage.action?pageId=831553537)

### eduroam JP
- [eduroam JP - AP選定における注意事項](https://www.eduroam.jp/for_admin/370)
- [eduroam JPサービス技術基準・運用基準](https://www.eduroam.jp/)
