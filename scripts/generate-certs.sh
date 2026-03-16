#!/bin/bash
# eduroam検証用 自己署名証明書生成スクリプト
# 本番環境ではCA発行の証明書を使用すること

set -euo pipefail

CERT_DIR="$(cd "$(dirname "$0")/../docker/freeradius/raddb/certs" && pwd)"
DAYS=365
KEY_SIZE=2048
REALM="kobedenshi.ac.jp"

echo "=== eduroam検証用証明書を生成します ==="
echo "出力先: ${CERT_DIR}"

mkdir -p "${CERT_DIR}"

# CA証明書
if [ ! -f "${CERT_DIR}/ca.key" ]; then
    echo "--- CA鍵を生成 ---"
    openssl genrsa -out "${CERT_DIR}/ca.key" ${KEY_SIZE}

    echo "--- CA証明書を生成 ---"
    openssl req -new -x509 -days ${DAYS} \
        -key "${CERT_DIR}/ca.key" \
        -out "${CERT_DIR}/ca.crt" \
        -subj "/C=JP/ST=Hyogo/L=Kobe/O=Kobe Denshi/OU=IT/CN=eduroam-ca.${REALM}"
else
    echo "CA証明書は既に存在します。スキップします。"
fi

# サーバー証明書
if [ ! -f "${CERT_DIR}/server.key" ]; then
    echo "--- サーバー鍵を生成 ---"
    openssl genrsa -out "${CERT_DIR}/server.key" ${KEY_SIZE}

    echo "--- サーバーCSRを生成 ---"
    openssl req -new \
        -key "${CERT_DIR}/server.key" \
        -out "${CERT_DIR}/server.csr" \
        -subj "/C=JP/ST=Hyogo/L=Kobe/O=Kobe Denshi/OU=IT/CN=radius.${REALM}"

    echo "--- サーバー証明書を署名 ---"
    openssl x509 -req -days ${DAYS} \
        -in "${CERT_DIR}/server.csr" \
        -CA "${CERT_DIR}/ca.crt" \
        -CAkey "${CERT_DIR}/ca.key" \
        -CAcreateserial \
        -out "${CERT_DIR}/server.crt"
else
    echo "サーバー証明書は既に存在します。スキップします。"
fi

# DHパラメータ
if [ ! -f "${CERT_DIR}/dh" ]; then
    echo "--- DHパラメータを生成（数分かかる場合があります）---"
    openssl dhparam -out "${CERT_DIR}/dh" ${KEY_SIZE}
else
    echo "DHパラメータは既に存在します。スキップします。"
fi

echo ""
echo "=== 証明書の生成が完了しました ==="
echo "CA証明書:       ${CERT_DIR}/ca.crt"
echo "サーバー証明書: ${CERT_DIR}/server.crt"
echo "サーバー鍵:     ${CERT_DIR}/server.key"
echo "DHパラメータ:   ${CERT_DIR}/dh"
echo ""
echo "注意: これらは検証用の自己署名証明書です。"
echo "本番環境ではNII等のCAが発行した証明書を使用してください。"
