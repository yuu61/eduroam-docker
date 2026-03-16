# Ubiquiti UniFi 無線LANアクセスポイント技術調査

eduroam導入に向けたUniFi APシリーズの技術調査結果。調査日: 2026-03-16

---

## 1. 現行ラインナップ

### Wi-Fi 7（802.11be）シリーズ

| モデル | Wi-Fi規格 | バンド | 最大スループット | アップリンク | 同時接続数 | 802.11k/v/r | 参考価格(USD) |
|--------|-----------|--------|------------------|-------------|-----------|-------------|---------------|
| U7 Lite | Wi-Fi 7 | デュアルバンド(2.4/5GHz) | - | 2.5GbE | 300+ | 対応 | $99 |
| U7 Pro | Wi-Fi 7 | トライバンド(2.4/5/6GHz) | 10.8 Gbps | 2.5GbE | 300+ | 対応 | $189 |
| U7 Pro Max | Wi-Fi 7 | トライバンド(2.4/5/6GHz) | - | 2.5GbE | 300+ | 対応 | $279 |
| U7 Pro XG | Wi-Fi 7 | トライバンド(2.4/5/6GHz) | 9.3 Gbps | 10GbE | 300+ | 対応 | $199 |
| U7 Pro XGS | Wi-Fi 7 | トライバンド(2.4/5/6GHz) | - | 10GbE RJ45 | 300+ | 対応 | $299 |
| U7 Mesh | Wi-Fi 7 | デュアルバンド(2.4/5GHz) | - | GbE | 300+ | 対応 | - |

### Wi-Fi 6/6E（802.11ax）シリーズ（現行販売中）

| モデル | Wi-Fi規格 | バンド | 最大スループット | アップリンク | 同時接続数 | 参考価格(USD) |
|--------|-----------|--------|------------------|-------------|-----------|---------------|
| U6 Lite | Wi-Fi 6 | デュアルバンド(2x2) | 1.5 Gbps | GbE | 300+ | $99 |
| U6 Plus | Wi-Fi 6 | デュアルバンド | - | GbE | 300+ | ~$129 |
| U6 Pro | Wi-Fi 6 | デュアルバンド(4x4) | 4.8 Gbps(5GHz) | GbE | 350+ | $159 |
| U6 Enterprise | Wi-Fi 6E | トライバンド(2.4/5/6GHz) | 2.4 Gbps(6GHz) | 2.5GbE PoE+ | 350+ | $279 |

### Enterprise Wi-Fi 7シリーズ

| モデル | 特徴 | 参考価格(USD) |
|--------|------|---------------|
| E7 (Enterprise 7) | AFC(Automated Frequency Coordination)対応、Wi-Fi 7初のAFC搭載AP | - |

### eduroam導入推奨モデル

教育機関の規模と予算に応じて以下を推奨:

- **コスト重視**: U7 Lite ($99) -- Wi-Fi 7対応で最安、小規模教室向け
- **標準構成**: U7 Pro ($189) -- トライバンド・6GHz対応、中規模教室・講堂向け
- **高密度環境**: U7 Pro XG/XGS ($199/$299) -- 10GbEアップリンク、大講義室・図書館向け

---

## 2. WPA2/WPA3-Enterprise (802.1X) 対応

### 対応セキュリティプロトコル

- **WPA2-Enterprise** (802.1X): 全モデル対応
- **WPA3-Enterprise** (802.1X): Wi-Fi 6以降のモデルで対応
- **WPA2/WPA3混在モード**: 対応（移行期に有用）

### 対応EAP方式

UniFi APは802.1Xのオーセンティケータとして動作し、EAP方式の処理自体はRADIUSサーバ側で行う。APはEAPパケットを透過的に中継するため、RADIUSサーバが対応する全てのEAP方式が利用可能:

- **EAP-TLS**: 証明書ベース認証（最もセキュア）
- **EAP-TTLS/PAP**: TLSトンネル内でPAP認証 -- **eduroamで使用する方式**
- **EAP-TTLS/MSCHAPv2**: TLSトンネル内でMSCHAPv2認証
- **PEAP/MSCHAPv2**: 一般的なWindows環境での方式
- **EAP-PEAP/GTC**: Cisco等で使用

### EAP-TTLS/PAP動作確認

**結論: 動作する。**

UniFi APはEAPパケットをRADIUSサーバへ透過的にプロキシするため、FreeRADIUS側でEAP-TTLS/PAPを設定すれば問題なく動作する。GitHub上にUniFi + FreeRADIUS + EAP-TTLSの構成ガイド（ankorez/unifi-okta-radius-eap-ttls）も公開されており、実績がある。

### 設定手順（UniFi Network Application）

1. **RADIUSプロファイル作成**: Settings > Profiles > RADIUS > Create New
   - Authentication Server: FreeRADIUSのIPアドレスとポート(1812)
   - Accounting Server: FreeRADIUSのIPアドレスとポート(1813)
   - Shared Secret: RADIUS共有シークレット
2. **WiFiネットワーク作成**: Settings > WiFi > Create New
   - SSID: `eduroam`
   - Security Protocol: WPA2 Enterprise（またはWPA3 Enterprise）
   - RADIUS Profile: 上記で作成したプロファイルを選択
3. **RADIUS assigned VLAN**: 必要に応じて有効化

---

## 3. 集中管理機能（UniFi Network Application）

### 概要

UniFi Network Applicationは、全UniFiデバイス（AP、スイッチ、ゲートウェイ）を一元管理するソフトウェア。**ライセンス費用は不要**。

### 主要機能

- デバイスの一括設定・ファームウェア更新
- リアルタイムトラフィック分析・統計
- ゲストポータル（キャプティブポータル）
- VLAN管理
- RADIUS連携設定
- Passpoint / Hotspot 2.0設定
- クライアント接続状況モニタリング
- アラート・通知管理
- ライセンスフリーのSD-WAN機能

### 管理台数上限

| プラットフォーム | 管理可能デバイス数 | 管理可能クライアント数 |
|-----------------|-------------------|---------------------|
| Cloud Key Gen2+ | 最大40デバイス | 最大2,000クライアント |
| UDM / Dream Router | 最大40デバイス | 最大2,000クライアント |
| UDM-SE / UDM Pro Max | 多数（大規模向け） | 多数 |
| セルフホスト（Linux） | スペック依存（実質無制限） | スペック依存 |

**注意**: Cloud Key Gen2+は40デバイス以下でもリソース不足になる報告あり。50台以上のAP管理にはセルフホストまたはUDM-SE以上を推奨。

### ホスティングオプション

| 方式 | 特徴 | 推奨環境 |
|------|------|---------|
| **UniFiハードウェア内蔵** | Dream Machine/Cloud Gatewayにコントローラ内蔵 | 小〜中規模 |
| **セルフホスト（Linux）** | Ubuntu 23.04+/Debian 12+、Podman 4.3.1+ | 中〜大規模 |
| **クラウドホスト** | AWS/DigitalOcean等のVPS上に構築 | リモート管理 |
| **UniFi OS Server** | Ubiquiti公式のセルフホスト型制御プレーン | MSP/大規模 |
| **サードパーティホスティング** | UniHosted等のマネージドサービス | MSP向け |

### セルフホスト最小要件

- OS: Ubuntu 23.04+ / Debian 12+
- ストレージ: 20GB以上の空き容量（SSD/NVMe推奨）
- メモリ: 最低2GB（50台以上管理時は4GB+推奨）
- コンテナランタイム: Podman 4.3.1+（Dockerは非対応）
- 必要ポート: 3478, 8080, 8443, 8880, 8881, 8882 他

---

## 4. VLAN対応

### タグVLAN

- 全UniFi APモデルでタグVLAN対応
- SSID単位でVLAN IDを割り当て可能
- UniFi Network ApplicationのGUIから設定: Settings > Networks > Create New でVLAN IDを指定

### Dynamic VLAN（RADIUS属性による動的割り当て）

**対応済み。FreeRADIUSとの連携で動作確認されている。**

#### 必要なRADIUS属性

FreeRADIUS側で以下の3属性をユーザーに対して返す:

```
Tunnel-Type = VLAN
Tunnel-Medium-Type = IEEE-802     # (= 6)
Tunnel-Private-Group-Id = <VLAN番号>
```

#### UniFi側の設定

1. RADIUSプロファイルを作成
2. WiFiネットワークでWPA2/WPA3 Enterpriseを選択
3. 「RADIUS assigned VLAN」オプションを有効化
4. VLANが返されない場合はデフォルト（untagged）VLANにフォールバック

#### eduroamでの活用

eduroamでは、認証結果に基づいてユーザーを適切なVLANに振り分けることが一般的:
- 所属機関のユーザー → 学内VLAN
- ビジターユーザー → ゲストVLAN（インターネットのみ）
- 未認証/失敗 → 隔離VLAN

この動的VLAN割り当てはUniFi APとFreeRADIUSの組み合わせで十分に実現可能。

---

## 5. RADIUS連携

### FreeRADIUS連携実績

多数のブログ記事・コミュニティ投稿でFreeRADIUS + UniFi APの組み合わせが検証されており、十分な実績がある。

#### 主要な設定ポイント

**FreeRADIUS側（clients.conf）**:
```
client unifi-ap {
    ipaddr = <APのIPアドレスまたはサブネット>
    secret = <RADIUS共有シークレット>
}
```

**FreeRADIUS側（EAP設定）**:
- `default_eap_type = ttls` を設定
- `use_tunneled_reply = yes` を設定（トンネル内のReply属性をAPに返すため）

**UniFi側**:
- RADIUSプロファイルでAuthentication Server（ポート1812）とAccounting Server（ポート1813）を設定
- WiFiネットワークでWPA2 Enterpriseを選択し、RADIUSプロファイルを割り当て

#### 注意事項

- UniFiゲートウェイ（UDM等）に内蔵のRADIUSサーバは機能が限定的。FreeRADIUSのような外部RADIUSサーバの使用を推奨
- APは自身のIPアドレスをNAS-IP-Addressとして送信する。FreeRADIUSのclientsにはAPのサブネットを指定するのが管理しやすい
- RADIUS Accountingを有効にすることで、接続時間やデータ使用量のログ取得が可能

### RadSec（RADIUS over TLS）対応

UniFi Network 8.4以降で**RadSec対応**が追加された。

- ポート: 2083/TCP
- eduroamプロキシ（GEANT/NII）との接続に使用可能
- クライアント証明書・秘密鍵・CA証明書のアップロードが必要
- WiFiネットワークのRADIUSプロファイルでTLSオプションをトグルして有効化

---

## 6. eduroam利用実績

### 直接的な採用事例

GEANTの公式wiki（eduroam How-to）に**Ubiquiti UniFi向けのOpenRoaming設定スニペット**が掲載されており、eduroamコミュニティで公式にサポートされたAPベンダーの一つとして扱われている。

Ubiquiti Community Forumでは以下のようなeduroam関連の議論が複数存在:
- eduroam SSID + RADIUS VLAN設定
- 同一SSIDで複数VLANの運用（eduroamの典型パターン）
- eduroam接続トラブルシューティング

### 大学キャンパスでのUniFi導入事例

- **Mount St. Mary's University（米国）**: UniFi Cloud Gatewayを活用したキャンパスネットワーク刷新
- **The Connect School**: UniFi AC PRO/AC EDUを利用した学校全体のWi-Fi展開
- **英国の教育機関（Integy事例）**: UniFiを使用したキャンパスネットワーク全面刷新、VLAN分離を含む

### 日本国内の状況

日本のeduroam JP参加機関でのUniFi採用に関する公開情報は限定的。国内の大学では従来、Aruba/HPE、Cisco、YAMAHA等が主流だが、コスト優位性からUniFiの採用を検討する小〜中規模の教育機関が増えている。

### eduroam構成における位置づけ

```
[端末] -- (802.1X/EAP-TTLS) --> [UniFi AP] -- (RADIUS) --> [FreeRADIUS IdP]
                                                               |
                                                    (RADIUS proxy)
                                                               |
                                                         [eduroam JP FLR]
```

UniFi APはオーセンティケータとしてEAPパケットをFreeRADIUSに中継する役割。eduroamの階層型RADIUS proxy構成において、APの役割は限定的であり、APの選択がeduroamの動作に大きな影響を与えることはない。

---

## 7. 802.11k/v/r対応状況

### 対応状況一覧

| 機能 | 規格 | UniFi対応 | 設定項目 |
|------|------|-----------|---------|
| Neighbor Report | 802.11k | 対応 | WiFi設定で有効化 |
| BSS Transition Management | 802.11v | 対応 | WiFi設定で有効化 |
| Fast BSS Transition | 802.11r | 対応（独自実装） | 「Fast Roaming」設定 |

### 各規格の詳細

**802.11k（Neighbor Report）**:
- APが周辺APの情報をクライアントに通知
- クライアントがローミング先を高速に発見できる（全チャネルスキャン不要）
- 有効にしないとクライアントが全チャネルをスキャンするため数秒のロスが発生

**802.11v（BSS Transition Management）**:
- ネットワーク側からクライアントに最適なAPへの移行を提案
- クライアントが提案を受け入れるかどうかはクライアント次第
- 対応状況はクライアントデバイスに依存（Apple製品は良好、Android/Windowsはまちまち）

**802.11r（Fast BSS Transition）**:
- UniFiの「Fast Roaming」機能はOTA（Over-the-Air）Fast BSS Transitionを実装
- 純粋な802.11rではなく、Ubiquiti独自の実装で約90%のローミング改善を実現
- **後方互換性あり**: 802.11r非対応クライアントでも動作する（純粋な802.11rは非対応クライアントで接続問題が発生することがある）
- VoIPやZoom等のリアルタイム通信中の移動でも切断を最小限に抑える

### 推奨設定

eduroam環境では以下を推奨:
- **802.11k**: 有効
- **802.11v**: 有効
- **Fast Roaming（802.11r相当）**: 有効
- **Min-RSSI**: -75 dBm（APが弱い信号のクライアントを切断し、近いAPへの再接続を促進）
- **Band Steering**: 有効（5GHz/6GHz優先）

### 制約事項

- 802.11rの純粋な実装ではないため、802.11r必須の一部エンタープライズ要件では制約となる可能性
- 802.11vのクライアント側対応が不安定な場合がある
- 異なるモデル混在環境でのローミングはテストが必要

---

## 8. Passpoint (Hotspot 2.0) 対応

### 対応状況

**対応済み**。UniFi Network Application 8.4.54以降 + AP ファームウェア要件:
- UAP/U6シリーズ: ファームウェア 6.6.78以降
- U7シリーズ: ファームウェア 7.0.66以降

### eduroam OpenRoaming との統合

GEANTの公式wikiにUniFi向けのeduroam OpenRoaming設定手順が掲載されている。

#### 設定手順

1. **RADIUSプロファイル作成**:
   - RadSec使用時: ポート2083、シークレット `radsec`
   - クライアント証明書・秘密鍵・CA証明書をアップロード
   - TLSオプションを有効化

2. **WiFiネットワーク作成**:
   - Hotspot 2.0 > Passpoint を選択
   - WPA2/WPA3 Enterpriseを設定
   - RADIUSプロファイルを割り当て

3. **Passpoint固有の設定**:
   - **Roaming Consortium OI**: `001BC50460`（eduroam OI）を追加、「Is Beacon」にチェック
   - **NAI Realm**: `eduroam.org` を追加
   - **Venue Name**: 施設名を設定
   - **Venue Type**: 教育機関（Education）を選択
   - **Network Type**: 適切なタイプを選択

4. **プロバイダ連携**:
   - Google Orion、IronWiFi、OpenRoaming等のサードパーティプロバイダとシームレス統合可能

### Passpoint利用のメリット（eduroam）

- ユーザーが手動でSSIDを選択・設定する必要がなくなる
- デバイスが自動的にeduroamネットワークを検出・接続
- 802.11u規格に基づくネットワーク検出
- SIMベース認証との統合も将来的に可能

---

## 9. 価格帯・ライセンス体系

### ライセンス費用

**ライセンス費用は不要**。

これはUniFiの最大の優位性の一つ。Cisco MerakiやAruba Centralのような年間ライセンス費用がかからない:

| ベンダー | ライセンス費用 | 備考 |
|---------|--------------|------|
| **Ubiquiti UniFi** | **無料** | コントローラソフトウェア無料 |
| Cisco Meraki | 年間ライセンス必須 | ライセンス切れでAP停止 |
| Aruba Central | 年間サブスクリプション | 管理機能に必要 |

### コントローラーハードウェアオプション

コントローラは以下のいずれかで動作:

| 方式 | 製品/構成 | 参考価格(USD) | 適用規模 |
|------|----------|---------------|---------|
| ゲートウェイ内蔵 | Cloud Gateway Ultra (UCG-Ultra) | ~$129 | 小規模（〜20台） |
| ゲートウェイ内蔵 | Cloud Gateway Max (UCG-Max) | $199 | 中規模（〜40台） |
| ゲートウェイ内蔵 | Dream Machine SE (UDM-SE) | ~$499 | 中〜大規模 |
| ゲートウェイ内蔵 | Dream Machine Pro Max | $599 | 大規模 |
| セルフホスト | Linux VM/VPS | VPSコストのみ | 任意の規模 |
| 専用ハード | Cloud Key Gen2+ | ~$199 | 小〜中規模 |

### AP価格帯まとめ

| カテゴリ | モデル | 価格帯(USD) | 日本円概算 |
|---------|--------|-------------|-----------|
| エントリー | U6 Lite / U7 Lite | $99 | 約15,000円 |
| ミドル | U6 Pro / U7 Pro | $159-189 | 約24,000-29,000円 |
| ハイエンド | U7 Pro Max / U6 Enterprise | $279 | 約43,000円 |
| 最上位 | U7 Pro XG / U7 Pro XGS | $199-299 | 約30,000-46,000円 |

### TCO（総所有コスト）試算例: AP 30台構成

| 項目 | UniFi | Cisco Meraki（参考） |
|------|-------|---------------------|
| AP (30台) | $5,670 (U7 Pro x30) | ~$24,000+ |
| コントローラ | $0 (セルフホスト) | ライセンス込み |
| 年間ライセンス | $0 | ~$3,000+/年 |
| 5年間TCO | ~$5,670 | ~$39,000+ |

---

## 10. エンタープライズ用途での制約・注意事項

### 制約事項

| 項目 | 詳細 |
|------|------|
| **サポート体制** | コミュニティベースが中心。有料サポートオプションは限定的。Aruba/Ciscoのような24/7エンタープライズサポートは期待できない |
| **大規模展開** | 100台超のAP管理では、Aruba/Cisco/Merakiに比べて管理ツールの成熟度が劣る |
| **セキュリティ機能** | アドバンストセキュリティ機能（WIDs/WIPs、RFプロファイリング等）はAruba/Ciscoに比べて限定的 |
| **802.11r実装** | 純粋な802.11rではなくUbiquiti独自実装。エンタープライズ要件で問題となる可能性は低いが留意 |
| **分析・レポート** | 大規模環境でのアナリティクス集約・ポリシー展開がAruba/Ciscoほど洗練されていない |
| **冗長性** | コントローラの冗長構成（HA）のサポートが限定的 |
| **SLA** | 明確なSLA保証がない |

### eduroam導入における評価

| 評価項目 | 判定 | コメント |
|---------|------|---------|
| 802.1X/EAP-TTLS/PAP | OK | RADIUSプロキシとして透過的に動作 |
| Dynamic VLAN | OK | RADIUS属性による動的割り当て対応 |
| Passpoint/OpenRoaming | OK | UniFi Network 8.4+で対応 |
| 802.11k/v/r | OK | 独自実装を含むが実用上問題なし |
| FreeRADIUS連携 | OK | 多数の実績あり |
| RadSec | OK | UniFi Network 8.4+で対応 |
| ライセンスコスト | 優秀 | 完全無料 |
| GEANT公式サポート | OK | eduroam wikiに設定ガイドあり |
| 大規模管理（100台+） | 要注意 | セルフホストで対応可能だが制約あり |
| エンタープライズサポート | 要注意 | コミュニティベース中心 |

### 総合評価

**eduroam導入用APとして十分に適格。** 特に以下の点で優位:

1. **コストパフォーマンス**: AP単価とライセンス不要の組み合わせで、Aruba/Cisco比で大幅なコスト削減
2. **eduroam互換性**: GEANTの公式wikiに設定ガイドがあり、eduroamコミュニティでの利用実績あり
3. **Passpoint/OpenRoaming**: 最新ファームウェアで対応済み
4. **FreeRADIUS連携**: 十分な実績と情報あり
5. **管理の容易さ**: UniFi Network Applicationは直感的なUIで設定しやすい

**注意が必要な点**:
- エンタープライズサポートが必要な場合はAruba/Ciscoを検討
- 100台を超える大規模展開では管理ツールの制約を確認
- 国内販売代理店・サポート体制の確認が必要

---

## 参考リンク

### 公式ドキュメント
- [UniFi WiFi - Tech Specs](https://techspecs.ui.com/unifi/wifi)
- [Configuring a RADIUS Server in UniFi](https://help.ui.com/hc/en-us/articles/360015268353-Configuring-a-RADIUS-Server-in-UniFi)
- [Setting Up Passpoint on UniFi Network](https://help.ui.com/hc/en-us/articles/25473982758551-Setting-Up-Passpoint-on-UniFi-Network)
- [Self-Hosting UniFi](https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi)
- [Choosing the Right UniFi Control Plane](https://help.ui.com/hc/en-us/articles/30127033090071-Choosing-the-Right-UniFi-Control-Plane)
- [UniFi WiFi SSID and AP Settings Overview](https://help.ui.com/hc/en-us/articles/32065480092951-UniFi-WiFi-SSID-and-AP-Settings-Overview)

### eduroam関連
- [GEANT Wiki - Ubiquiti UniFi OpenRoaming configuration snippet](https://wiki.geant.org/pages/viewpage.action?pageId=831553537)
- [GEANT Wiki - Passpoint / Hotspot 2.0](https://wiki.geant.org/pages/viewpage.action?pageId=121346191)
- [GitHub - UniFi-Okta-Radius-EAP-TTLS](https://github.com/ankorez/UniFi-Okta-Radius-EAP-TTLS)

### FreeRADIUS連携
- [Using freeradius to assign VLANs for UniFi Wi-Fi](https://neilzone.co.uk/2021/09/using-freeradius-to-assign-vlans-for-unifi-wi-fi/)
- [Ubiquiti 802.1X with FreeRadius](https://chewonice.com/2022/10/06/ubiquiti-802-1x-with-freeradius/)
- [UniFi with Freeradius Part 1 (Medium)](https://codebeta.medium.com/unifi-with-freeradius-part-1-setup-radius-with-mariadb-mysql-7b368d4f1f15)

### 比較・レビュー
- [UniFi AP Comparison Guide (LazyAdmin)](https://lazyadmin.nl/home-network/unifi-ap-comparison-2021/)
- [UniFi Fast Roaming Explained (LazyAdmin)](https://lazyadmin.nl/home-network/unifi-fast-roaming/)
- [UniFi's Advanced Wi-Fi Settings Explained (McCann Tech)](https://evanmccann.net/blog/2021/11/unifi-advanced-wi-fi-settings)
- [Wireless Solution Comparison: Ubiquiti vs. Meraki vs. Aruba](https://www.datadirectglobal.com/blogs/it-knowledge-sharing/wireless-solution-comparison-ubiquiti-vs-meraki-vs-aruba)
- [UniFi E7 Review (Dong Knows Tech)](https://dongknows.com/ubiquiti-enterprise-7-unifi-e7-review/)
- [U7 Pro Max Review (Dong Knows Tech)](https://dongknows.com/ubiquiti-unifi-u7-pro-max-wi-fi-7-ap-review/)
