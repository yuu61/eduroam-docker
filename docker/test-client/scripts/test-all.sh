#!/bin/bash
# eduroam認証テスト一括実行スクリプト

set -euo pipefail

RADIUS_SERVER="${RADIUS_SERVER:-freeradius}"
RADIUS_SECRET="${RADIUS_SECRET:?RADIUS_SECRET environment variable is required}"
TEST_USER="${TEST_USER:-testuser1@kobedenshi.ac.jp}"
TEST_PASSWORD="${TEST_PASSWORD:?TEST_PASSWORD environment variable is required}"

echo "========================================"
echo " eduroam 認証テスト"
echo "========================================"
echo ""

# テスト1: radtest（PAP直接テスト）
echo "--- テスト1: radtest (PAP) ---"
echo "ユーザー: ${TEST_USER}"
if radtest "${TEST_USER}" "${TEST_PASSWORD}" "${RADIUS_SERVER}" 0 "${RADIUS_SECRET}"; then
    echo "結果: PASS"
else
    echo "結果: FAIL"
fi
echo ""

# テスト2: 不正パスワード（拒否確認）
echo "--- テスト2: 不正パスワードの拒否確認 ---"
echo "ユーザー: ${TEST_USER} (不正パスワード)"
if radtest "${TEST_USER}" wrongpassword "${RADIUS_SERVER}" 0 "${RADIUS_SECRET}" 2>&1 | grep -q "Access-Reject"; then
    echo "結果: PASS (正しく拒否された)"
else
    echo "結果: FAIL (拒否されなかった)"
fi
echo ""

# テスト3: eapol_test（EAP-TTLS/PAP）
echo "--- テスト3: eapol_test (EAP-TTLS/PAP) ---"
if command -v eapol_test &> /dev/null; then
    echo "ユーザー: ${TEST_USER}"
    if eapol_test -c /scripts/eapol_test.conf -s "${RADIUS_SECRET}" -a "${RADIUS_SERVER}" 2>&1 | grep -q "SUCCESS"; then
        echo "結果: PASS"
    else
        echo "結果: FAIL"
    fi
else
    echo "eapol_test が見つかりません。スキップします。"
fi
echo ""

echo "========================================"
echo " テスト完了"
echo "========================================"
