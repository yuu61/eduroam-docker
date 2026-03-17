# 仮想化技術比較レポート

eduroam導入プロジェクトにおける仮想化基盤の選定資料。
RADIUSサーバに加え、監視基盤・ログ管理・運用支援サービス等の複数サービスを同一基盤上で運用することを前提に評価する。

調査日: 2026-03-17（初版: 2026-03-16）

---

## 1. 前提: 基盤上で稼働させるサービス群

eduroamの安定運用には、RADIUSサーバ単体ではなく以下のサービス群が必要となる。

### 1.1 必須サービス

| サービス | 役割 | 想定実装 |
|---------|------|---------|
| **FreeRADIUS** | 802.1X認証（IdP/SP） | FreeRADIUS 3.2.6 |
| **監視・メトリクス** | サーバ/サービス死活監視、認証成功率、応答時間 | Prometheus 3.10 + Grafana 12.4 |
| **ログ管理** | RADIUS認証ログ集約、監査対応 | Loki 3.6 + Grafana Alloy（※Promtailは2026-03-02 EOL） |
| **アラート通知** | 障害時の自動通知 | Alertmanager 0.31（→ メール/Slack） |

### 1.2 推奨サービス

| サービス | 役割 | 想定実装 |
|---------|------|---------|
| **リバースプロキシ** | Grafana等の管理UIへのHTTPSアクセス | Nginx / Caddy |
| **証明書監視** | UPKIサーバ証明書の有効期限監視 | blackbox_exporter（TLSプローブ） |
| **SNMP監視** | AP・スイッチのステータス監視 | snmp_exporter |
| **RADIUSメトリクス** | FreeRADIUS認証統計の収集 | freeradius_exporter（Prometheus用） |
| **バックアップ** | 設定・データの定期バックアップ | vzdump（Proxmox）/ restic |

### 1.3 将来的に検討するサービス

| サービス | 役割 | 想定実装 |
|---------|------|---------|
| **RADIUS accounting分析** | 利用統計、傾向分析 | FreeRADIUS detail + カスタムダッシュボード |
| **端末オンボーディング** | WiFiプロファイル配布 | eduroam CAT（GEANT運営・無料）/ SecureW2 |
| **NMS** | ネットワーク機器統合管理 | LibreNMS / Zabbix |

### 1.4 リソース要件見積もり

| サービス | vCPU | メモリ | ストレージ | 備考 |
|---------|------|--------|-----------|------|
| FreeRADIUS | 1 | 512 MB - 1 GB | 1 GB | 軽量。認証バースト時にCPU負荷 |
| Prometheus 3.10 | 0.5-1 | 768 MB | 8 GB | 5,000時系列・30日保持で約2GB。余裕込み |
| Grafana 12.4 | 0.25-0.5 | 384 MB | 1 GB | SQLiteで小規模は十分 |
| Loki 3.6（monolithic） | 0.5-1 | 512 MB | 5 GB | 認証ログ約15MB/日→30日で約3GB（圧縮後） |
| Alertmanager 0.31 | 0.1 | 64 MB | 0.1 GB | 極めて軽量 |
| Grafana Alloy（ログ+メトリクス収集） | 0.25 | 192 MB | 0.1 GB | Promtail後継。ログとメトリクスを統合収集 |
| freeradius_exporter | 0.1 | 64 MB | - | FreeRADIUS status serverからメトリクス収集 |
| snmp_exporter | 0.1 | 64 MB | - | AP/SW数に依存 |
| Nginx/Caddy | 0.1 | 128 MB | 0.5 GB | リバースプロキシ |
| **合計（サービス分）** | **約3** | **約2.7 GB** | **約16 GB** | |
| ホストOS/基盤オーバーヘッド | - | 2 GB | 10 GB | Proxmox VE / Linux OS |
| **総合計（最小）** | **約3** | **約5 GB** | **約26 GB** | |
| **総合計（推奨・余裕込み）** | **4-8** | **8-16 GB** | **60-120 GB** | 将来のサービス追加・保持期間延長に対応 |

**推奨ハードウェア**: 8コアCPU / 16GB RAM / 256GB SSD（データ用に別途HDD/SSD推奨）

> **Prometheusディスク計算根拠**: 5,000アクティブ時系列 × 15秒間隔スクレイプ × 30日保持 = 約2.1GB（`retention_seconds × ingested_samples/s × 2 bytes × 1.2`）
>
> **Lokiディスク計算根拠**: 1認証イベント約500バイト × 5,000ユーザー × 日次2-3回認証 = 約7.5-15MB/日（生データ）。Lokiの圧縮で30-50%に削減

---

## 2. 技術概要サマリ

| 項目 | Proxmox VE | Docker | k3s | Hyper-V |
|------|-----------|--------|-----|---------|
| **分類** | ハイパーバイザー + コンテナ基盤 | アプリケーションコンテナ | コンテナオーケストレーション | ハイパーバイザー |
| **仮想化方式** | KVM（完全仮想化）+ LXC（システムコンテナ） | OCI コンテナ（namespaces/cgroups） | OCI コンテナ + オーケストレーション | Type-1 ハイパーバイザー（完全仮想化） |
| **最新バージョン** | 9.1（2025年11月） | Engine 29.3 / Compose v5.1 | v1.35.2+k3s1（LTS: v1.34.5） | Windows Server 2025 |
| **ライセンス** | AGPL v3（無償で全機能利用可） | Engine: Apache 2.0（無償）/ Desktop: 商用 | Apache 2.0（無償） | Windows Server ライセンス必要 |
| **管理UI** | WebUI（ポート8006） | CLI / Docker Desktop GUI | kubectl CLI / Dashboard / Lens | Hyper-Vマネージャー / WAC |
| **対象** | サーバ仮想化基盤 | アプリケーション開発・デプロイ | コンテナのスケーリング・管理 | Windows中心のサーバ仮想化 |
| **マルチサービス管理** | WebUIから全VM/LXCを統合管理 | Compose で定義・管理 | kubectl / Helm で宣言的管理 | Hyper-Vマネージャー / WAC |

---

## 3. システム要件比較

### 最小要件

| 項目 | Proxmox VE | Docker Engine | k3s | Hyper-V |
|------|-----------|---------------|-----|---------|
| **CPU** | Intel VT / AMD-V 対応 | 64bit | 1コア | SLAT対応 64bit |
| **メモリ** | 2GB + ゲスト分 | 512MB | 512MB（1GB推奨） | 4GB + ゲスト分 |
| **ディスク** | 特に制限なし | 数GB | 1GB（10GB推奨） | VHDXサイズ依存 |
| **インストール先** | ベアメタル専用 | Linux OS上 | Linux OS上 | ベアメタル / Windows上 |

### 本プロジェクトでの目安（RADIUS + 監視基盤 + 運用サービス群）

| 構成 | CPU | メモリ | ストレージ | 備考 |
|------|-----|--------|-----------|------|
| **Proxmox VE** | 8コア推奨 | 16GB推奨 | 256GB SSD + データ用 | ホスト2GB + LXC群6GB + 余裕 |
| **Docker on Linux** | 4-8コア | 8-16GB | 256GB SSD | ホストOS + 全コンテナ共有カーネル |
| **k3s on Linux** | 4-8コア | 8-16GB | 256GB SSD | k3sオーバーヘッド約1GB追加 |
| **Hyper-V** | 8コア推奨 | 16-24GB推奨 | 256GB SSD | VM毎にカーネル分のメモリが必要 |

---

## 4. コスト比較

| 項目 | Proxmox VE | Docker | k3s | Hyper-V |
|------|-----------|--------|-----|---------|
| **ソフトウェア費用** | 無料（全機能） | Engine: 無料 | 無料 | Windows Serverライセンス必要 |
| **有償オプション** | サブスクリプション €115〜/ソケット/年 | Desktop Pro $9/月〜 | マネージドサービス $72/月〜 | Standard/Datacenter CAL |
| **教育機関向け** | 公式割引なし（無償で十分） | Personal無料（学生） | 無料 | EES/Azure Dev Tools for Teaching |
| **追加HW** | 専用物理サーバ必要 | 既存サーバで動作 | 既存サーバで動作 | 専用物理サーバ or Windows PC |

### コスト試算（RADIUS + 監視基盤構成）

| 構成 | 初期コスト | 年間コスト |
|------|----------|----------|
| **Docker on Linux サーバ** | サーバ購入費のみ | 0円 |
| **k3s on Linux サーバ** | サーバ購入費のみ | 0円 |
| **Proxmox VE on 専用サーバ** | サーバ購入費のみ | 0円（Community版） |
| **Hyper-V on Windows Server** | サーバ購入費 + WS ライセンス | CAL費用 |

---

## 5. マルチサービス管理能力の比較

RADIUS単体ではなく5〜10のサービスを運用する場合の管理能力を評価する。

| 機能 | Proxmox VE | Docker Compose | k3s | Hyper-V |
|------|-----------|----------------|-----|---------|
| **サービス定義** | WebUIで個別作成 | YAML（docker-compose.yml） | YAML（Helm/Kustomize） | GUIで個別作成 |
| **起動/停止の一括管理** | WebUIでVM/LXC個別操作 | `docker compose up/down` | `kubectl apply` | GUIで個別操作 |
| **自動再起動** | LXCの`onboot`設定 | `restart: unless-stopped` | Pod自動再作成 | VM自動起動設定 |
| **ヘルスチェック** | 基本的な死活監視 | `healthcheck`ディレクティブ | liveness/readinessプローブ | なし（外部ツール依存） |
| **リソース制限** | LXC/VMごとにCPU/メモリ制限 | `deploy.resources` | `resources.limits/requests` | VM単位で設定 |
| **ローリングアップデート** | 手動（スナップショット→更新） | `docker compose up -d` | `kubectl rollout` | 手動 |
| **ログ集約** | 各LXC/VMの`journalctl` | `docker compose logs` | `kubectl logs` / Fluent Bit | イベントビューア |
| **シークレット管理** | ファイルベース（各ゲスト内） | `.env` / Docker Secrets | Kubernetes Secrets | ファイルベース |
| **IaC対応** | Terraform / Ansible | Dockerfile + Compose | Helm / Kustomize / ArgoCD | PowerShell DSC |
| **構成のバージョン管理** | 設定ファイルをgit管理可能 | docker-compose.yml をgit管理 | マニフェストをgit管理（GitOps） | 困難 |

### 管理負荷の評価

| サービス数 | Docker Compose | k3s | Proxmox VE | Hyper-V |
|-----------|----------------|-----|-----------|---------|
| 1-3 | 非常に容易 | オーバースペック | 容易 | 容易 |
| 4-7 | 容易 | 適切 | 容易 | やや煩雑 |
| 8-15 | やや煩雑 | 適切 | 容易（WebUI統合） | 煩雑 |
| 16+ | 困難（Swarm不要なら限界） | 最適 | 容易 | 煩雑 |

---

## 6. ネットワーク機能比較

| 機能 | Proxmox VE | Docker | k3s | Hyper-V |
|------|-----------|--------|-----|---------|
| **VLAN** | VLAN-aware bridge | macvlan / ipvlan | CNI依存 | 仮想スイッチでVLAN設定 |
| **SDN** | Fabrics（OpenFabric/OSPF）、EVPN対応 | overlay（Swarm） | Calico / Cilium / Flannel | Datacenter版のみ |
| **ファイアウォール** | 3階層（DC/ノード/VM） | iptables自動管理 | NetworkPolicy | Windows Firewall |
| **L2接続** | Linux bridge | macvlan / bridge | macvlan CNI | External仮想スイッチ |
| **UDP対応** | ネイティブ | ポートマッピング / host mode | Service(UDP) ※制約あり | ネイティブ |
| **サービス間通信** | ゲスト間はブリッジ経由 | Docker network | ClusterIP Service | 仮想スイッチ経由 |

### RADIUS通信（UDP 1812/1813）への適性

- **Proxmox VE**: LXC/VMが物理NICに直結可能。最も自然
- **Docker**: `host`ネットワークモードまたはポートマッピングで対応
- **k3s**: `hostNetwork: true`またはNodePortで対応。LoadBalancerのUDPヘルスチェックが未成熟
- **Hyper-V**: External仮想スイッチで物理ネットワークに直結

### マルチサービス環境でのネットワーク分離

| 要件 | Proxmox VE | Docker | k3s | Hyper-V |
|------|-----------|--------|-----|---------|
| RADIUS（外部公開）と監視（内部）の分離 | VLAN-aware bridgeで容易 | Docker networkで分離 | NetworkPolicyで制御 | 仮想スイッチで分離 |
| 監視→RADIUSのメトリクス収集 | ブリッジ経由で直接通信 | 同一Docker network | ClusterIP Service | 仮想スイッチ経由 |
| Grafana WebUIの外部公開 | リバースプロキシ推奨 | ポートマッピング | Ingress（Traefik内蔵） | リバースプロキシ推奨 |

---

## 7. 高可用性（HA）比較

| 機能 | Proxmox VE | Docker | k3s | Hyper-V |
|------|-----------|--------|-----|---------|
| **自動フェイルオーバー** | HA Manager（3ノード〜） | Swarm mode（非推奨傾向） | Pod自動再スケジュール | フェイルオーバークラスタ |
| **ライブマイグレーション** | 共有ストレージ上で対応 | なし | Pod再作成（Rolling Update） | 対応（Shared Nothing含む） |
| **最小HA構成** | 3ノード + Ceph | Docker Swarm 3ノード | k3s 3サーバノード | 2ノード + 共有ストレージ |
| **レプリケーション** | Ceph / ZFS | なし（外部ツール） | etcd Raft / PV CSI | Hyper-V レプリカ |
| **DR（災害復旧）** | PBS連携 | なし | Velero等 | Azure Site Recovery |

---

## 8. 管理・自動化比較

| 項目 | Proxmox VE | Docker | k3s | Hyper-V |
|------|-----------|--------|-----|---------|
| **API** | REST API（全機能） | Docker API（REST） | Kubernetes API | WMI / PowerShell |
| **IaC** | Terraform / Ansible | Dockerfile / Compose | Helm / Kustomize / ArgoCD | PowerShell DSC |
| **構成管理** | Ansible対応 | Dockerfile / Compose | GitOps（ArgoCD/Flux） | SCVMM / Ansible（限定的） |
| **バックアップ** | PBS / vzdump（スケジュール対応） | Volume export | Velero / Longhorn backup | Windows Server Backup |
| **監視** | 組み込みメトリクス + pve-exporter | cAdvisor / Prometheus | Prometheus / Grafana 統合 | Windows Admin Center |

---

## 9. セキュリティ比較

| 項目 | Proxmox VE | Docker | k3s | Hyper-V |
|------|-----------|--------|-----|---------|
| **分離レベル** | VM: 完全分離 / LXC: カーネル共有 | namespaces（カーネル共有） | namespaces（カーネル共有） | VM: 完全分離 |
| **root権限** | VM内で独立 | rootless mode対応 | Pod Security Standards | VM内で独立 |
| **ネットワーク制御** | ファイアウォール + VLAN + SDN | iptables / seccomp | NetworkPolicy | 仮想スイッチ + Windows FW |
| **証明書管理** | 手動（Ansible推奨） | bind mount / secret | Secret / cert-manager | 手動 |

### マルチサービス環境でのセキュリティ考慮

| リスク | Proxmox VE (LXC) | Docker | k3s | Hyper-V |
|--------|------------------|--------|-----|---------|
| RADIUSコンテナ侵害時の影響範囲 | LXC間はnamespace分離。VM使用でさらに強化可能 | コンテナ間はnamespace分離 | Pod間はnamespace分離 | VM間は完全分離 |
| 監視基盤からのRADIUSアクセス | ファイアウォールルールで制限可能 | Docker networkで制限可能 | NetworkPolicyで制限可能 | 仮想スイッチACLで制限可能 |
| ホストOS侵害時の影響 | 全ゲストに影響 | 全コンテナに影響 | 全Podに影響 | 全VMに影響 |

---

## 10. 学習コスト比較

| 項目 | Proxmox VE | Docker | k3s | Hyper-V |
|------|-----------|--------|-----|---------|
| **基礎習得** | 1-2週間 | 1-2週間 | 2-4週間 | 1-2週間 |
| **マルチサービス運用** | 2-3週間 | 2-3週間 | 1-2ヶ月 | 2-3週間 |
| **本番運用** | 3-6ヶ月 | 2-3ヶ月 | 6ヶ月-1年 | 3-6ヶ月 |
| **前提知識** | Linux管理 | Linux基礎 | Docker + ネットワーク + YAML | Windows Server管理 |
| **ドキュメント** | 充実（英語中心） | 非常に充実 | 非常に充実 | 非常に充実（日本語あり） |
| **監視スタック構築の容易さ** | LXC内で通常通り構築 | Composeで一括定義 | Helm chartで一括デプロイ | VM内で通常通り構築 |

---

## 11. eduroamプロジェクトでの適性評価

### 評価基準とスコア（5段階）

旧版（RADIUS単体）と新版（RADIUS + 監視基盤 + 運用サービス群）の比較。

| 評価基準 | Proxmox VE | Docker | k3s | Hyper-V |
|----------|:---------:|:------:|:---:|:-------:|
| **コスト** | 5 | 5 | 5 | 2 |
| **検証環境での使いやすさ** | 3 | 5 | 3 | 3 |
| **本番運用への適性** | 5 | 3 | 4 | 5 |
| **HA構成** | 5 | 2 | 5 | 4 |
| **学習コスト（低い=高スコア）** | 3 | 4 | 2 | 3 |
| **RADIUS/UDP適性** | 5 | 4 | 3 | 5 |
| **既存Docker資産の活用** | 4 | 5 | 4 | 3 |
| **ネットワーク柔軟性** | 5 | 3 | 4 | 4 |
| **バックアップ・復旧** | 5 | 2 | 3 | 4 |
| **マルチサービス管理** ★新規 | 5 | 4 | 4 | 3 |
| **監視基盤との統合** ★新規 | 5 | 4 | 5 | 3 |
| **運用の自動化・省力化** ★新規 | 4 | 3 | 5 | 3 |
| **合計** | **54** | **44** | **47** | **42** |

#### スコア変動の理由（旧版との差分）

- **Docker**: 学習コスト 5→4（マルチサービスでCompose管理が複雑化）、マルチサービス管理で加点あるが運用自動化で減点
- **k3s**: 検証環境 2→3（Helmチャートで監視スタック一括導入が容易）、監視統合・運用自動化で高評価
- **Proxmox VE**: マルチサービス管理・監視統合で高評価。WebUIからLXC群を統合管理でき、pve-exporterで基盤自体の監視も容易
- **Hyper-V**: マルチサービス管理はVM個別操作が必要で減点

### フェーズ別推奨

| フェーズ | 推奨技術 | 理由 |
|----------|---------|------|
| **Phase 1-3（検証）** | **Docker Compose（現状維持）** | 最も軽量・高速。設定変更→テストのサイクルが最短。監視はこの段階では不要 |
| **Phase 4-5（接続・実機テスト）** | **Docker on Linux サーバ** or **Proxmox VE上のLXC** | WSL2のネットワーク制約を回避。実APからのUDP通信を受けるにはネイティブ環境が必要。この段階で監視基盤を構築開始 |
| **本番運用（推奨）** | **Proxmox VE**（LXC中心） | RADIUS・監視・ログ管理をLXCで分離運用。スナップショット、バックアップ、WebUI統合管理 |
| **本番運用（HA）** | **Proxmox VE 3ノードクラスタ** | 自動フェイルオーバー、ライブマイグレーション。eduroam 24/365要件対応 |

---

## 12. 各技術の詳細

### 12.1 Proxmox VE

#### バージョン情報（v9.1 / 2025年11月）

| コンポーネント | バージョン |
|--------------|-----------|
| Linux Kernel | 6.17.2-1-pve |
| ベースOS | Debian 13 "Trixie" |
| QEMU | 10.1.2 |
| LXC | 6.0.5 |
| ZFS | 2.3.4 |
| Ceph | Squid 19.2.3 |

※ PVE 8.4はセキュリティアップデート継続中（2026年8月まで）

#### アーキテクチャ
- KVM（完全仮想化）+ LXC（システムコンテナ）を単一WebUIから統合管理
- Corosyncベースのクラスタリング、pmxcfsによる設定同期
- Cephネイティブ統合によるハイパーコンバージドインフラ（HCI）

#### v9.0-9.1の主要新機能

- **SDN Fabrics（v9.0）**: OpenFabric/OSPFプロトコル対応。ノード間で自動ルーティングトポロジを構成。EVPN/Cephネットワークの自動構成
- **SDN監視強化（v9.1）**: EVPN zone内の学習済みIP/MACアドレス表示、ファブリックトポロジのGUI統合
- **OCIイメージ対応（v9.1）**: Docker Hub等からOCIイメージをダウンロードしLXCテンプレートとして利用可能。アプリケーションコンテナとしてPrometheus/Grafana等を直接デプロイ可能
- **HA Resource Affinity Rules（v9.0）**: クラスタ内でのVM/LXC配置を細かく制御
- **vTPMスナップショット（v9.1）**: TPM状態をqcow2ディスクに保存、完全なVMスナップショット

#### ストレージ
- ローカル: LVM、ZFS、ディレクトリ
- 共有: NFS、iSCSI、GlusterFS、Ceph
- ZFS: 圧縮・重複排除・スナップショット対応

#### バックアップ
- vzdump: VM/LXCの完全バックアップ（スケジュール対応）
- Proxmox Backup Server（PBS）: 増分バックアップ、重複排除、暗号化
- Live-restore: リストア中にVM起動可能

#### LXC vs VM パフォーマンス比較

| 指標 | LXC | KVM VM |
|------|-----|--------|
| CPUオーバーヘッド | 0-2%（ほぼネイティブ） | 5-15% |
| 総合パフォーマンス | ネイティブの95-98% | ネイティブの80-90% |
| ベースメモリ消費 | 100-500 MB | 2-4 GB |
| 起動時間 | 1-3秒 | 30-90秒 |
| 分離レベル | カーネル共有（cgroup/namespace） | 完全ハードウェアレベル分離 |

**本プロジェクトへの推奨**: FreeRADIUS・Prometheus・Grafana・Loki等は全てLinuxサービスであり、ハードウェアパスルーやカーネル分離は不要。**LXCコンテナが最適**。

#### マルチサービス構成例

```
[Proxmox VE サーバ（16GB RAM / 8コア / 256GB SSD）]
  ├─ LXC: FreeRADIUS + freeradius_exporter（512MB / 1コア）
  │    └─ VLAN-aware bridge（RADIUS VLAN）
  ├─ LXC: Prometheus + Alertmanager（1GB / 1コア / 8GB data）
  │    └─ 内部ブリッジ（監視VLAN）
  ├─ LXC: Grafana + Nginx（512MB / 0.5コア）
  │    └─ 内部ブリッジ + 管理VLAN（HTTPS公開）
  ├─ LXC: Loki + Grafana Alloy（768MB / 1コア / 5GB data）
  │    └─ 内部ブリッジ
  ├─ PVEホスト: prometheus-pve-exporter
  └─ （予備: 約11GB RAM / 4.5コア → 将来のNMS等に）
```

#### 監視との統合

**FreeRADIUS メトリクス収集**:
- `bvantagelimited/freeradius_exporter`: FreeRADIUS status serverからAccept/Reject/Challenge数、キュー長等を収集（ポート9812）
- `devon-mar/radius-exporter`: ブラックボックス方式で実際のRADIUS認証プローブを送信し、エンドツーエンドの疎通を確認（ポート9881）
- Grafanaダッシュボード（ID: 19891）で可視化

**基盤メトリクス**:
- `prometheus-pve-exporter`: Proxmoxホスト自体のメトリクス（CPU/メモリ/ディスク/ネットワーク、ゲスト単位）をPrometheusに送信。読み取り専用のPVEユーザーを作成して使用
- 各LXC内のサービスはPrometheusの通常のscrape設定で監視

**ログ収集**:
- Grafana Alloy（Promtail後継）: 各LXCからFreeRADIUS認証ログを収集しLokiに送信。メトリクスとログを単一エージェントで統合収集
- ※ Promtailは2026年3月2日にEOL。`alloy convert` コマンドで既存Promtail設定を移行可能

#### WSL2との関係
- WSL2上では動作不可（ベアメタルインストール専用）
- 開発はWSL2/Docker → 本番デプロイ先としてProxmox VEという構成が自然

#### API・自動化
- REST API（全機能対応、APIトークン認証）
- Terraform: Telmate/proxmox プロバイダ（非公式）
- Ansible: community.general.proxmox / proxmox_kvm モジュール

---

### 12.2 Docker

#### アーキテクチャ
```
Docker CLI → dockerd → containerd → runc → Linux Kernel (namespaces/cgroups)
```
- イメージはレイヤー構造（overlay2）、Copy-on-Write
- コンテナ間でベースレイヤーを共有しディスク効率が高い

#### Docker Engine vs Desktop
- Engine: Linux専用、Apache 2.0（完全無料）
- Desktop: Windows/macOS/Linux、商用ライセンス（250名以上 or 年商$10M以上の企業は有償）
- 教育機関: 学生はPersonal無料、教職員はライセンス確認推奨

#### Docker Compose v5 によるマルチサービス管理

Docker Compose v5.1（2026年2月）は単一ホスト上で複数コンテナを管理するツールとして成熟している。v5はCompose v2の直接的な後継で、Go SDKの追加が主な差分。

**5〜10サービス運用時の利点**:
- `docker-compose.yml` 1ファイルで全サービスを宣言的に定義
- `docker compose up -d` で一括起動、`docker compose logs` で一括ログ確認
- `restart: unless-stopped` で自動再起動
- `healthcheck` + `depends_on: { service: { condition: service_healthy } }` で依存順序を保証
- `profiles` で開発/テスト/本番の構成を切替（例: `--profile monitoring` で監視スタックのみ起動）
- `deploy.resources.limits` でCPU/メモリ制限
- Secrets: `/run/secrets/<name>` マウント（インメモリ、ディスクに残らない）

**5〜10サービス運用時の課題**:
- ゼロダウンタイム更新は不可（`docker compose up -d` はコンテナを順次再作成）
- コンテナを手動削除した場合、自動再作成されない（desired-state reconciliationなし）
- 単一ホストを超えたスケーリングは不可（Docker Swarmは非推奨傾向）
- ログローテーションは `json-file` ドライバーの `max-size`/`max-file` で個別設定が必要
- 証明書の自動更新管理機能なし（cert-manager相当がない）
- systemd統合が本番運用では必須

**本番運用でのベストプラクティス**:

systemd unitファイルでCompose起動を管理:

```ini
[Unit]
Description=eduroam RADIUS Stack
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/eduroam
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
```

- 各サービスに `restart: unless-stopped` を設定（Dockerが自動再起動を担当）
- ヘルスチェックを全サービスに定義（FreeRADIUS: `radtest`、Prometheus: `/-/healthy`、Grafana: `/api/health`）
- ログドライバー設定: `json-file` + `max-size: 10m` + `max-file: 5` でローテーション
- Secrets: SOPS + age で暗号化した `.env` をgit管理

#### セキュリティ
- Rootless mode: daemonとコンテナを非特権ユーザーで実行
- User namespaces: コンテナ内rootをホスト非特権ユーザーにマッピング
- Seccomp: システムコール制限（デフォルトで約44種を無効化）
- RADIUS 1812/1813は1024以上なのでrootlessでも問題なし

#### Podman + Quadlet との比較

Podman v5.8（2026年3月）はデーモンレス・デフォルトrootlessのコンテナランタイム。Quadletは `podman generate systemd` の後継で、宣言的なsystemd統合を提供する。

| 観点 | Docker Compose | Podman Quadlet |
|------|----------------|----------------|
| プロセスモデル | Docker daemon（単一障害点） | デーモンレス。各コンテナはsystemdの直接子プロセス |
| 起動統合 | systemd unitラッパーが必要 | ネイティブsystemd unit。`systemctl enable` で個別管理 |
| 自動更新 | 手動 `docker compose pull && up` | `podman auto-update`（ヘルスチェック失敗時ロールバック） |
| Rootless | サポートあり（やや未成熟） | ファーストクラスサポート |
| Compose互換 | ネイティブ | `podman compose` + `podlet` 変換ツール |
| エコシステム | 最大（FreeRADIUS公式イメージ対応） | 成長中（RHEL/CentOSデフォルト） |

**本プロジェクトでの位置づけ**: Quadletはsystemd統合が最もシンプルだが、エコシステムの大きさとドキュメントの充実度からDocker Composeが現時点では実用的。RHEL/Rocky Linux環境で構築する場合はPodman Quadletも有力な選択肢

---

### 12.3 k3s

#### バージョン情報

| バージョン | Kubernetes | リリース日 | 備考 |
|-----------|-----------|-----------|------|
| v1.35.2+k3s1 | v1.35.2 | 2026年2月 | 最新 |
| v1.34.5+k3s1 | v1.34.5 | 2026年3月 | LTS相当・安定版 |

同梱コンポーネント（v1.34.5）: Containerd 2.1.5 / Traefik 3.6.9 / CoreDNS 1.14.1 / Etcd 3.6.7

#### 軽量Kubernetesとしての特徴
- 単一バイナリ（約70MB）、インストール1コマンド
- シングルノード時はSQLite使用（etcd不要）。local-path-provisioner・metrics-server内蔵
- k8s比で約70%のリソース削減
- k8sと完全API互換

#### マルチサービス管理での強み

5〜10サービスを運用する場合、k3sはDocker Composeに対していくつかの明確な優位性がある。

**k3sが優れる点**:
- **宣言的管理**: `kubectl apply -f` でマニフェストを適用。desired stateとの差分を自動解消
- **Helmチャート**: Prometheus/Grafana/Lokiは公式Helmチャートで一括デプロイ可能（`kube-prometheus-stack`）
- **自動修復**: Podが異常終了すると自動で再作成。依存関係も考慮
- **ローリングアップデート**: Deployment単位でゼロダウンタイム更新
- **Ingress内蔵**: Traefik Ingress ControllerでHTTPSルーティングを統合管理
- **cert-manager**: Let's Encrypt等との自動証明書管理
- **Secret管理**: Kubernetes Secretsで一元管理（暗号化オプションあり）

**k3sの課題（本プロジェクト固有）**:
- **UDPプロトコル**: ServiceのUDP対応はあるが、LBのヘルスチェックがTCP/HTTPほど成熟していない
- **Pod IP変動**: eduroam FLRからの接続はソースIP固定が前提。`hostNetwork: true`が必要
- **学習コスト**: Docker Compose経験のみの場合、Kubernetes概念の習得に2-4週間
- **トラブルシューティング**: FreeRADIUS障害 + k8sレイヤー障害の切り分けが複雑

#### 監視スタックとの親和性

k3sの最大の強みは監視スタックとの統合にある。

```bash
# kube-prometheus-stack で Prometheus + Grafana + Alertmanager を一括デプロイ
helm install monitoring prometheus-community/kube-prometheus-stack

# Loki を追加
helm install loki grafana/loki-stack
```

- kube-prometheus-stackはクラスタ内の全サービスを自動で発見・監視
- ServiceMonitor CRDでカスタムメトリクスエンドポイントを宣言的に追加
- Grafanaダッシュボードもマニフェストとしてgit管理可能

#### HA構成
- 組み込みetcd方式（`--cluster-init`）: 3サーバノードで構成
- 外部DB方式: MySQL/PostgreSQL/etcdを外部に配置

---

### 12.4 Hyper-V

#### アーキテクチャ
- Type-1 ハイパーバイザー（ベアメタル直接動作）
- 親パーティション（管理OS）+ 子パーティション（VM）
- 3形態: Windows Server Hyper-V ロール / クライアントHyper-V / Hyper-V Server（2019で廃止）

#### エディション比較
- Standard: 2 Windows Server VM/ライセンス、S2D不可
- Datacenter: 無制限VM、S2D対応、SDN対応
- クライアント（Win 10/11 Pro/Edu）: ライブマイグレーション等なし

#### 教育機関向けライセンス

- **Microsoft EES（Enrollment for Education Solutions）**: 教育機関向け包括契約（1,000+ FTE向け）。**Windows Server OSライセンスは基本契約に含まれない**（追加製品として別途購入）。Core CAL Suite（Serverアクセス権）は含まれる
- **OVS-ES（Open Value Subscription - Education Solutions）**: 1,000未満の機関向け。同様にサーバOSライセンスは別途
- **Azure Dev Tools for Teaching**: Windows Server 2019/2022/2025のライセンスを含むが、**2025年8月15日以降、新規管理者登録を停止**。既存登録済み機関のみ利用可能。今後はAzure for Students（$100クレジット）に置き換えられ、オンプレミスライセンスは提供されない
- **コスト目安**:
  - Windows Server 2025 Standard（16コア）: 約$599-$699 USD（アカデミック価格で40-60%割引の可能性あり → 約45,000-60,000円）
  - CAL（ユーザー単位）: 約$44 USD/ユーザー
  - ※WS2022比で10-20%値上げ。Datacenter版は約$6,155-$6,771 USD
- **Hotpatching（新機能）**: Azure Arc接続で再起動なし更新が可能だが、**$1.50 USD/コア/月**の追加サブスクリプションが必要（例: 32コアサーバ = 年間$576）

#### Linux VM対応
- Ubuntu/RHEL/Debian/SUSE等をGeneration 2 VMで完全サポート
- Secure Boot、Dynamic Memory、SR-IOV対応
- Integration Services はカーネル組み込み済み（追加インストール不要）

#### マルチサービス運用時の課題

- **メモリ効率**: VM毎にカーネルとOS分のメモリが必要。LXCと比べて同一サービスで3-5倍のメモリ消費
- **管理効率**: VM個別の管理が必要。Docker ComposeやHelmのような一括管理ツールがない
- **監視統合**: Windows Admin Centerは基本的なメトリクスのみ。Prometheus連携には各VM内に個別設定が必要
- **Linux中心のワークロード**: FreeRADIUS・Prometheus・Grafana・Loki等は全てLinuxサービス。Hyper-V上でLinux VMを多数動かす構成はオーバーヘッドが大きい

#### Windows Server 2025の新機能

| スペック | WS2022 | WS2025 |
|---------|--------|--------|
| 最大vCPU/VM（Gen2） | 240 | **2,048**（約8.5倍） |
| 最大メモリ/VM | 24 TB | **240 TB**（10倍） |
| 最大仮想SCSIディスク/VM | 64 | **256** |
| ストレージIOPS | - | WS2022比**60%向上** |

- **GPU-P（GPUパーティショニング）**: ライブマイグレーション・HA対応。Standard版でも利用可
- **ライブマイグレーション圧縮**: 転送データを圧縮し約2倍高速化
- **AccelNet**: 簡素化されたSR-IOV管理でVM間レイテンシ低減
- **ワークグループクラスタ**: Active Directoryなしでフェイルオーバークラスタを構成可能
- **Windows Admin Center 2511**: vMode（Virtualization Mode）で最大1,000ホスト/25,000 VM管理。ただしLinux VM内のゲスト管理（SSH等）は非対応

#### HA構成
- フェイルオーバークラスタリング: 最大64ノード、8,000 VM
- ライブマイグレーション（Shared Nothing含む）
- Hyper-Vレプリカ: RPO最短30秒の非同期レプリケーション

---

## 13. 推奨アーキテクチャ案

### 案A: Docker Compose on Linux（最小構成）

```
[Linux サーバ（8GB RAM / 4コア）]
  └─ Docker Engine + Docker Compose
       ├─ FreeRADIUS コンテナ（host network）
       ├─ Prometheus コンテナ
       ├─ Grafana コンテナ
       ├─ Loki コンテナ
       ├─ Alertmanager コンテナ
       └─ Nginx コンテナ（リバースプロキシ）
```

- **メリット**: 現在の検証環境からの移行が最もスムーズ。1ファイル（docker-compose.yml）で全サービス管理。学習コスト最小
- **デメリット**: サービス間の分離がnamespaceレベルのみ。スナップショット/バックアップがDocker volume単位で煩雑。OS障害で全サービス停止
- **適合**: 小規模（学生数千名以下）、初期コスト最小化が最優先の場合

### 案B: Proxmox VE + LXC（推奨）

```
[Proxmox VE サーバ（16GB RAM / 8コア / 256GB SSD）]
  ├─ LXC: FreeRADIUS
  │    └─ VLAN-aware bridge（RADIUS VLAN）
  ├─ LXC: Prometheus + Alertmanager
  │    └─ 内部ブリッジ（監視VLAN）
  ├─ LXC: Grafana + Nginx
  │    └─ 内部ブリッジ + 管理VLAN
  ├─ LXC: Loki（ログ集約）
  │    └─ 内部ブリッジ
  └─ （予備: 将来のNMS、追加サービス用）
```

- **メリット**: LXC分離によりサービス単位のスナップショット・バックアップが可能。WebUIで全LXCを統合管理。vzdumpで定期バックアップ。VLAN分離でネットワークセキュリティ確保。将来のサービス追加も容易
- **デメリット**: 専用物理サーバが必要。Proxmox VEの学習が必要
- **適合**: **中規模以上、堅牢な運用基盤が必要な場合（本プロジェクトの推奨構成）**

### 案C: Proxmox VE HAクラスタ（大規模・高可用性）

```
[Proxmox VE 3ノードクラスタ + Ceph]
  ├─ LXC: FreeRADIUS Primary（自動フェイルオーバー）
  ├─ LXC: FreeRADIUS Secondary
  ├─ LXC: Prometheus HA（Thanos/Mimir）
  ├─ LXC: Grafana + Loki
  └─ LXC: 管理・バックアップ
```

- **メリット**: 自動フェイルオーバー、ライブマイグレーション。eduroam 24/365要件に完全対応
- **デメリット**: 3台の物理サーバ必要、運用複雑、コスト増
- **適合**: 大規模、高可用性が必須の場合

### 案D: k3s on Linux（クラウドネイティブ志向）

```
[Linux サーバ（16GB RAM / 8コア）]
  └─ k3s（シングルノード）
       ├─ Namespace: radius
       │    └─ FreeRADIUS Pod（hostNetwork: true）
       ├─ Namespace: monitoring
       │    ├─ Prometheus Pod（kube-prometheus-stack）
       │    ├─ Grafana Pod
       │    ├─ Alertmanager Pod
       │    └─ Loki Pod
       └─ Ingress: Traefik（HTTPS）
```

- **メリット**: Helmチャートで監視スタック一括デプロイ。自動修復・ローリングアップデート。GitOpsによる構成管理。cert-managerで証明書自動管理。将来のマルチノード拡張が容易
- **デメリット**: Kubernetes学習コストが高い。RADIUS/UDP運用にhostNetwork必要。障害切り分けが複雑
- **適合**: 運用チームにKubernetes経験者がいる場合、またはクラウドネイティブ基盤への移行を見据える場合

### 案E: Hyper-V（Windows Server既存環境）

```
[Windows Server 2025 + Hyper-V]
  ├─ Linux VM: FreeRADIUS + 監視エージェント
  ├─ Linux VM: Prometheus + Grafana + Loki
  └─ （フェイルオーバークラスタで冗長化可能）
```

- **メリット**: 既存Windows Server環境があれば追加コスト最小。教育機関向けライセンスの可能性
- **デメリット**: Linux VMの多数運用はメモリ効率が悪い（VM毎に2-4GB必要）。Windows Serverライセンスコスト（新規の場合）。Linux中心のワークロードにはオーバーヘッド大
- **適合**: 学校がWindows Server環境を既に運用しており、追加サーバ購入が困難な場合

### 案の比較サマリ

| 観点 | A: Docker | B: Proxmox LXC | C: Proxmox HA | D: k3s | E: Hyper-V |
|------|:---------:|:--------------:|:-------------:|:------:|:----------:|
| 初期コスト | ◎ | ○ | △ | ○ | △ |
| 運用コスト（年間） | ◎ | ◎ | △ | ◎ | △ |
| サービス分離 | △ | ○ | ○ | ○ | ◎ |
| バックアップ容易性 | △ | ◎ | ◎ | ○ | ○ |
| 監視統合 | ○ | ◎ | ◎ | ◎ | △ |
| スケーラビリティ | △ | ○ | ◎ | ◎ | ○ |
| 学習コスト | ◎ | ○ | △ | △ | ○ |
| 将来のサービス追加 | ○ | ◎ | ◎ | ◎ | ○ |

---

## 14. 結論

### 現在のフェーズ（Phase 1-3: 検証）

**Docker Compose を継続**が最適。変更不要。
監視基盤はこの段階では構築不要（FreeRADIUSのデバッグログで十分）。

### 本番移行時の推奨

**案B: Proxmox VE + LXC**を第一推奨とする。

**選定理由**:
1. **LXCのメモリ効率**: FreeRADIUS + 監視スタック（5-7サービス）を16GB RAMで余裕をもって運用可能。Hyper-V VMでは同等構成に24GB以上が必要
2. **サービス単位の管理**: LXCごとにスナップショット・バックアップ・リソース制限が可能。Docker Composeでは困難
3. **WebUI統合管理**: 全LXCの状態を1画面で把握。vzdumpによる定期バックアップもGUIから設定
4. **ネットワーク柔軟性**: VLAN-aware bridgeでRADIUS通信と監視通信を分離。SDN Fabricsで将来の拡張にも対応
5. **将来のHA拡張**: シングルノードで開始し、必要に応じて3ノードクラスタへ拡張可能
6. **コスト**: 全機能無償。教育機関にとって重要
7. **OCI対応（v9.1）**: Docker Hubから直接イメージを取得してLXCとしてデプロイ可能。Docker資産の活用

**条件別の代替案**:
- 学校に**Windows Serverライセンスと既存環境**がある → **案E: Hyper-V**
- 運用チームに**Kubernetes経験者**がいる → **案D: k3s**
- **予算・リソースが極めて限定的** → **案A: Docker Compose on Linux**

### k3sを再検討すべきタイミング

- 監視サービスに加えて**NMS・ユーザーポータル・DHCP等**もコンテナ化して10+サービスを統合管理する場合
- 運用チームにKubernetes経験者が加わった場合
- クラウドネイティブ基盤への移行を組織として決定した場合
- **GitOpsによる構成管理**を導入したい場合

---

## 15. 調査情報源

### Proxmox VE
- [Proxmox VE 9.1 プレスリリース](https://www.proxmox.com/en/about/company-details/press-releases/proxmox-virtual-environment-9-1)
- [Proxmox VE 9.0 プレスリリース](https://www.proxmox.com/en/about/company-details/press-releases/proxmox-virtual-environment-9-0)
- [Proxmox VE SDN ドキュメント](https://pve.proxmox.com/pve-docs/chapter-pvesdn.html)
- [Proxmox VE LXC vs VM パフォーマンス比較](https://ikus-soft.com/en_CA/blog/techies-10/proxmox-ve-performance-of-kvm-vs-lxc-75)
- [Proxmox + Prometheus/Grafana 監視](https://community.hetzner.com/tutorials/proxmox-prometheus-metrics/)
- [Proxmox VE ハードウェア要件](https://www.proxmox.com/en/products/proxmox-virtual-environment/requirements)

### Docker / Podman
- [Docker Engine v29 リリースノート](https://docs.docker.com/engine/release-notes/29/)
- [Docker Compose v5 リリースノート](https://docs.docker.com/compose/releases/release-notes/)
- [Docker Compose Secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Docker Compose for Production Workloads](https://www.freecodecamp.org/news/how-to-use-docker-compose-for-production-workloads/)
- [Podman Quadlet systemd統合](https://www.redhat.com/en/blog/quadlet-podman)
- [Podlet: Compose → Quadlet変換ツール](https://github.com/containers/podlet)

### k3s / Kubernetes
- [k3s ドキュメント](https://docs.k3s.io/)
- [k3s v1.34.X リリースノート](https://docs.k3s.io/release-notes/v1.34.X)
- [kube-prometheus-stack Helm chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Docker Compose vs Kubernetes in Production](https://dev.to/synsun/docker-compose-vs-kubernetes-what-i-actually-learned-running-both-in-production-18me)

### Hyper-V / Windows Server
- [Windows Server 2025 新機能](https://learn.microsoft.com/en-us/windows-server/get-started/whats-new-windows-server-2025)
- [Windows Server 2025 Hyper-V アップデート](https://www.techtarget.com/searchwindowsserver/tip/Windows-Server-2025-Hyper-V-updates-promise-speed-boost)
- [Windows Server 2025 ライセンス・価格](https://www.microsoft.com/en-us/windows-server/pricing)
- [Windows Admin Center 2511（vMode）](https://learn.microsoft.com/en-us/windows-server/manage/windows-admin-center/virtualization-mode-overview)
- [Azure Dev Tools for Teaching 停止案内](https://learn.microsoft.com/en-us/azure/education-hub/azure-dev-tools-teaching/program-faq)
- [Hyper-V Linux VMサポート](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-linux-and-freebsd-virtual-machines-for-hyper-v-on-windows)

### 監視基盤
- [Prometheus 3.10 リリース](https://github.com/prometheus/prometheus/releases)
- [Prometheus ストレージドキュメント](https://prometheus.io/docs/prometheus/latest/storage/)
- [Grafana 12.4 新機能](https://grafana.com/docs/grafana/latest/whatsnew/whats-new-in-v12-0/)
- [Grafana Loki サイジングガイド](https://grafana.com/docs/loki/latest/setup/size/)
- [Grafana Alloy（Promtail後継）移行ガイド](https://grafana.com/docs/alloy/latest/set-up/migrate/from-promtail/)
- [bvantagelimited/freeradius_exporter](https://github.com/bvantagelimited/freeradius_exporter)
- [devon-mar/radius-exporter](https://github.com/devon-mar/radius-exporter)
- [FreeRADIUS Grafanaダッシュボード（ID: 19891）](https://grafana.com/grafana/dashboards/19891-freeradius/)
- [FreeRADIUS Statistics Documentation](https://www.freeradius.org/documentation/freeradius-server/3.2.9/howto/monitoring/statistics.html)
- [Loki vs Elasticsearch 比較](https://signoz.io/blog/loki-vs-elasticsearch/)
