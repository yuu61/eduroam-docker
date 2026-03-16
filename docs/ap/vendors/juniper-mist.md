# Juniper Mist AI 無線LANアクセスポイント技術調査

調査日: 2026-03-16

eduroam導入に向けたJuniper Mist APシリーズの技術調査結果をまとめる。

---

## 1. 現行ラインナップ

### Wi-Fi 7 (802.11be) 対応モデル

| モデル | 用途 | 無線構成 | 最大データレート | PoE要件 | 特徴 |
|--------|------|----------|------------------|---------|------|
| **AP47** | 屋内フラッグシップ | 4ラジオ、3x 4SS | 6GHz: 11,528Mbps / 5GHz: 5,764Mbps / 2.4GHz: 1,376Mbps | 802.3bt (29W) | 最高性能、USB搭載 |
| **AP37** | 屋内ハイエンド | トライバンド + スキャニングラジオ | マルチギガビット | 802.3bt | vBLE位置情報、BLE 6.0、IoT |
| **AP36** | 屋内ハイエンド | トライバンド + スキャニングラジオ | 17.98 Gbps (合計) | 802.3bt | AP37同等、アンテナ構成違い |
| **AP66/AP66D** | 屋外 | 4ラジオ、3x 2SS | 6GHz: 5.8Gbps / 5GHz: 2.9Gbps / 2.4GHz: 688Mbps | 802.3bt | IP67、BLE 6.0、GNSS/GPS |

### Wi-Fi 6E (802.11ax 6GHz) 対応モデル

| モデル | 用途 | 無線構成 | 最大データレート | PoE要件 | 特徴 |
|--------|------|----------|------------------|---------|------|
| **AP45** | 屋内ハイエンド | 4ラジオ、4SS | 6GHz: 4,800Mbps / 5GHz: 2,400Mbps / 2.4GHz: 1,148Mbps | 802.3bt (29.3W) | フラッグシップWi-Fi 6E |
| **AP34** | 屋内ミドル | トライバンド、2x2:2 | 6GHz: 2,400Mbps / 5GHz: 1,200Mbps / 2.4GHz: 575Mbps | Dynamic PoE (20.9W) | コストパフォーマンス重視 |
| **AP24** | 屋内エントリー | トライバンド対応デュアルバンド同時、2x2 | 6GHz: 2,400Mbps / 5GHz: 1,200Mbps / 2.4GHz: 575Mbps | 802.3af | 最小PoE要件、エントリーモデル |

### Wi-Fi 6 (802.11ax) 対応モデル（レガシー）

| モデル | 用途 | PoE要件 | 備考 |
|--------|------|---------|------|
| **AP43** | 屋内ハイエンド | 802.3at/PoE+ (25.5W) | Wi-Fi 6世代のフラッグシップ |
| **AP33** | 屋内ミドル | 802.3at | Mist AI for AX統合 |
| **AP32** | 屋内スタンダード | 802.3at | 東京大学で約7,500台導入 |

### 同時接続数

- 各ラジオあたり最大 **128クライアント** 接続
- AP全体の理論最大値: 約 **256クライアント**（2ラジオAPの場合）～ **384クライアント**（3データラジオAPの場合）
- 1 APあたり最大 **15 WLAN/ラジオ**、AP全体で30-45 WLAN

### 教育機関向け推奨モデル

eduroam用途では、コスト・PoE要件・性能のバランスから以下が候補:
- **AP34**: Wi-Fi 6E、PoE要件が比較的低く（20.9W）、コスパ良好
- **AP24**: エントリーモデル、802.3af対応で既存PoEスイッチ流用可能
- **AP45**: 高密度エリア向け（講義室・図書館等）

---

## 2. WPA2/WPA3-Enterprise (802.1X) 対応

### 対応セキュリティモード

- **WPA2-Enterprise (802.1X)**: 完全対応
- **WPA3-Enterprise (802.1X)**: 完全対応
- **WPA3-Enterprise 192-bit**: 対応（ただし制約あり。下記参照）

### EAP方式対応

Mist APはEAPパススルーモードで動作する。APはEAPフレームを中継するだけで、EAP認証のネゴシエーションはクライアントとRADIUSサーバ間で行われる。

**対応EAP方式（パススルー）:**
- EAP-TLS
- EAP-TTLS/PAP
- PEAP (EAP-MSCHAPv2)
- EAP-TEAP
- その他すべてのEAP方式（APはトランスポートのみ）

### EAP-TTLS/PAP動作可否

**動作確認済み。** Juniper公式ドキュメントにEAP-TTLSクライアント設定ガイドが存在し、Mist Access Assuranceの認証方式としてEAP-TTLS/PAPが明示的にサポートされている。APはパススルーモードで動作するため、バックエンドのFreeRADIUSがEAP-TTLS/PAPを処理する構成で問題なく動作する。

### WPA3-Enterprise 192-bit モードの制約

- 802.11r（Fast BSS Transition）が使用不可
- EAP-TLS必須（EAP-TTLS/PAPは使用不可）
- **eduroamでは WPA3-Enterprise（通常モード）を使用すべき**

---

## 3. 集中管理機能（Mist Cloud / Mist AI）

### アーキテクチャ

- **完全クラウドベース管理**: 物理コントローラ不要
- APはクラウドに直接接続し、設定・監視・ファームウェア管理を受ける
- **管理対象**: AP、EXシリーズスイッチ、SRXシリーズFW、SSRシリーズルーター

### AIエンジン「Marvis」

- プロアクティブなトラブルシューティング
- 異常検知とサービスレベル低下の自動検出
- 自然言語によるネットワーク問い合わせ（Marvis Virtual Network Assistant）
- SLE（Service Level Expectations）による品質監視

### 管理台数

- クラウドベースのため、**管理台数に明示的な上限なし**（ライセンス数による）
- 東京大学: 約7,500台のAPを一元管理
- 追手門学院大学: 340台のAPを一元管理
- 組織ごとにマルチテナント管理が可能（部局別権限設定対応）

### オンプレミスオプション

- **完全オンプレミス: 非対応** - Mist はクラウド接続が必須
- **Mist Edge**: オンプレミスに設置するデータプレーンアプライアンス
  - コントロールプレーン/管理プレーンはクラウドに残る
  - データプレーン（ユーザートラフィック）のみローカル処理
  - RADIUS Proxy機能（eduroam連携で重要）
  - ハードウェアモデル:
    - **ME-X1**: 500 AP対応、2x 1Gbps
    - **ME-X10**: 10,000 AP対応、4x 10GBASE-X (SFP+)
    - **ME-VM**: 仮想アプライアンス、500 AP対応
    - **ME-VM-OC-PROXY**: プロキシ専用仮想アプライアンス
- **GovCloud**: AWS GovCloud (US) 上の専用インスタンス（FedRAMP Moderate認証済み）

### 閉域網運用の注意

Mist APはクラウドへの常時接続を前提としている。インターネット接続が断たれた場合、APは既存の設定で動作を継続するが、管理・監視・設定変更は不可。教育機関のネットワーク設計では、管理用VLANからクラウドへの経路確保が必要。

---

## 4. VLAN対応

### タグVLAN

- 802.1Q タグVLAN完全対応
- SSIDごとにVLAN IDを割り当て可能
- APと上流スイッチ間はトランクポートで接続

### Dynamic VLAN（RADIUS属性による動的割り当て）

**完全対応。** 2種類のRADIUS属性に対応:

1. **Tunnel-Private-Group-Id（Standard方式）**
   - RADIUS Access-Acceptに以下の属性を含める:
     - `Tunnel-Type = VLAN`
     - `Tunnel-Medium-Type = IEEE-802`
     - `Tunnel-Private-Group-Id = <VLAN-ID>`
   - FreeRADIUSとの親和性が高い

2. **Airespace-Interface-Name方式**
   - Cisco由来の属性名でVLAN名を指定

### 設定上の注意点

- VLAN Typeは **WLANごとに1種類のみ** 指定可能（同一SSIDでStandardとAirespaceの混在不可）
- Dynamic VLANで指定するVLAN IDは、**APが接続するスイッチのトランクポートに事前に設定**が必要
- Mist Cloudダッシュボードから WLAN設定 > VLAN で Dynamic VLANを有効化

### eduroamでの活用

eduroam SSIDでDynamic VLANを使用し、所属機関ユーザーと外来ユーザーを異なるVLANに振り分けることが可能。FreeRADIUSのauthorizeセクションでTunnel属性を返すよう設定する。

---

## 5. RADIUS連携

### 基本構成

- Mist Cloud ダッシュボードでRADIUSサーバ（IP、ポート、Shared Secret）を設定
- WLANセキュリティで「WPA2/WPA3 Enterprise (802.1X)」を選択するとRADIUS設定が有効化
- プライマリ/セカンダリRADIUSサーバの冗長構成が可能

### FreeRADIUS連携

**連携実績あり。** 公式ドキュメントにFreeRADIUSとの連携が言及されている。

設定のポイント:
1. **Mist側**: WLAN設定でFreeRADIUSサーバのIP、認証ポート(1812)、アカウンティングポート(1813)、Shared Secretを設定
2. **FreeRADIUS側**: `clients.conf` にMist APのIPレンジ（またはMist EdgeのIP）を登録
3. **Dynamic VLAN使用時**: FreeRADIUSがTunnel属性を返さない場合、`mods-available/eap` に設定追加が必要な場合あり
4. **CoA (Change of Authorization)**: MistはRADIUS CoAに対応、ポート3799

### Mist RADIUS属性

Mist APが送信する主なRADIUS属性:
- `NAS-IP-Address`: APのIPアドレス
- `Called-Station-Id`: AP BSSID:SSID名
- `Calling-Station-Id`: クライアントMACアドレス
- `NAS-Port-Type`: Wireless-802.11

### eduroamでのRADIUS構成パターン

**パターンA: 直接RADIUS（小規模向け）**
```
[クライアント] --> [Mist AP] --> [FreeRADIUS (IdP/SP)] --> [eduroam FLR]
```

**パターンB: Mist Edge Proxy経由（推奨）**
```
[クライアント] --> [Mist AP] --> [Mist Edge (RADIUS Proxy)] --> [eduroam FLR]
                                         |
                                    [FreeRADIUS (IdP)]  ← 自機関ユーザー認証
```

Mist Edge Proxyを使用する場合:
- Mist Edgeに固定パブリックIPまたはNAT IPを割り当て
- eduroam管理ポータルにRADIUSクライアントとして登録
- OOBMインタフェースでプロキシ機能を提供
- RADIUS Auth/Acct (1812/1813 UDP)、RadSec (2083 TCP) を許可

---

## 6. eduroam利用実績

### 日本国内の大学導入事例

#### 東京大学（2023年〜）

- **採用モデル**: Mist AP32（屋内）、AP64（屋外）
- **導入規模**: 約 **7,500台** のAP、本郷・駒場・柏の3キャンパス
- **同時接続**: ピーク時約 **18,000台**
- **ネットワーク構成**:
  - PoEスイッチ: EX4100-48MP
  - 集約スイッチ: QFX5120-48S-6Q
  - AP-スイッチ間: 2.5GBASE-T
  - スイッチ間: 10GBASE-LR
- **採用理由**: 部局横断的な統合管理、単一ダッシュボードでの可視化、Marvisによるトラブルシューティング
- **eduroam**: 全学無線LANの一部としてeduroamを提供

#### 追手門学院大学

- **導入規模**: **340台** のMist AP（大学キャンパス、茨木アイキャンパス、附属校含む）
- **スイッチ**: EXシリーズ 170台
- **ゲートウェイ**: SRXシリーズ
- **効果**: Wi-Fi接続の安定化、ローミング問題の解消、BLE位置情報活用

### 海外の大学導入事例

| 大学 | 国 | 備考 |
|------|------|------|
| **University of Oxford** | 英国 | 2024年パイロット → 2025年から5年計画で全学展開。eduroam/OWL SSIDを提供 |
| **University of Plymouth** | 英国 | 900台以上のAPを3週間で交換 |
| **University of Sussex** | 英国 | 2024-2025年にネットワーク全面更新 |
| **Dartmouth College** | 米国 | キャンパスWi-Fi全面刷新 |
| **James Cook University Singapore** | シンガポール | キャンパスネットワーク導入 |

### Juniper公式のeduroamサポート

Juniperは **Mist Edge Proxy for eduroam** として公式ドキュメントを公開しており、eduroamとの統合を正式にサポートしている。Mist Access AssuranceとMist EdgeをRADIUS Proxyとして使用するアーキテクチャが文書化されている。

---

## 7. 802.11k/v/r 対応状況

### 対応状況一覧

| 規格 | 対応 | デフォルト | 設定単位 | 備考 |
|------|------|-----------|----------|------|
| **802.11k** | 対応 | **有効** | グローバル | 隣接AP情報をクライアントに通知、オフチャネルスキャン削減 |
| **802.11v** | 対応 | **有効** | グローバル | BSS Transition Management (BTM)、クライアントへのローミング推奨 |
| **802.11r** | 対応 | **無効**（要手動有効化） | WLANごと | Fast BSS Transition、再認証なしのローミング |

### 802.11r の詳細

- **Hybrid/Mixed mode対応**: 802.11r対応/非対応クライアントの混在が可能
- **WPA2/WPA3-Enterprise対応**: 802.1X認証環境でのFast Roamingをサポート
- **制約事項**:
  - WPA3-Enterprise 192-bit モードでは使用不可
  - クライアント側の802.11r対応が必要（古いデバイスでは非対応の場合あり）
  - WLANごとに有効/無効を切り替え可能

### eduroamでの推奨設定

- 802.11k/v: デフォルト有効のまま使用
- 802.11r: **有効化を推奨**（ただしHybrid/Mixed modeで）
  - eduroamでは多様なクライアントデバイスが接続するため、Mixed modeが安全
  - EAP再認証のオーバーヘッドを削減し、ローミング品質を向上

---

## 8. Passpoint (Hotspot 2.0) 対応

### 対応状況

**対応。** Wi-Fi Alliance認定のPasspoint (Hotspot 2.0) をサポート。

### 要件

- APファームウェア: **0.8.21116以降**（rc1以降）
- WLANセキュリティ: **802.1X必須**（Passpoint仕様による制約）
- RadSecサポート: AP証明書のプロビジョニングが可能

### 設定項目

- Operator（サービスプロバイダー）選択
- 802.11u設定の自動ロード
- Domain Names
- Roaming Consortium IDs
- NAI Realm
- AP証明書（秘密鍵 + 署名済み証明書）

### OpenRoaming対応

Juniper MistはOpenRoaming Passpoint設定にも対応しており、RadSecを使用したセキュアなエンドツーエンド認証パスを提供する。

### eduroamとの関係

eduroamはPasspoint/Hotspot 2.0を利用した自動接続（eduroam via Passpoint）を推進している。Mist APがPasspointに対応していることで、将来的にeduroam Passpointプロファイルによるシームレスな自動接続が可能になる。

---

## 9. 価格帯・ライセンス体系

### 購入構成

Juniper Mist APの導入には以下が必要:

1. **APハードウェア**: 本体購入（買い切り）
2. **クラウドサブスクリプション**: 必須（APはライセンスなしでは動作しない）

### サブスクリプション体系

#### Wireless向けサブスクリプション（5種類）

| サブスクリプション | SKUプレフィックス | 説明 | 必須/任意 |
|-------------------|------------------|------|-----------|
| **Wi-Fi Assurance** | SUB-MAN | 基本管理・監視・SLE | **必須** |
| **Marvis (VNA)** | SUB-VNA | AI仮想ネットワークアシスタント | 任意 |
| **Asset Visibility** | SUB-AST | BLE資産追跡 | 任意 |
| **User Engagement** | SUB-ENG | 位置情報ベースのサービス | 任意 |
| **Premium Analytics** | SUB-PA | 高度な分析・レポート | 任意 |

#### 契約期間

- **1年** / **3年** / **5年** / **7年** から選択
- 長期契約ほど割引率が高い

#### サブスクリプションバンドル

- 複数サービスをバンドルした割安パッケージあり
- 例: `SUB-3S-1Y`（3サービス、1AP、1年）

### eduroam構成で必要になる追加コスト

eduroam構成でMist Edge Proxyを使用する場合:
- **Mist Edge アプライアンス**: ME-X1（小規模）またはME-VM（仮想）
- **Mist Edge サブスクリプション**: SUB-ME-DATA（APあたり）

### 概算価格帯（参考、販売代理店による変動あり）

**注意: 以下は公開情報からの推定であり、正確な価格は販売代理店への見積もりが必要。**

| 項目 | 概算価格帯 |
|------|-----------|
| APハードウェア（エントリー: AP24） | 約 $500-800 USD |
| APハードウェア（ミドル: AP34） | 約 $800-1,200 USD |
| APハードウェア（ハイエンド: AP45/AP47） | 約 $1,500-3,000 USD |
| Wi-Fi Assuranceサブスクリプション（APあたり/年） | 約 $150-300 USD |
| Marvis VNA（APあたり/年） | 約 $50-100 USD |

**日本国内の販売代理店:**
- ソフトバンク
- 日立ソリューションズ
- ネットワンパートナーズ
- ジェイズ・コミュニケーション
- 日商エレクトロニクス
- SB C&S

---

## 10. 総合評価とeduroam導入への適合性

### 利点

1. **eduroam公式サポート**: Mist Edge Proxy for eduroamが公式文書化されている
2. **日本の大学での実績**: 東京大学（7,500台）、追手門学院大学（340台）で大規模導入済み
3. **EAP-TTLS/PAP対応**: APパススルーモードにより、任意のEAP方式をサポート
4. **Dynamic VLAN**: Tunnel-Private-Group-Id完全対応、FreeRADIUSとの親和性良好
5. **802.11k/v/r対応**: ローミング品質の向上に寄与
6. **Passpoint対応**: 将来のeduroam Passpoint展開に対応可能
7. **AI駆動の管理**: Marvisによるプロアクティブな障害対応
8. **クラウド管理**: 物理コントローラ不要、運用負荷軽減

### 注意点・懸念事項

1. **クラウド接続必須**: 完全オンプレミス運用は不可。インターネット接続断時は管理不能
2. **サブスクリプション必須**: APはライセンスなしでは動作しない。ランニングコストが継続的に発生
3. **Mist Edge追加コスト**: eduroam Proxy構成にはMist Edgeアプライアンスの追加購入が必要
4. **価格**: Cisco/Arubaと同等〜やや高めの価格帯。エントリーモデルでも$500以上

### 神戸電子専門学校への適合性評価

| 評価項目 | 評価 | コメント |
|----------|------|---------|
| eduroam対応 | A | 公式サポートあり、大学実績豊富 |
| EAP-TTLS/PAP | A | パススルーで問題なし |
| Google Workspace LDAP連携 | A | FreeRADIUS経由で対応可能 |
| Dynamic VLAN | A | 標準RADIUS属性対応 |
| 管理の容易さ | A | クラウド管理、AI支援 |
| ローミング品質 | A | 802.11k/v/r完全対応 |
| 初期コスト | B | AP+サブスクリプション+Mist Edge |
| ランニングコスト | B- | 年次サブスクリプション必須 |
| オフライン耐性 | C | クラウド接続必須 |

---

## Sources

- [Juniper Mist AP製品ページ](https://www.juniper.net/us/en/products/access-points.html)
- [AP47データシート](https://www.juniper.net/us/en/products/access-points/ap47-access-point-datasheet.html)
- [AP45データシート](https://www.juniper.net/us/en/products/access-points/ap45-datasheet.html)
- [AP37/AP36データシート](https://www.juniper.net/us/en/products/access-points/ap37-ap36-access-point-datasheet.html)
- [AP66データシート](https://www.juniper.net/us/en/products/access-points/ap66-access-point-datasheet.html)
- [AP34データシート](https://www.juniper.net/us/en/products/access-points/ap34-access-point-datasheet.html)
- [WPA2/WPA3 Enterprise (802.1X) WLAN設定](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/topic-map/radius-configuration.html)
- [EAP-TTLSクライアント設定](https://www.juniper.net/documentation/us/en/software/mist/mist-access/topics/task/mist-access-eap-ttls-client-config.html)
- [Mist Access Assurance認証方式](https://www.juniper.net/documentation/us/en/software/mist/mist-access/topics/topic-map/access-assurance-authentication-methods.html)
- [Dynamic VLAN設定](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/task/mist-dynamic-vlans.html)
- [Mist RADIUS属性](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/topic-map/radius-attributes.html)
- [VLANs (Static & Dynamic)](https://www.mist.com/documentation/vlans-static-dynamic/)
- [802.11k/v/r対応](https://www.mist.com/documentation/802-11k-802-11r-802-11v/)
- [RSSI, Roaming, Fast Roaming](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/topic-map/rssi-fast-roaming.html)
- [802.11rサポート詳細 (artofrf.com)](https://artofrf.com/2024/02/01/juniper-mist-802-11r-support/)
- [Passpoint設定](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/task/passpoint.html)
- [OpenRoaming Passpoint設定](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/task/mist-radsec-openroaming.html)
- [Hotspot 2.0 (Mist)](https://www.mist.com/documentation/hotspot-2-0/)
- [Mist Edge Proxy for eduroam](https://www.juniper.net/documentation/us/en/software/mist/mist-access/topics/topic-map/mist-edge-proxy-eduroam.html)
- [Mist Edge Proxy IdP - eduroam (旧Mist)](https://www.mist.com/documentation/mist-edge-proxy-idp-eduroam/)
- [RADIUS Proxyサーバ設定](https://www.juniper.net/documentation/us/en/software/mist/mist-edge-guide/mist-edge/topics/topic-map/radius-proxy-service-configure.html)
- [Mist Edgeハードウェア仕様](https://www.juniper.net/documentation/us/en/software/mist/mist-edge-guide/mist-edge/topics/concept/hardware-specifications.html)
- [Mist Edgeデータシート](https://www.juniper.net/us/en/products/access-points/juniper-edge-datasheet.html)
- [サブスクリプションタイプ](https://www.juniper.net/documentation/jp/ja/software/mist/mist-management/topics/topic-map/mist-subscription-types.html)
- [Mist購入ガイド（日本語PDF）](https://www.juniper.net/content/dam/www/assets/additional-resources/jp/ja/2021-1/mist-buying-guide-mist-wireless.pdf)
- [Mistサブスクリプション](https://www.juniper.net/documentation/jp/ja/software/mist/mist-management/topics/concept/subscriptions.html)
- [同時接続数・WLAN上限](https://www.mist.com/documentation/maximum-devices-and-wlans-per-ap/)
- [AP PoE要件一覧](https://www.juniper.net/documentation/us/en/software/mist/mist-wireless/topics/ref/ap-poe-requirements.html)
- [東京大学 Mist導入事例](https://www.juniper.net/us/en/customers/the-university-of-tokyo-case-study.html)
- [東大がジュニパーのMistを採用 (BUSINESS NETWORK)](https://businessnetwork.jp/article/14749/)
- [東京大学における全学無線LAN整備 (AXIES 2023)](https://axies.jp/_files/conf/conf2023/paper/14PM1Y-5.pdf)
- [追手門学院大学 導入事例](https://www.juniper.net/us/en/customers/otemon-case-study.html)
- [University of Oxford 導入事例](https://www.juniper.net/us/en/customers/university-of-oxford-case-study.html)
- [University of Plymouth 導入事例](https://www.juniper.net/us/en/customers/university-of-plymouth-case-study.html)
- [University of Sussex 導入事例](https://www.juniper.net/us/en/customers/2024/university-of-sussex-case-study.html)
- [Juniper Mist高等教育機関向けソリューション（日本語PDF）](https://www.juniper.net/content/dam/www/assets/additional-resources/jp/ja/juniper-mist-solution-for-universities.pdf)
- [Juniper Mist概要（日立ソリューションズ）](https://www.hitachi-solutions.co.jp/juniperproducts/lineup/juniper-mist/)
- [Juniper Mist概要（ネットワンパートナーズ）](https://www.netone-pa.co.jp/lp/juniper-mist/)
- [iDATEN APラインアップ](https://www.idaten.ne.jp/portal/page/out/mss/juniper/ap_lineup.html)
- [iDATEN ライセンス紹介](https://www.idaten.ne.jp/portal/page/out/mss/juniper/license.html)
- [eduroam FreeRADIUS SP設定 (GEANT)](https://wiki.geant.org/display/H2eduroam/freeradius-sp)
