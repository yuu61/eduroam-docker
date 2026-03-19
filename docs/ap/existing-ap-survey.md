# 既存アクセスポイント調査

学内に設置されている既存APの仕様調査。eduroam導入に向けたWPA2-Enterprise対応状況とセキュリティ評価を目的とする。

調査日: 2026-03-19
調査場所: 神戸電子専門学校 北野校舎4F付近（IT_H4Sに接続した状態でスキャン）
調査方法: `netsh wlan show networks mode=bssid` / `netsh wlan show interfaces` / `netsh wlan show profiles`
調査端末: Intel Wi-Fi 6E AX211 160MHz

---

## 調査結果サマリ

- 検出ネットワーク数: **37 SSID**
- 学内AP関連ベンダー: **4社**（YAMAHA, Buffalo, ICOM, ELECOM）
- WPA2-Enterprise対応SSID: **7個**（KOBEDENSHI_GAME, H1W, IT_S5A_2, IT_H4S, IT_H4N, IT_S4B, KD-IT-testing相当）
- セキュリティ上の問題: オープンネットワーク2件、WPA+TKIP 2件

---

## 現在接続中のAP: IT_H4S

### 基本情報

| 項目 | 値 |
|------|-----|
| **SSID** | IT_H4S |
| **ベンダー** | Buffalo (OUI: 18:c2:bf) |
| **推定機種** | WAPM-2133TR（トライバンド Wi-Fi 5） |
| **認証** | WPA2-Enterprise / 802.1X |
| **EAP方式** | PEAP（Microsoft 保護された EAP） |
| **暗号化** | CCMP + GCMP |
| **無線規格** | 802.11ac (Wi-Fi 5) |
| **ラジオ構成** | トライバンド（2.4GHz ×1 + 5GHz ×2） |

### 機種推定の根拠

- OUI `18:c2:bf` = Buffalo.INC
- 3つのBSSIDが連番（:41, :51, :61）→ 同一物理APのトライバンド構成
- Buffalo AirStation Proでトライバンド対応かつWPA2-Enterprise対応 → **WAPM-2133TR** が最有力
- WAPM-2133TRの仕様: 802.11ac Wave 2、3バンド同時、最大384クライアント（128×3）、マルチSSID最大48個

### 検出されたBSSID

| BSSID | バンド | チャネル | 無線タイプ | シグナル |
|-------|--------|---------|-----------|---------|
| 18:c2:bf:61:fb:41 | 2.4 GHz | ch2 | 802.11ac | 91% |
| 18:c2:bf:61:fb:51 | 5 GHz | ch48 | 802.11ac | 94%（接続中） |
| 18:c2:bf:61:fb:61 | 5 GHz | ch140 | 802.11ac | 83% |

### マルチSSID運用

同一物理AP（18:c2:bf:61:fb）から以下のSSIDが配信されていることを確認:

| SSID | BSSID末尾 | 認証 | 用途 |
|------|-----------|------|------|
| IT_H4S | :41/:51/:61 | WPA2-Enterprise | 教室用（802.1X認証） |
| KD-IT-testing | :40/:50/:60 | WPA2-Personal | テスト用 |

### eduroam適合性評価

| 要件 | 状態 | 備考 |
|------|------|------|
| WPA2-Enterprise | **対応** | 現在運用中 |
| EAP-TTLS/PAP | **動作可能** | APはEAPパススルー。現在はPEAPだが方式はRADIUS側で決定 |
| 802.11k/v/r | **非対応** | WAPM-2133TRはWi-Fi 5世代で802.11k/v/r非対応 |
| Dynamic VLAN | **不明** | Buffalo公式ドキュメントに明示的な記載なし |
| WPA3-Enterprise | **非対応** | Wi-Fi 5世代のため |

### 接続プロファイル詳細

`netsh wlan show profiles name=IT_H4S key=clear` の結果:

```
認証          : WPA2-エンタープライズ
暗号          : GCMP / CCMP
802.1X        : 有効
EAP の種類    : Microsoft: 保護された EAP (PEAP)
資格情報      : ユーザーの資格情報
キャッシュ    : はい
```

---

## 学内AP ベンダー別一覧

### YAMAHA (OUI: ac:44:f2, 00:a0:de) — 最多

| SSID | BSSID（代表） | 無線タイプ | バンド | 認証 | 暗号化 |
|------|-------------|-----------|--------|------|--------|
| KOBEDENSHI_GAME | ac:44:f2:5d:be:c8 他5件 | 802.11ac | 2.4/5 GHz | WPA2-Enterprise | CCMP |
| H1W | ac:44:f2:5b:63:10 | 802.11n | 2.4 GHz | WPA2-Enterprise | CCMP |
| IT_S5A_2 | ac:44:f2:5b:5d:90/88 | 802.11ac/n | 2.4/5 GHz | WPA2-Enterprise | CCMP |
| IT_H4N | ac:44:f2:59:94:80/88 | 802.11n/ac | 2.4/5 GHz | WPA2-Enterprise | CCMP |
| IT_S4B | ac:44:f2:5b:5c:b0 | 802.11n | 2.4 GHz | WPA2-Enterprise | CCMP |
| MainStaffRoom | ac:44:f2:5d:b8:08 | 802.11ac | 2.4 GHz | WPA3-Personal | CCMP |
| SHOKUINSHITSU | 00:a0:de:98:7f:a8 | 802.11n | 2.4 GHz | **オープン** | **なし** |

**推定機種**: OUI `ac:44:f2` はYAMAHA WLXシリーズ。802.11ac対応のものはWLX402/WLX313相当、802.11n のみのものはそれ以前の世代の可能性。

### Buffalo (OUI: 18:c2:bf, 00:16:01)

| SSID | BSSID（代表） | 無線タイプ | バンド | 認証 | 暗号化 |
|------|-------------|-----------|--------|------|--------|
| IT_H4S | 18:c2:bf:61:fb:51 | 802.11ac | 2.4/5 GHz | WPA2-Enterprise | CCMP |
| KD-IT-testing | 18:c2:bf:61:fb:40 | 802.11ac | 2.4/5 GHz | WPA2-Personal | CCMP |
| SOFTBUNYA34_2_G | 00:16:01:f8:49:62 | **802.11g** | 2.4 GHz | WPA2-Personal | **TKIP** |
| SOFTBUNYA34_2_A | 00:16:01:f8:49:63 | **802.11a** | 5 GHz | WPA2-Personal | **TKIP** |

**注意**: SOFTBUNYA34は802.11g/a世代（Wi-Fi 3相当）でTKIP暗号化を使用。非常に古く、セキュリティ上もリプレース推奨。

### ICOM (OUI: 00:90:c7)

| SSID | BSSID（代表） | 無線タイプ | バンド | 認証 | 暗号化 |
|------|-------------|-----------|--------|------|--------|
| WAVEMASTER-0 | 00:90:c7:00:33:6e/6d | 802.11n | 2.4 GHz | **オープン** | **なし** |
| TtotWT | 00:90:c7:02:34:64 | 802.11n | 2.4 GHz | WPA2-Personal | CCMP |
| (KD-IT-testing内) | 00:90:c7:02:34:ab/7b | 802.11n | 5 GHz | WPA2-Personal | CCMP |

**注**: ICOM WAVEMASTERシリーズは業務用無線LAN AP。802.11n世代。

### ELECOM (OUI: 04:ab:18)

| SSID | BSSID（代表） | 無線タイプ | バンド | 認証 | 暗号化 |
|------|-------------|-----------|--------|------|--------|
| KOKUSAI-COMM | 04:ab:18:d9:4a:f2 他2件 | 802.11ax | 2.4/5 GHz | WPA3-Personal | CCMP |

**注**: 唯一のWi-Fi 6 (802.11ax) 対応AP。「国際コミュニケーション学科」用と推測。

---

## セキュリティ上の懸念事項

### 重大（要対応）

| SSID | 問題 | リスク |
|------|------|--------|
| **SHOKUINSHITSU** (YAMAHA) | オープン/暗号化なし | 職員室ネットワークが平文通信。盗聴・不正接続が容易 |
| **WAVEMASTER-0** (ICOM) | オープン/暗号化なし | 同上 |

### 中（改善推奨）

| SSID | 問題 | リスク |
|------|------|--------|
| **SOFTBUNYA34_2_G/A** (Buffalo) | WPA2-Personal + TKIP | TKIPは非推奨（Wi-Fi Allianceは2012年に廃止勧告）。802.11g/a世代で極めて古い |
| 2CB60A..., 15FACB... (Buffalo) | WPA-Personal | WPAv1は脆弱性が知られている |

---

## 無線規格の世代分布

検出された学内APのWi-Fi世代:

| Wi-Fi世代 | 規格 | AP数（BSSID単位） | 割合 | 802.11k/v/r |
|-----------|------|-------------------|------|-------------|
| Wi-Fi 6 (ax) | 802.11ax | 3 | 少数 | 対応可能 |
| Wi-Fi 5 (ac) | 802.11ac | 約15 | 多数 | **非対応** |
| Wi-Fi 4 (n) | 802.11n | 約15 | 多数 | **非対応** |
| Wi-Fi 3以前 (g/a) | 802.11g/a | 4 | 少数 | **非対応** |

**結論**: 学内APの大半がWi-Fi 4/5世代で、802.11k/v/rによる高速ローミングは期待できない。eduroam導入自体はWPA2-Enterprise対応APで可能だが、AP間ローミングはクライアント自律判断に依存する。

---

## eduroam導入に向けた評価

### 既存APでのeduroam導入可否

| 条件 | 評価 |
|------|------|
| WPA2-Enterprise対応AP | **あり**（YAMAHA/Buffalo計7 SSID以上で運用中） |
| 外部RADIUSサーバ指定 | **可能**（現在もPEAPで802.1X認証を運用中） |
| EAP-TTLS/PAP | **動作可能**（APはEAPパススルー、方式はRADIUS側で決定） |
| eduroam SSID追加 | **可能**（マルチSSID対応APが確認済み） |

**既存のWPA2-Enterprise対応APにeduroam SSIDを追加配信することで、AP更新なしでeduroam導入が可能。**

### 制約事項

- 802.11k/v/r非対応のため、AP間移動時にフル再認証が発生（EAP-TTLS/PAPは軽量なため体感1-2秒）
- Dynamic VLAN対応が不明確（Buffalo/YAMAHA共に公式記載なし）
- ベンダー4社混在のため、統一的な管理・設定変更が困難
- Wi-Fi 4 (802.11n) 世代のAPはeduroam SSID追加によるパフォーマンス低下の懸念

---

## 現行SSID構成の問題: SSIDによる接続台数制御（要改善）

保存済みWiFiプロファイルの分析（`netsh wlan show profiles name="<SSID>" key=clear`）から、**教室・エリアごとに個別のSSIDを割り当てることで、APあたりの接続台数を分散制御している**ことが判明。

> **この方式は根本的に間違っている。** SSID乱立による接続台数制御はWLCが存在しない環境での苦肉の策であり、管理の複雑化・ローミング不可・セキュリティ低下を招く。**WLC導入によるSSID統合と適切なクライアント負荷分散への移行が必須。**

### SSIDの全体構成

#### WPA2-Enterprise（802.1X認証）— 教室用

| SSID | 推定場所 | 認証 | EAP方式 | 備考 |
|------|---------|------|---------|------|
| IT_H4S | 北野校舎4F南 | WPA2-Enterprise | PEAP | 現在接続中 |
| IT_H4N | 北野校舎4F北 | WPA2-Enterprise | PEAP（推定） | |
| IT_S5A_2 | S棟5F A教室 | WPA2-Enterprise | PEAP（推定） | |
| IT_S4B | S棟4F B教室 | WPA2-Enterprise | PEAP（推定） | |
| H1W | 北野校舎1F西 | WPA2-Enterprise | PEAP（推定） | |
| KOBEDENSHI_GAME | ゲーム学科 | WPA2-Enterprise | PEAP（推定） | 複数AP（BSSID 6件） |

#### WPA2/WPA3-Personal（PSK認証）— 教室・エリア用

| SSID | 推定場所/用途 | 認証 | PSK共有範囲 |
|------|-------------|------|------------|
| IT_4C | 4C教室 | WPA2-Personal | 同一パスワードをIT_4Aと共有 |
| IT_4A | 4A教室 | WPA2-Personal | 同一パスワードをIT_4Cと共有 |
| IT_MMPC | MMPC教室 | WPA2-Personal | 教室固有のパスワード |
| KD-IT-testing | IT科テスト用 | WPA2/3-Personal | |
| KOBEDENSHI_S00 | 全学ゲスト？ | WPA3-Personal | 推測容易なパスワード |

#### 学科・施設固有SSID

| SSID | 推定場所/用途 | 認証 |
|------|-------------|------|
| JCOM_VCEM | 声優演技学科（Voice Entertainment Communications） | WPA2/3-Personal |
| JCOM_TYJX | 通訳翻訳学科？ | WPA2/3-Personal |
| JCOM_OMTK | 音楽テクノロジー学科？ | WPA2/3-Personal |
| JCOM_NIMS | 日本語教育？ | WPA2/3-Personal |
| DomeHall | ドームホール（サウンド系） | WPA2/3-Personal |
| opedu | オープンエデュケーション？ | WPA2/3-Personal |

#### KIC（神戸情報大学院大学）

| SSID | 用途 | 認証 |
|------|------|------|
| KIC_special | 教職員/特別用途 | WPA2-Personal |
| KIC_GUEST | 来客用 | WPA2-Personal |

#### その他

| SSID | 用途 | 認証 |
|------|------|------|
| MainStaffRoom | 職員室（メイン） | WPA3-Personal |
| jukousha_01 | 受講者用 | WPA2/3-Personal |
| foyer | ホワイエ | WPA2/3-Personal |
| bld2-guest | 2号館ゲスト | WPA2/3-Personal |
| R1FWIFI | 1F共有？ | **オープン（暗号化なし）** |
| guest | ゲスト | **オープン（暗号化なし）** |

### 現行方式の問題点

```
[現行: SSIDベースの分散（WLCなし）]
  教室A → IT_4A (専用SSID)
  教室B → IT_S4B (専用SSID)
  教室C → IT_4C (専用SSID)
  ゲーム学科 → KOBEDENSHI_GAME
  声優学科 → JCOM_VCEM
  ...SSID が際限なく増殖
```

| 問題 | 影響 |
|------|------|
| **SSID乱立** | 30以上のSSIDが混在。学生・教職員が接続先を覚えきれない |
| **ローミング不可** | 教室を移動するたびに異なるSSIDに手動で切り替える必要がある |
| **PSKの脆弱性** | PSK共有方式では退職者・卒業生のアクセス取消が不可能 |
| **パスワード品質** | 推測容易なパスワード、`12345678` のような極めて脆弱なものが存在 |
| **管理コスト** | SSID追加・パスワード変更を全APに個別設定する必要がある |
| **オープンSSIDの残存** | SHOKUINSHITSU, WAVEMASTER-0, R1FWIFI, guest が暗号化なしで稼働 |

### あるべき姿: WLCによる統一管理

```
[目標: WLC + 最小限のSSID]
  全教室共通  → "学内SSID"     (WPA2/3-Enterprise, 802.1X)
  eduroam    → "eduroam"      (WPA2-Enterprise, EAP-TTLS/PAP)
  来客用     → "guest"        (Captive Portal / WPA3-Personal)
  ────────────────────────────────────────────
  接続台数制御: WLCが担当
    - 802.11v BSS Transition（負荷ベースのAP推奨）
    - バンドステアリング（2.4GHz → 5GHz誘導）
    - Aruba ClientMatch / Cisco Adaptive 802.11r 等
    - 電波出力調整でセルサイズを教室単位に制限
```

WLC導入により、SSIDは用途別に **3つ程度** に集約できる。接続台数制御・ローミング・セキュリティはすべてWLCが一元管理する。

### PSKパスワードの傾向（参考）

> 注: パスワード自体はセキュリティ上gitに記載しない。`netsh wlan show profiles name="<SSID>" key=clear` で確認可能。

- IT_4A と IT_4C が同一PSKを共有
- 施設名・年号ベースの推測容易なパスワードが複数
- JCOM系は学科別に数字ベースのパスワード（ランダム生成風）
- 1件で `12345678` を使用（論外）
- → **PSK運用自体をやめ、802.1X認証に統一すべき**

---

## SSID命名規則

| パターン | 例 | 推測 |
|---------|-----|------|
| `IT_<棟><階><方角>` | IT_H4S, IT_H4N | IT科: H=北野校舎, 4=階, S/N=南北 |
| `IT_S<階><教室>` | IT_S5A_2, IT_S4B | IT科: S=S棟, 数字=階, A/B=教室 |
| `IT_<教室>` | IT_4C, IT_4A, IT_MMPC | IT科: 教室番号/教室名 |
| `KOBEDENSHI_*` | KOBEDENSHI_GAME, _S00 | 学科別/全学 |
| `JCOM_*` | JCOM_VCEM, _TYJX, _OMTK, _NIMS | J-COM系学科（学科略称4文字） |
| `KIC_*` | KIC_GUEST, KIC_special | 神戸情報大学院大学 |
| `H<階><方角>` | H1W | 北野校舎1F西 |
| 施設名そのまま | DomeHall, MainStaffRoom, foyer | 共用施設 |

---

## 今後のアクション

1. **他の棟・階でも同様のスキャンを実施** — 全棟のAP機種リストを完成させる
2. **YAMAHA APの正確な機種を特定** — 管理画面またはSNMPで確認
3. **既存RADIUS構成の確認** — 現在のPEAP認証で使用しているRADIUSサーバの所在と設定
4. **eduroam SSID追加のテスト** — IT_H4S（Buffalo WAPM-2133TR推定）で試験的にeduroam SSIDを追加
5. **オープンネットワークの対処** — SHOKUINSHITSU, WAVEMASTER-0のセキュリティ改善
6. **SOFTBUNYA34のリプレース** — 802.11g/a + TKIP は即座に更新すべき

---

## 参考: 調査コマンド

```powershell
# 検出可能な全ネットワーク（BSSID付き）
netsh wlan show networks mode=bssid

# 現在接続中のインターフェース情報
netsh wlan show interfaces

# 保存済みプロファイル詳細
netsh wlan show profiles name="<SSID名>" key=clear

# WiFiドライバの対応規格
netsh wlan show drivers

# OUIベンダー検索（macvendors.com API）
curl -s "https://api.macvendors.com/<OUI>"
```
