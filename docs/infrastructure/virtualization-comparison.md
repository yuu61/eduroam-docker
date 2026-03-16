# 仮想化技術比較レポート

eduroam導入プロジェクト（FreeRADIUS + Google Workspace Secure LDAP）における仮想化基盤の選定資料。

調査日: 2026-03-16

---

## 1. 技術概要サマリ

| 項目 | Proxmox VE | Docker | k8s / k3s | Hyper-V |
|------|-----------|--------|-----------|---------|
| **分類** | ハイパーバイザー + コンテナ基盤 | アプリケーションコンテナ | コンテナオーケストレーション | ハイパーバイザー |
| **仮想化方式** | KVM（完全仮想化）+ LXC（システムコンテナ） | OCI コンテナ（namespaces/cgroups） | OCI コンテナ + オーケストレーション | Type-1 ハイパーバイザー（完全仮想化） |
| **最新バージョン** | 9.1（2025年11月） | Engine 29.3 / Compose v5 | k8s v1.35 / k3s v1.34.5 | Windows Server 2025 |
| **ライセンス** | AGPL v3（無償で全機能利用可） | Engine: Apache 2.0（無償）/ Desktop: 商用 | Apache 2.0（無償） | Windows Server ライセンス必要 |
| **管理UI** | WebUI（ポート8006） | CLI / Docker Desktop GUI | kubectl CLI / Dashboard / Lens | Hyper-Vマネージャー / WAC |
| **対象** | サーバ仮想化基盤 | アプリケーション開発・デプロイ | コンテナのスケーリング・管理 | Windows中心のサーバ仮想化 |

---

## 2. システム要件比較

### 最小要件

| 項目 | Proxmox VE | Docker Engine | k3s | k8s | Hyper-V |
|------|-----------|---------------|-----|-----|---------|
| **CPU** | Intel VT / AMD-V 対応 | 64bit | 1コア | 2コア | SLAT対応 64bit |
| **メモリ** | 2GB + ゲスト分 | 512MB | 512MB（1GB推奨） | 2GB（4GB推奨） | 4GB + ゲスト分 |
| **ディスク** | 特に制限なし | 数GB | 1GB（10GB推奨） | 50GB推奨 | VHDXサイズ依存 |
| **インストール先** | ベアメタル専用 | Linux OS上 | Linux OS上 | Linux OS上 | ベアメタル / Windows上 |

### 本プロジェクトでの目安（FreeRADIUS 1台）

- **Proxmox VE / Hyper-V**: ホストに4GB以上 + ゲストVM用2GB = 計6GB以上推奨
- **Docker**: ホストOS上で512MB程度の追加消費
- **k3s**: ホストOS上で1GB程度の追加消費

---

## 3. コスト比較

| 項目 | Proxmox VE | Docker | k8s / k3s | Hyper-V |
|------|-----------|--------|-----------|---------|
| **ソフトウェア費用** | 無料（全機能） | Engine: 無料 / Desktop: 条件付き無料 | 無料 | Windows Serverライセンス必要 |
| **有償オプション** | サブスクリプション €115〜€1,060/ソケット/年 | Desktop Pro $9/月〜 | マネージドサービス $72/月〜 | Standard/Datacenter CAL |
| **教育機関向け** | 公式割引なし（無償で十分） | Personal無料（学生） | 無料 | EES/Azure Dev Tools for Teaching |
| **追加HW** | 専用物理サーバ必要 | 既存サーバで動作 | 既存サーバで動作 | 専用物理サーバ or Windows PC |

### コスト試算（本プロジェクト）

| 構成 | 初期コスト | 年間コスト |
|------|----------|----------|
| **Docker（現状）** on WSL2 | 0円 | 0円 |
| **Docker** on Linux サーバ | サーバ購入費のみ | 0円 |
| **k3s** on Linux サーバ | サーバ購入費のみ | 0円 |
| **Proxmox VE** on 専用サーバ | サーバ購入費のみ | 0円（Community版） |
| **Hyper-V** on Windows Server | サーバ購入費 + WS ライセンス | CAL費用 |

---

## 4. ネットワーク機能比較

| 機能 | Proxmox VE | Docker | k8s / k3s | Hyper-V |
|------|-----------|--------|-----------|---------|
| **VLAN** | VLAN-aware bridge | macvlan / ipvlan | CNI依存 | 仮想スイッチでVLAN設定 |
| **SDN** | 8.x以降で本格対応 | overlay（Swarm） | Calico / Cilium / Flannel | Datacenter版のみ |
| **ファイアウォール** | 3階層（DC/ノード/VM） | iptables自動管理 | NetworkPolicy | Windows Firewall |
| **L2接続** | Linux bridge | macvlan / bridge | macvlan CNI | External仮想スイッチ |
| **UDP対応** | ネイティブ | ポートマッピング / host mode | Service(UDP) ※制約あり | ネイティブ |

### RADIUS通信（UDP 1812/1813）への適性

- **Proxmox VE**: VMが物理NICに直結可能。最も自然
- **Docker**: `host` ネットワークモードまたはポートマッピングで対応
- **k8s/k3s**: UDP ServiceはLBのヘルスチェックが未成熟。NodePortまたはhostNetworkで回避
- **Hyper-V**: External仮想スイッチで物理ネットワークに直結

---

## 5. 高可用性（HA）比較

| 機能 | Proxmox VE | Docker | k8s / k3s | Hyper-V |
|------|-----------|--------|-----------|---------|
| **自動フェイルオーバー** | HA Manager（3ノード〜） | Swarm mode（非推奨傾向） | Pod自動再スケジュール | フェイルオーバークラスタ |
| **ライブマイグレーション** | 共有ストレージ上で対応 | なし | Pod再作成（Rolling Update） | 対応（Shared Nothing含む） |
| **最小HA構成** | 3ノード + Ceph | Docker Swarm 3ノード | k3s 3サーバノード | 2ノード + 共有ストレージ |
| **レプリケーション** | Ceph / ZFS | なし（外部ツール） | etcd Raft / PV CSI | Hyper-V レプリカ |
| **DR（災害復旧）** | PBS連携 | なし | Velero等 | Azure Site Recovery |

---

## 6. 管理・自動化比較

| 項目 | Proxmox VE | Docker | k8s / k3s | Hyper-V |
|------|-----------|--------|-----------|---------|
| **API** | REST API（全機能） | Docker API（REST） | Kubernetes API | WMI / PowerShell |
| **IaC** | Terraform（非公式）/ Ansible | Dockerfile / Compose | Helm / Kustomize / ArgoCD | PowerShell DSC |
| **構成管理** | Ansible対応 | Dockerfile / Compose | GitOps（ArgoCD/Flux） | SCVMM / Ansible（限定的） |
| **バックアップ** | PBS / vzdump | Volume export | Velero / Longhorn backup | Windows Server Backup |
| **監視** | 組み込みメトリクス | cAdvisor / Prometheus | Prometheus / Grafana 統合 | Windows Admin Center |

---

## 7. セキュリティ比較

| 項目 | Proxmox VE | Docker | k8s / k3s | Hyper-V |
|------|-----------|--------|-----------|---------|
| **分離レベル** | VM: 完全分離 / LXC: カーネル共有 | namespaces（カーネル共有） | namespaces（カーネル共有） | VM: 完全分離 |
| **root権限** | VM内で独立 | rootless mode対応 | Pod Security Standards | VM内で独立 |
| **ネットワーク制御** | ファイアウォール + VLAN | iptables / seccomp | NetworkPolicy | 仮想スイッチ + Windows FW |
| **証明書管理** | 手動（Ansible推奨） | bind mount / secret | Secret / cert-manager | 手動 |
| **Shielded VM** | - | - | - | TPM 2.0対応（Gen 2 VM） |

---

## 8. 学習コスト比較

| 項目 | Proxmox VE | Docker | k8s / k3s | Hyper-V |
|------|-----------|--------|-----------|---------|
| **基礎習得** | 1-2週間 | 1-2週間 | 2-4週間（k3s） / 4-8週間（k8s） | 1-2週間 |
| **実践運用** | 1-2ヶ月 | 1ヶ月 | 2-3ヶ月 | 1-2ヶ月 |
| **本番運用** | 3-6ヶ月 | 2-3ヶ月 | 6ヶ月-1年 | 3-6ヶ月 |
| **前提知識** | Linux管理 | Linux基礎 | Docker + ネットワーク + YAML | Windows Server管理 |
| **ドキュメント** | 充実（英語中心） | 非常に充実 | 非常に充実 | 非常に充実（日本語あり） |

---

## 9. eduroamプロジェクトでの適性評価

### 評価基準とスコア（5段階）

| 評価基準 | Proxmox VE | Docker | k8s / k3s | Hyper-V |
|----------|:---------:|:------:|:---------:|:-------:|
| **コスト** | 5 | 5 | 5 | 2 |
| **検証環境での使いやすさ** | 3 | 5 | 2 | 3 |
| **本番運用への適性** | 5 | 3 | 4 | 5 |
| **HA構成** | 5 | 2 | 5 | 4 |
| **学習コスト（低い=高スコア）** | 3 | 5 | 1 | 3 |
| **RADIUS/UDP適性** | 5 | 4 | 3 | 5 |
| **既存Docker資産の活用** | 4 | 5 | 4 | 3 |
| **ネットワーク柔軟性** | 5 | 3 | 4 | 4 |
| **バックアップ・復旧** | 5 | 2 | 3 | 4 |
| **合計** | **40** | **34** | **31** | **33** |

### フェーズ別推奨

| フェーズ | 推奨技術 | 理由 |
|----------|---------|------|
| **Phase 1-3（検証）** | **Docker Compose（現状維持）** | 最も軽量・高速。設定変更→テストのサイクルが最短 |
| **Phase 4-5（接続・実機テスト）** | **Docker on Linux サーバ** or **Proxmox VE上のVM/LXC** | WSL2のネットワーク制約を回避。実APからのUDP通信を受けるにはネイティブ環境が必要 |
| **本番運用（単体）** | **Proxmox VE**（LXC/VM）or **Hyper-V**（既存WS環境あれば） | 完全な分離、スナップショット、バックアップ |
| **本番運用（HA）** | **Proxmox VE 3ノードクラスタ** or **Hyper-V フェイルオーバークラスタ** | 自動フェイルオーバー、ライブマイグレーション |

---

## 10. 各技術の詳細

### 10.1 Proxmox VE

#### アーキテクチャ
- KVM（完全仮想化）+ LXC（システムコンテナ）を単一WebUIから統合管理
- Corosyncベースのクラスタリング、pmxcfsによる設定同期
- Cephネイティブ統合によるハイパーコンバージドインフラ（HCI）

#### ストレージ
- ローカル: LVM、ZFS、ディレクトリ
- 共有: NFS、iSCSI、GlusterFS、Ceph
- ZFS: 圧縮・重複排除・スナップショット対応
- Ceph RBD: ブロックレベル分散ストレージ

#### バックアップ
- vzdump: VM/LXCの完全バックアップ（スケジュール対応）
- Proxmox Backup Server（PBS）: 増分バックアップ、重複排除、暗号化、粒度の細かいリストア
- Live-restore: リストア中にVM起動可能

#### API・自動化
- REST API（全機能対応、APIトークン認証）
- Terraform: Telmate/proxmox プロバイダ（非公式）
- Ansible: community.general.proxmox / proxmox_kvm モジュール

#### WSL2との関係
- WSL2上では動作不可（ベアメタルインストール専用）
- 開発はWSL2/Docker → 本番デプロイ先としてProxmox VEという構成が自然

#### 最新情報（v9.1）
- Debian 13 "Trixie"ベース、Linux kernel 6.17
- OCIイメージからLXCコンテナ作成が可能に（Docker Hub連携）
- ネスト仮想化改善、Intel TDX対応

---

### 10.2 Docker

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

#### Docker Compose v5
- Profiles: 1ファイルで開発/テスト/本番を切替
- Watch: ファイル変更監視→自動アクション
- Compose Bridge: K8sマニフェスト/Helmチャートへの変換
- Go SDK: アプリケーション統合

#### セキュリティ
- Rootless mode: daemonとコンテナを非特権ユーザーで実行
- User namespaces: コンテナ内rootをホスト非特権ユーザーにマッピング
- Seccomp: システムコール制限（デフォルトで約44種を無効化）
- RADIUS 1812/1813は1024以上なのでrootlessでも問題なし

#### パフォーマンス（VM比較）
- CPUオーバーヘッド: ネイティブ比5%未満（VM: 最大30%低下）
- 起動時間: 平均1.1秒（VM: 平均29.3秒）
- 集約密度: 89コンテナ/サーバ（VM: 12台/サーバ）

#### Podmanとの比較
- Podman: daemonless、デフォルトrootless、20-50%高速起動
- Docker: エコシステム最大、FreeRADIUS公式イメージ対応、eduroamコミュニティイメージもDocker前提

---

### 10.3 Kubernetes / k3s

#### k8sアーキテクチャ
- コントロールプレーン: kube-apiserver、etcd、kube-scheduler、kube-controller-manager
- ワーカーノード: kubelet、kube-proxy、containerd
- 主要リソース: Pod、Service、Ingress、Deployment、ConfigMap、Secret

#### k3sの軽量化
- 単一バイナリ（約70MB）、インストール1コマンド
- etcd → SQLite（組み込み）、Traefik/Flannel/ServiceLB組み込み
- k8s比で約70%のリソース削減
- k8sと完全API互換

#### HA構成
- k8s: 3台以上のマスター + etcdクラスタ + LB
- k3s: 組み込みetcd方式（`--cluster-init`）または外部DB方式

#### FreeRADIUS運用の課題
- **UDPプロトコル**: ServiceのUDP対応はあるが、LBのヘルスチェックがTCPほど成熟していない
- **Pod IP変動**: eduroam FLRからの接続はソースIP固定が前提。hostNetwork使用が必要
- **オーバースペック**: RADIUS 1-2台にk8sクラスタは過剰
- **運用複雑性**: FreeRADIUS障害 + k8sレイヤー障害の切り分けが困難

#### 最新情報
- k8s v1.35: In-place Pod Vertical Scaling（GA）、cgroup v1サポート除去、IPVSモード非推奨
- k3s v1.34.5: containerd 2.0対応、secretboxプロバイダ、UDP対応rootlessポート

---

### 10.4 Hyper-V

#### アーキテクチャ
- Type-1 ハイパーバイザー（ベアメタル直接動作）
- 親パーティション（管理OS）+ 子パーティション（VM）
- 3形態: Windows Server Hyper-V ロール / クライアントHyper-V / Hyper-V Server（2019で廃止）

#### エディション比較
- Standard: 2 Windows Server VM/ライセンス、S2D不可
- Datacenter: 無制限VM、S2D対応、SDN対応
- クライアント（Win 10/11 Pro/Edu）: ライブマイグレーション等なし

#### Linux VM対応
- Ubuntu/RHEL/Debian/SUSE等をGeneration 2 VMで完全サポート
- Secure Boot、Dynamic Memory、SR-IOV対応
- Integration Services はカーネル組み込み済み（追加インストール不要）

#### WSL2との関係
- WSL2はHyper-Vアーキテクチャのサブセット（Virtual Machine Platform）を使用
- WSL2とHyper-V VMは同時動作可能
- 全Desktop SKU（Home含む）でWSL2利用可能

#### HA構成
- フェイルオーバークラスタリング: 最大64ノード、8,000 VM
- ライブマイグレーション（Shared Nothing含む）
- Hyper-Vレプリカ: RPO最短30秒の非同期レプリケーション

#### Windows Server 2025の新機能
- Gen 2 VMで最大2,048 vCPU（WS2022: 1,024）
- GPUパーティショニング（Standard版でも利用可）
- Azure Arc統合によるハイブリッドクラウド管理
- Hotpatching（Azure Arc経由で再起動なし更新）

---

## 11. 推奨アーキテクチャ案

### 案A: Docker継続（最小構成）

```
[Linux サーバ]
  └─ Docker Engine + Docker Compose
       ├─ FreeRADIUS コンテナ（host network）
       └─ （監視: Prometheus + Grafana コンテナ）
```

- メリット: 現在の構成をほぼそのまま本番移行。学習コスト最小
- デメリット: HA構成が難しい。VM分離なし
- 適合: 小規模（学生数千名以下）、冗長化不要の場合

### 案B: Proxmox VE + Docker（推奨）

```
[Proxmox VE サーバ]
  ├─ VM/LXC: FreeRADIUS（Docker Compose or ネイティブ）
  ├─ VM/LXC: 監視（Prometheus + Grafana）
  └─ VM/LXC: その他サービス
```

- メリット: VM分離、スナップショット、バックアップ、将来のHA拡張性
- デメリット: 専用物理サーバが必要
- 適合: 中規模以上、堅牢な運用基盤が必要な場合

### 案C: Proxmox VE HAクラスタ（大規模・高可用性）

```
[Proxmox VE 3ノードクラスタ + Ceph]
  ├─ VM: FreeRADIUS Primary（自動フェイルオーバー）
  ├─ VM: FreeRADIUS Secondary
  └─ VM: 監視・管理
```

- メリット: 自動フェイルオーバー、ライブマイグレーション、eduroam 24/365要件対応
- デメリット: 3台の物理サーバ必要、運用複雑
- 適合: 大規模、高可用性が必須の場合

### 案D: Hyper-V（Windows Server既存環境）

```
[Windows Server 2025 + Hyper-V]
  ├─ Linux VM: FreeRADIUS
  └─ （フェイルオーバークラスタで冗長化可能）
```

- メリット: 既存Windows Server環境があれば追加コスト最小。教育機関向けライセンス
- デメリット: Windows Serverライセンスコスト（新規の場合）
- 適合: 学校がWindows Server環境を既に運用している場合

---

## 12. 結論

### 現在のフェーズ（Phase 1-3: 検証）

**Docker Compose を継続**が最適。変更不要。

### 本番移行時の推奨

**案B: Proxmox VE + Docker（または案D: Hyper-V）**を推奨。

選定基準:
- 学校に**Windows Serverライセンスと既存環境**がある → **Hyper-V**
- **新規にサーバを調達**する → **Proxmox VE**（無償で全機能利用可能）
- **k8s/k3sは現時点では不推奨**（RADIUSサーバ1-2台の運用にはオーバースペック）

### k8s/k3sを再検討すべきタイミング

- RADIUSサーバの冗長化 + 他のネットワークサービスもコンテナ化して統合管理する場合
- 運用チームにKubernetes経験者が加わった場合
- クラウドネイティブ基盤への移行を組織として決定した場合
