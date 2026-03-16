# Aruba (HPE Aruba Networking) 無線LANアクセスポイント技術調査

eduroam導入に向けたAruba APの技術調査結果。調査日: 2026-03-16

---

## 1. 現行ラインナップ

Aruba APは大きく3つのカテゴリに分かれる。

### 1.1 Campus AP（エンタープライズ向け、AOS 10 / ArubaOS対応）

eduroamに最も適した製品群。フル機能の802.1X、Dynamic VLAN、Hotspot 2.0に対応。

| シリーズ | 代表型番 | Wi-Fi規格 | MIMO構成 | 最大速度 | バンド | 802.11k/v/r | 最大クライアント/Radio | Ethernet | 参考価格(USD) |
|----------|----------|-----------|----------|----------|--------|-------------|----------------------|----------|--------------|
| **730 Series** (Wi-Fi 7) | AP-734, AP-735 | 802.11be | 2x2 x3 radio | 9.3 Gbps (tri-band) / 14.4 Gbps (dual mode) | 2.4/5/6 GHz | 対応 | 512 | Dual 5GbE | ~$1,370-$1,996 |
| **650 Series** (Wi-Fi 6E Flagship) | AP-655 | 802.11ax | 4x4 x3 radio | 7.8 Gbps | 2.4/5/6 GHz | 対応 | 512 | Dual 5GbE | ~$2,020-$2,635 |
| **630 Series** (Wi-Fi 6E Mid-range) | AP-635 | 802.11ax | 2x2 x3 radio | 3.9 Gbps | 2.4/5/6 GHz | 対応 | 512 | 2.5GbE + 1GbE | ~$1,395 |
| **500 Series** (Wi-Fi 6) | AP-503, AP-505, AP-515, AP-535, AP-555 | 802.11ax | 2x2~8x8 | 1.49~5.4 Gbps | 2.4/5 GHz | 対応 | 256 | 1GbE~5GbE | AP-505: ~$600-800 |

**730 Series の特徴:**
- Ultra Tri-Band (UTB) フィルタリングで干渉を排除
- 内蔵GNSS受信機・気圧センサー（位置情報サービス対応）
- MLO（Multi-Link Operation）、320MHz チャネル幅、4K QAM対応
- AI駆動のRF最適化
- WPA3認定

**500 Series の位置づけ:**
- コスト効率の高いWi-Fi 6エントリーモデル
- 中密度の屋内環境向け
- AP-505が最も一般的なエントリーモデル

### 1.2 Instant On（SMB向け、クラウド管理専用）

| モデル | Wi-Fi規格 | MIMO | 最大速度 | 参考価格(日本) |
|--------|-----------|------|----------|--------------|
| AP22 | Wi-Fi 6 (802.11ax) | 2x2 | 1.77 Gbps | ~4万円前後 |
| AP25 | Wi-Fi 6 (802.11ax) | 4x4 | 5.30 Gbps | ~5.8万円 |
| AP32 | Wi-Fi 6E (802.11ax) | 2x2 x3 | 3.60 Gbps | - |

**eduroam利用における重要な制限事項:**
- **最大25台/サイト**のAP管理上限
- Dynamic VLAN（RADIUS属性による動的VLAN割り当て）の**サポートが限定的**
- Hotspot 2.0 / Passpoint **非対応**
- CLI設定不可（Webアプリ/モバイルアプリのみ）
- **eduroam用途には推奨しない** -- Campus APを推奨

### 1.3 Instant AP (IAP)（コントローラレス・エンタープライズ）

Campus APと同一ハードウェアを使用し、コントローラレスモード（Virtual Controller方式）で動作。
AOS 10移行後はCampus APとInstant APの区別が統合されつつある。

- 最大128台のクラスタ構成（推奨は小規模~中規模）
- Aruba Centralによるクラウド管理に対応
- 802.1X、Dynamic VLAN対応

---

## 2. WPA2/WPA3-Enterprise (802.1X) 対応

### 2.1 対応セキュリティモード

| モード | 対応状況 |
|--------|----------|
| WPA2-Enterprise (802.1X) | 全Campus AP/Instant APで対応 |
| WPA3-Enterprise (CCM 128) | AOS 10以降で対応 |
| WPA3-Enterprise (GCM 256) | AOS 10以降で対応 |
| WPA3-Enterprise (CNSA 192-bit) | AOS 10以降で対応 |
| Transition Mode (WPA2/WPA3混在) | 対応 |

### 2.2 対応EAP方式

Aruba APは802.1X認証においてEAP処理をRADIUSサーバにパススルーする構成が基本。APはEAPメッセージを透過的に中継するため、**RADIUSサーバが対応する全てのEAP方式が利用可能**。

| EAP方式 | 動作可否 | 備考 |
|---------|----------|------|
| **EAP-TTLS/PAP** | **動作可** | APはEAPトンネルを透過。RADIUSサーバ（FreeRADIUS等）で処理。eduroamで広く使用 |
| EAP-PEAP/MSCHAPv2 | 動作可 | 最も一般的な構成 |
| EAP-TLS | 動作可 | 証明書ベース認証 |
| EAP-TTLS/MSCHAPv2 | 動作可 | |
| EAP-TTLS/GTC | 動作可 | |

### 2.3 EAP-TTLS/PAP動作に関する重要事項

- Aruba APは **802.1X Authenticator** として動作し、EAPメッセージをRADIUSサーバに転送するのみ
- EAP-TTLS/PAPの内部認証処理はRADIUSサーバ側（FreeRADIUS等）で完結
- **APの設定では「WPA2-Enterprise」または「WPA3-Enterprise」を選択するだけ**で、EAP方式の指定はAP側では不要
- Google Workspace Secure LDAP + EAP-TTLS/PAP構成は、FreeRADIUSとの組み合わせで問題なく動作する

---

## 3. 集中管理機能

### 3.1 Aruba Central（クラウド管理 SaaS）

| 項目 | 内容 |
|------|------|
| 形態 | クラウドSaaS（オンプレミス版 Central On-Premises も存在） |
| 管理対象 | AP、スイッチ、ゲートウェイ |
| 管理台数上限 | 実質無制限（ライセンス数による） |
| Zero Touch Provisioning | 対応（APを接続するだけで自動構成） |
| AI機能 | AIOps（障害予兆検知、RF最適化、クライアントトラブルシューティング） |
| ファームウェア管理 | Live Upgrade対応（サービス中断最小化） |
| 対応OS | AOS 10（推奨）、AOS 8 |

**ライセンス体系:**

| ライセンス | 対象 | 特徴 |
|-----------|------|------|
| **Foundation** | 全デバイス共通 | 基本的なネットワーク管理機能。中小規模・K12向け |
| **Advanced** | 全デバイス共通 | AIOps拡張、プレミアム機能追加。大規模キャンパス向け |

- **ライセンス期間**: 1年 / 3年 / 5年 / 7年 / 10年のサブスクリプション
- **課金単位**: デバイス単位（AP 1台につき1ライセンス）
- **ソフトウェアメンテナンス**: ライセンスに含まれる

### 3.2 Mobility Controller / Gateway

AOS 8ではMobility Controller（ハードウェアコントローラ）によるオンプレミス管理が中心。AOS 10では「Gateway」と呼称が変更。

**7200 Series Mobility Controller:**

| モデル | 最大AP管理数 | ポート構成 |
|--------|-------------|-----------|
| 7205 | 256 AP | 2x 10GbE (SFP+), 4x Dual Media |
| 7210 | 512 AP | 4x 10GbE (SFP/SFP+), 2x Dual Media |
| 7220 | 1,024 AP | 2x 40GbE (QSFP+), 8x 10GbE (SFP+) |
| 7240/7240XM | 2,048 AP | 4x 40GbE, 8x 10GbE |

**AOS 10移行における変化:**
- Mobility Controllerは「Gateway」に移行
- クラウド管理（Central）が標準に
- コントローラレス運用が可能（APがAOS 10を直接実行）
- **小規模構成ではコントローラ不要**（Central + APのみで運用可能）

---

## 4. VLAN対応

### 4.1 タグVLAN

- 全Campus APでIEEE 802.1Qタグ VLANに完全対応
- AP接続スイッチポートはトランクポートとして設定
- SSID毎に異なるVLAN IDを割り当て可能
- AP管理VLANはネイティブVLANとして設定

### 4.2 Dynamic VLAN（RADIUS属性による動的割り当て）

**完全対応（Campus AP / Instant AP）。** RADIUSサーバからのAccess-Acceptに含まれるVLAN属性に基づき、クライアントを動的にVLANに割り当てる。

**対応RADIUS属性:**

| 属性 | 値 | 説明 |
|------|----|----- |
| Tunnel-Type (64) | VLAN (13) | 必須 |
| Tunnel-Medium-Type (65) | IEEE-802 (6) | 必須 |
| Tunnel-Private-Group-Id (81) | VLAN ID番号 | 必須。VLAN番号を指定 |

**Aruba VSA（Vendor Specific Attribute）:**
- `Aruba-User-Vlan`: Aruba独自のVLAN割り当て属性。標準IETF属性の代替として使用可能
- FreeRADIUSの`post-auth`セクションでVSAを設定

**FreeRADIUSでの設定例:**
```
# users ファイルまたは post-auth セクション
Tunnel-Type := VLAN,
Tunnel-Medium-Type := IEEE-802,
Tunnel-Private-Group-Id := "100"
```

### 4.3 eduroamにおけるVLAN設計

- eduroamユーザ用の専用VLANを作成
- 認証前: 制限付きVLAN（eduroam-logon ロール）
- 認証後: eduroam用VLANに動的割り当て
- ローカルユーザとeduroamビジターで異なるVLANに分離可能

---

## 5. RADIUS連携

### 5.1 FreeRADIUS連携

FreeRADIUSとの連携は広く実績があり、問題なく動作する。

**設定のポイント:**

1. **NASクライアント設定**: Aruba AP/ControllerのIPアドレスをFreeRADIUSの`clients.conf`に登録
2. **Shared Secret**: AP/Controllerとの共有シークレットを一致させる
3. **認証ポート**: 標準の1812（認証）/1813（アカウンティング）
4. **EAPパススルー**: APはEAPメッセージをそのままFreeRADIUSに転送

**Instant AP（コントローラレス）の場合の注意:**
- Virtual Controller（VC）がRADIUS通信の代表IPとなる
- NASクライアント設定はVCのIPアドレスで行う
- 各APのIPを個別登録する必要がない

**Controller構成の場合:**
- ControllerのIPアドレスをNASクライアントとして登録
- 複数Controllerがある場合はそれぞれ登録

### 5.2 Aruba ClearPass

Aruba純正のRADIUS/NAC製品。eduroamとの統合ガイドがGEANTから公式に提供されている。

- **本プロジェクトではFreeRADIUSを使用するため不要**
- ClearPassなしでもeduroamは構成可能

### 5.3 RADIUS設定手順（Aruba Controller/Central）

1. RADIUS Server作成（Configuration > Authentication > Servers > RADIUS Server > Add）
2. RADIUS Server Group作成
3. 802.1X Group Auth Profile作成
4. User Role定義（eduroam-logon: 認証前、eduroam-user: 認証後）
5. AAA Profile作成
6. SSID Profile作成（SSID名: "eduroam"）

---

## 6. eduroam利用実績

### 6.1 概要

**Arubaはeduroamにおいて最も多くの実績を持つ無線LANベンダーの一つ。** 世界中の大学・研究機関で採用されている。

### 6.2 公式ガイド・推奨状況

| ドキュメント | 発行元 | 内容 |
|-------------|--------|------|
| **"Guide to Configuring eduroam Using the Aruba Wireless Controller and ClearPass"** (CBP-79 / GN4-NA3-UFS139) | GEANT | Aruba Controller + ClearPassでのeduroam構成の公式ベストプラクティス |
| **Aruba eduroam Wiki** | GEANT | Aruba機器でのeduroam設定手順 |
| **ArubaOS OpenRoaming configuration snippets** | GEANT | Passpoint/OpenRoaming対応のCLI設定例 |

### 6.3 日本国内の採用事例

| 機関名 | 導入内容 | パートナー |
|--------|----------|-----------|
| **東京大学 大学院理学系研究科** | Aruba AP-125 x250台、Aruba 6000 Controller | エイチ・シー・ネットワークス (HCNET) |
| **慶應義塾大学** | Aruba無線LAN全学導入 | HPE Aruba公式事例 |
| **駿河台大学** | Wi-Fi 6対応AP、eduroam対応、最大2,000同時接続 | HCNET |
| **大阪府立大学** | eduroam対応、学生・教職員・来訪者の認証分離 | HCNET |
| **神戸大学** | Aruba Controller + AP約400台、eduroam RADIUS連携 | - |

### 6.4 日本市場でのパートナー

| 会社名 | 役割 |
|--------|------|
| エイチ・シー・ネットワークス (HCNET) | Aruba国内最大手代理店。大学向けeduroam導入実績多数 |
| 日立ソリューションズ | セキュア無線LANシステムとしてArubaを販売 |
| マクニカ | Aruba正規代理店。技術情報・FAQ提供 |
| SB C&S | Aruba Central等の販売 |
| SCSK | 無線LAN製品販売 |
| 富士通 | OEM/販売パートナー |

### 6.5 AXIES 2024での展示

2024年12月、HCNETとHPE Aruba Networkingが「AXIES 2024」（大学ICT推進協議会年次大会、奈良コンベンションセンター）に共同出展。Wi-Fi 7製品、Central、大学DX向け認証ソリューションを展示。

---

## 7. 802.11k/v/r対応状況

### 7.1 対応状況一覧

| 規格 | 機能 | Campus AP対応 | Instant On対応 |
|------|------|-------------|---------------|
| **802.11k** | Radio Resource Management（近隣AP情報提供） | 全モデル対応 | 限定的 |
| **802.11v** | BSS Transition Management（AP移行指示） | 全モデル対応（802.11k有効化時に自動有効） | 限定的 |
| **802.11r** | Fast BSS Transition（高速ローミング） | 全モデル対応 | 非対応 |

### 7.2 設定方法（Campus AP / AOS 10）

- **802.11k**: SSID設定のFast Roamingタブで有効化
- **802.11v**: 802.11k有効化時にデフォルトで有効
- **802.11r**: Fast Roamingタブで有効化、MDID（Mobility Domain Identifier）を指定
- **OKC (Opportunistic Key Caching)**: 802.11rの代替として利用可能

### 7.3 Aruba独自のローミング最適化

- **ClientMatch**: Arubaの独自技術。802.11k/vを補完し、クライアントを最適なAPに誘導
- **Key Management Service (KMS)**: AOS 10で802.11r R1キーをAP間で分散管理
- **ARM (Adaptive Radio Management)**: AI駆動のRF最適化

### 7.4 eduroamにおける802.11r利用の注意

- 802.11rはSSID内でのローミングを高速化するが、**一部の古いクライアントデバイスとの互換性問題**がある
- eduroamのように多様なクライアントが接続する環境では、802.11rを**無効にするか、transition modeで運用**することが推奨される場合がある
- 802.11k/vは互換性リスクが低く、有効化を推奨

---

## 8. Passpoint (Hotspot 2.0) 対応

### 8.1 対応状況

| 項目 | 対応状況 |
|------|----------|
| Hotspot 2.0 Release 1 | Campus AP全モデルで対応 |
| Hotspot 2.0 Release 2 | Campus AP全モデルで対応 |
| Passpoint Release 3 | 新機種で対応 |
| OpenRoaming | 対応（GEANT公式設定例あり） |
| 802.11u (ANQP) | 対応 |
| Instant On | **非対応** |

### 8.2 eduroam + Passpoint設定

ArubaOS CLIでの設定項目:
- **Hotspot Profile**: HS2.0有効化、GAS comeback delay設定
- **ANQP Venue Profile**: 会場情報（Venue Group: Education-Research, Venue Type: University）
- **ANQP Roaming Consortium Profile**: RCOI設定
- **NAI Realm Profile**: 認証方式のアドバタイズ
- **Advertisement Profile**: 上記プロファイルの集約

**eduroam関連のRCOI:**

| RCOI | 名称 | 説明 |
|------|------|------|
| `001BC50460` | eduroam | eduroam公式RCOI |
| `5A03BA0000` | OpenRoaming-All | WBA OpenRoaming（全ID、無料） |
| `004096` | OpenRoaming (Cisco Legacy) | 旧Cisco OpenRoaming RCOI |

### 8.3 将来的な展望

eduroamはPasspoint/OpenRoamingとの統合が進んでおり、Aruba Campus APでこれらに対応しておくことで、将来の自動接続（プロファイルレス接続）への移行が容易になる。

---

## 9. 価格帯・ライセンス体系

### 9.1 アクセスポイント参考価格

| シリーズ | 代表モデル | 米国参考価格(USD) | 日本市場目安 | 備考 |
|----------|-----------|------------------|-------------|------|
| 730 (Wi-Fi 7) | AP-735 | $1,370~$1,996 | 20~30万円程度 | 最新ハイエンド |
| 650 (Wi-Fi 6E) | AP-655 | $2,020~$2,635 | 25~35万円程度 | フラッグシップ 4x4 |
| 630 (Wi-Fi 6E) | AP-635 | ~$1,395 | 18~25万円程度 | ミッドレンジ 2x2 |
| 500 (Wi-Fi 6) | AP-505 | ~$600~800 | 10~15万円程度 | エントリー |
| Instant On | AP25 | - | ~5.8万円 | SMB向け（eduroam非推奨） |

※日本市場価格は代理店・ボリュームにより変動。要見積もり。

### 9.2 Aruba Centralライセンス

| ライセンス | 期間 | 概算(AP1台あたり/年) | 備考 |
|-----------|------|---------------------|------|
| Foundation (1年) | 1年 | 数千~1万円程度 | 基本管理機能 |
| Foundation (3年) | 3年 | 割引あり | 一括購入で割安 |
| Advanced (1年) | 1年 | Foundation + α | AIOps、プレミアム機能 |
| Advanced (3年) | 3年 | 割引あり | |

**Centralライセンスの必要性:**
- AOS 10運用ではCentral Foundationが**事実上必須**（Zero Touch Provisioning、ファームウェア管理）
- AOS 8 + Controller構成であればCentralなしでも運用可能
- **eduroam運用に最低限必要なのはFoundationライセンス**

### 9.3 Mobility Controller / Gateway

| モデル | 概算参考価格 | 備考 |
|--------|-------------|------|
| 7005 | 数十万円 | 小規模（最大16AP） |
| 7008 | 数十万円 | 小規模 |
| 7205 | 100万円前後 | 中規模（最大256AP） |
| 7210 | 150~200万円 | 中~大規模（最大512AP） |

**AOS 10ではController不要の構成が可能**であり、小~中規模環境ではCentral + APのみの構成が推奨される。

---

## 10. 神戸電子専門学校への推奨構成

### 10.1 推奨AP

| 優先度 | モデル | 理由 |
|--------|--------|------|
| **第1候補** | **AP-635 (630 Series)** | Wi-Fi 6E対応、ミッドレンジ価格、eduroam実績豊富なCampus AP。2x2 MIMOで教室環境に十分 |
| 第2候補 | AP-505 (500 Series) | Wi-Fi 6対応、最もコスト効率が高い。6GHz不要なら最適 |
| 将来投資 | AP-735 (730 Series) | Wi-Fi 7対応、最新規格。予算に余裕があれば |

### 10.2 推奨管理構成

| 構成 | 方式 | 備考 |
|------|------|------|
| **推奨** | AOS 10 + Aruba Central (Foundation) | コントローラ不要、クラウド管理、ZTP対応 |
| 代替 | AOS 8 + Mobility Controller (7005/7205) | オンプレ完結。Centralサブスクリプション不要 |

### 10.3 eduroam構成の概要

```
[クライアント] --802.1X/EAP-TTLS-- [Aruba AP] --RADIUS-- [FreeRADIUS] --LDAP-- [Google Workspace]
                                                                |
                                                          [eduroam JP FLR]
                                                          (Proxy RADIUS)
```

- APの設定: WPA2-Enterprise SSID「eduroam」を作成、FreeRADIUSをRADIUSサーバとして指定
- APはEAPパススルーのみ。内部認証は全てFreeRADIUS側
- Dynamic VLANでeduroamユーザを専用VLANに割り当て

### 10.4 コスト見積もり（概算）

教室・共有スペース20教室程度を想定した場合:

| 項目 | 数量 | 単価目安 | 小計 |
|------|------|---------|------|
| AP-635 | 20台 | 20万円 | 400万円 |
| Central Foundation 3年 | 20ライセンス | 2万円/台 | 40万円 |
| PoEスイッチ | 2~3台 | 15万円 | 45万円 |
| 設計・導入費用 | - | - | 100~200万円 |
| **合計** | | | **585~685万円** |

※上記は概算。代理店見積もりで大幅に変動する可能性あり。教育機関向け割引の適用可能性あり。

---

## 11. まとめ・所見

### Arubaの強み
1. **eduroam実績が最も豊富**なベンダーの一つ。GEANTから公式設定ガイドが提供されている
2. **Passpoint/OpenRoaming対応**が充実しており、eduroamの将来方向と合致
3. 日本国内に**HCNET、日立ソリューションズ、マクニカ**等の強力な代理店網
4. **FreeRADIUSとの連携**に問題なし（EAPパススルー方式）
5. **802.11k/v/r**、**Dynamic VLAN**、**WPA3-Enterprise**等のeduroam関連機能が全て対応
6. AOS 10 + Centralでコントローラレス運用が可能（初期コスト削減）

### 注意点
1. **Instant Onはeduroamに不適** -- 必ずCampus APを選択すること
2. Central **サブスクリプションが継続コスト**として発生（AOS 10利用時）
3. ClearPass不要だが、**FreeRADIUS構成は自前で行う**必要がある
4. 802.11rは多様なクライアント環境では互換性注意

### 他ベンダーとの比較における位置づけ
- **Cisco**: 同等の実績あり。CatalystやMerakiと比較するとArubaはAI/ML機能で先行
- **UniFi**: 低コストだがエンタープライズ機能で劣る
- Arubaは**価格と機能のバランス**が良く、eduroam用途では最有力候補の一つ

---

## 参考リンク

### 公式ドキュメント
- [HPE Aruba Networking Access Points](https://www.hpe.com/us/en/aruba-access-points.html)
- [HPE Aruba Networking 730 Series](https://www.arubanetworks.com/products/wireless/access-points/indoor-access-points/730-series/)
- [HPE Aruba Networking 650 Series](https://www.arubanetworks.com/products/wireless/access-points/indoor-access-points/650-series/)
- [AOS 10 Roaming and Key Management Service](https://arubanetworking.hpe.com/techdocs/aos/aos10/services/roaming/)
- [WPA3-Enterprise TechDocs](https://arubanetworking.hpe.com/techdocs/aos/wifi-design-deploy/security/modes/wpa3-enterprise/)
- [User VLANs (Dynamic VLAN)](https://arubanetworking.hpe.com/techdocs/aos/aos10/design/vlans/)
- [Hotspot 2.0 TechDocs](https://arubanetworking.hpe.com/techdocs/ArubaOS_8.12.0_Web_Help/Content/arubaos-solutions/hotspot/hosp2.htm)
- [Passpoint Service Profile Configuration (Central)](https://arubanetworking.hpe.com/techdocs/central/2.5.7/content/nms/access-points/cfg/networks/passpoint.htm)

### eduroam設定ガイド
- [GEANT: Guide to Configuring eduroam Using the Aruba Wireless Controller and ClearPass (PDF)](https://archive.geant.org/projects/gn3/geant/services/cbp/Documents/cbp-79_guide_to_configuring_eduroam_using_the_aruba_wireless_controller_and_clearpass.pdf)
- [GEANT: Aruba eduroam Wiki](https://wiki.geant.org/display/H2eduroam/aruba)
- [GEANT: ArubaOS OpenRoaming configuration snippets](https://wiki.geant.org/display/H2eduroam/ArubaOS+(stand-alone)+OpenRoaming+configuration+snippets)
- [GEANT: ArubaOS (controller) OpenRoaming configuration snippet](https://wiki.geant.org/spaces/H2eduroam/pages/273481745/ArubaOS+controller+OpenRoaming+configuration+snippet)
- [Jisc: Aruba ClearPass Configuration for eduroam](https://community.jisc.ac.uk/library/network-and-technology-service-docs/aruba-clearpass-configuration-eduroam)
- [eduroam on Aruba and Microsoft NPS (Blog)](https://gshaw0.wordpress.com/2019/03/06/eduroam-on-aruba-and-microsoft-nps-an-end-to-end-guide/)

### 日本国内リソース
- [eduroam JP](https://www.eduroam.jp/)
- [HCNET 導入事例一覧](https://www.hcnet.co.jp/case/)
- [日立ソリューションズ Aruba APラインナップ](https://www.hitachi-solutions.co.jp/aruba/products/wi-fi/spec-ap.html)
- [マクニカ Aruba AP仕様](https://www.macnica.co.jp/en/business/network/manufacturers/aruba/ap_spec.html)
- [SB C&S Aruba Central](https://www.it-ex.com/products/maker/hpe-aruba/aruba-central.html)
- [ATC Aruba価格情報](https://www.atc.jp/aruba-price/)
- [HCNET Wi-Fi 7 Campus AP](https://www.hcnet.co.jp/products/wireless/wifi/wi-fi_7_campus_ap.html)

### RADIUS連携
- [FreeRADIUS: Aruba-User-Vlan VSA](https://lists.freeradius.org/pipermail/freeradius-users/2009-October/041732.html)
- [EAP-TTLS/PAP authentication for network users (Aruba Community)](https://airheads.hpe.com/discussion/eap-ttlspap-authentication-for-network-users)
- [Dynamic VLAN assignment with Aruba (Community)](https://community.arubanetworks.com/discussion/dynamic-vlan-assignment-using-radius-attribute-filter-id)
