#!/bin/bash
# eduroam検証環境 初期セットアップスクリプト

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="${PROJECT_DIR}/docker"

echo "=== eduroam検証環境セットアップ ==="

# 1. .envファイル作成（docker-compose用の予備）
if [ ! -f "${DOCKER_DIR}/.env" ]; then
    echo "--- .env ファイルを作成 ---"
    cp "${DOCKER_DIR}/.env.example" "${DOCKER_DIR}/.env"
    echo ".env ファイルを作成しました: ${DOCKER_DIR}/.env"
    echo "⚠ パスワード・シークレットを編集してください: ${DOCKER_DIR}/.env"
else
    echo ".env ファイルは既に存在します。"
fi

# 2. 証明書生成
if [ ! -f "${DOCKER_DIR}/freeradius/raddb/certs/server.crt" ]; then
    echo "--- 検証用証明書を生成 ---"
    bash "${PROJECT_DIR}/scripts/generate-certs.sh"
else
    echo "証明書は既に存在します。"
fi

# 3. Dockerイメージビルド
echo "--- Dockerイメージをビルド ---"
cd "${DOCKER_DIR}"
docker compose build

echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "  cd ${DOCKER_DIR}"
echo "  docker compose up -d       # 環境起動"
echo "  docker compose logs -f     # ログ確認"
echo ""
echo "テスト:"
echo "  make test-radtest          # radtestで基本認証テスト"
echo "  make test-eapol            # eapol_testでEAP-TTLS/PAPテスト"
