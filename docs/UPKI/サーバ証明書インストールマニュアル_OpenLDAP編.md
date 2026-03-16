# サーバ証明書インストールマニュアル OpenLDAP編

> 出典: https://nii-auth.atlassian.net/wiki/spaces/UPKIManual/pages/43878202

## 改版履歴

| 版数 | 日付 | 内容 | 担当 |
|------|------|------|------|
| V.1.0 | 2018/2/26 | 初版 | NII |
| V.1.1 | 2018/3/26 | CT対応版の中間CA証明書について説明を追加 | NII |
| V.1.2 | 2018/7/9 | 誤記修正、DNのルールの修正 | NII |
| V.1.3 | 2018/8/21 | ECC非対応の記載を追加 | NII |
| V.2.5 | 2019/6/10 | DNのルール(Locality Name)の修正 | NII |
| V.2.6 | 2020/4/13 | DNのルール(State or Province Name、Locality Name)の修正 | NII |
| V.2.7 | 2020/7/15 | DNのルール、TSVファイル形式のSTおよびLの値の説明、リンクの変更 | NII |
| V.2.8 | 2020/8/25 | 中間CA証明書の記載内容を修正 | NII |
| V.2.9 | 2020/12/22 | 中間CA証明書を修正、サーバー証明書L、STを必須に修正、OUの利用条件を修正 | NII |
| V.2.10 | 2022/08/02 | CSR作成からOUを削除 | NII |
| V.2.11 | 2025/03/31 | 鍵ペア生成の手順を追加 | NII |
| V.2.12 | 2025/12/25 | RSA認証局 中間CA証明書のファイル名を変更、クロスルート証明書用の手順を追加 | NII |

## 1. OpenLDAP2.4 によるサーバ証明書の利用

### 1-1. 前提条件

OpenLDAP2.4（以下OpenLDAP）でサーバ証明書を使用する場合の前提条件について記載します。
（本マニュアルではRed Hat Enterprise Linux Server 7.2 (Maipo)、OpenSSL3.4.0でCSRを作成し、OpenLDAP2.4.44へインストールする方法での実行例を記載しております）

**前提条件:**

1. 鍵ペア及びCSRを生成する端末にOpenSSLがインストールされていること
2. 証明書をインストールする端末にOpenLDAP 2.4がインストールされていること（LDAP server及びLDAP clientを含む）
3. OpenLDAPの証明書参照先: `/etc/openldap/certs`
4. 発行されたサーバ証明書のファイル名: `server.crt`
5. CSR作成時は既存の鍵ペアは使わずに、必ず新たにCSR作成用に生成した鍵ペアを利用してください。更新時も同様です。鍵ペアの鍵長は2048bitにしてください

> **注意:** OpenLDAPではECC証明書はサポートされていません。
>
> **注意:** 証明書の更新を行う場合は、先に1-5をご確認ください。

### 1-2. 鍵ペアの生成とCSRの作成

#### 1-2-1. 鍵ペアの生成

```bash
$ cd /etc/httpd/conf/ssl.key/        # 作業ディレクトリへ移動
$ openssl genpkey -algorithm rsa -aes128 -pkeyopt rsa_keygen_bits:2048 -out servername.key
Enter pass phrase: <PassPhrase>       # 私有鍵パスフレーズ入力
Verifying - Enter pass phrase: <PassPhrase>  # 私有鍵パスフレーズ再入力
```

> **重要:** OpenLDAPではパスフレーズ付きの私有鍵を利用することが出来ないため、`<PassPhrase>`には何も入力せずEnterを押下してください。

> **重要:** この鍵ペア用私有鍵パスフレーズは、サーバの再起動時および証明書のインストール等に必要となる重要な情報です。鍵ペア利用期間中は忘れることがないよう、また、情報が他人に漏れることがないよう、安全な方法で管理してください。

鍵ペアファイルへのアクセス権は利用管理者自身とSSL/TLSサーバのプロセス等必要最小限になるよう設定してください。

#### 1-2-2. CSRの生成

**DNのルール:**

| 項目 | 指定内容の説明 | 必須 | 文字数および注意点 |
|------|------|------|------|
| Country(C) | 必ず「JP」と設定 | ○ | JP固定 |
| State or Province Name(ST) | 所在地の都道府県名（ローマ字表記） | ○ | 機関ごとに固定。「UPKI証明書 主体者DNにおける ST および L の値一覧」を参照 |
| Locality Name(L) | 所在地の市区町村名（ローマ字表記） | ○ | 機関ごとに固定。「UPKI証明書 主体者DNにおける ST および L の値一覧」を参照 |
| Organization Name(O) | サービス参加申請時の機関名英語表記 | ○ | 半角英数字64文字以内。記号は`'(),-./:=`と半角スペースのみ |
| Common Name(CN) | サーバのFQDN | ○ | 64文字以内。半角英数字、`.`、`-`のみ。先頭と末尾に`.`と`-`は使用不可 |
| Email | 使用しないでください | × | - |
| 鍵長 | RSA 2048bit | - | - |

**CSR作成コマンド:**

```bash
$ openssl req -new -key servername.key -sha256 -out servername.csr
Enter pass phrase for servername.key: <PassPhrase>  # 私有鍵パスフレーズ入力

Country Name (2 letter code) [AU]: JP
State or Province Name (full name) []: Tokyo
Locality Name (eg, city) []: Chiyoda-ku
Organization Name (eg, company) [Default Company Ltd]: National Institute of Informatics
Organizational Unit Name (eg, section) []: .
Common Name (eg, your name or your server's hostname) []: www.nii.ac.jp
Email Address []: .
Please enter the following 'extra' attributes
A challenge password []: .
An optional company name []: .
```

**CSR内容の確認:**

```bash
$ openssl req -noout -text -in servername.csr
```

確認事項:
- Subject: CSR生成時に入力したDNと一致していること
- Public Key: 鍵長が2048bitであること
- Signature Algorithm: CSR生成時に指定した署名アルゴリズムであること

### 1-3. 証明書の申請から取得まで

CSRを作成後、登録担当者へ送付する証明書発行申請TSVファイルを作成し申請します。発行申請TSVファイルの作成方法、申請方法等につきましては、「証明書自動発行支援システム操作手順書（利用管理者用）」をご確認ください。

証明書の発行が完了すると、本システムよりメールが送信されます。メール本文に記載された証明書取得URLにアクセスし、証明書の取得を実施してください。

### 1-4. 証明書のインストール

#### 1-4-1. 事前準備

サーバ証明書、中間CA証明書を取得してください。

**リポジトリ（証明書の発行日時が2025年12月17日0時以降の場合）:**

- URL: https://repo1.secomtrust.net/sppca/nii/odca4/index.html
- サーバ証明書G8 RSA認証局 中間CA証明書: `nii-odca4g8rsa-pem.cer`

**リポジトリ（証明書の発行日時が2025年12月16日23時59分以前の場合）:**

- URL: https://repo1.secomtrust.net/sppca/nii/odca4/index.html
- サーバ証明書 RSA認証局 中間CA証明書: `nii-odca4g7rsa.cer`

**クロスルート証明書（サーバ証明書G8 RSA認証局のみ）:**

- URL: https://repository.secomtrust.net/SC-Root2/
- SECOM TLS RSA Root CA 2024 クロスルート証明書: `tlsrsarootca2024cross-pem.cer`

#### 1-4-2. 中間CA証明書の配置

```bash
$ mv nii-odca4g8rsa-pem.cer /etc/openldap/certs/nii-odca4g8rsa-pem.cer
```

#### 1-4-3. サーバ証明書のインストール

```bash
# 私有鍵を配置
$ mv servername.key /etc/openldap/certs/servername.key

# サーバ証明書を配置
$ mv server.crt /etc/openldap/certs/server.crt
```

> **重要:** OpenLDAPではパスフレーズ付き秘密鍵ファイルを利用できません。適切にディレクトリ・ファイルのアクセス権限を設定し、十分なセキュリティ対策を施した上で保管してください。
>
> 参照: https://www.openldap.org/doc/admin24/tls.html#Server%20Certificates

#### 1-4-4. クロスルート証明書のインストール

サーバ証明書G8 RSA認証局を利用する場合:

```bash
$ mv tlsrsarootca2024cross-pem.cer /etc/openldap/certs/tlsrsarootca2024cross-pem.cer
```

OpenLDAP設定への追加（`enable-ldaps.ldif`に以下を追記）:

```
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/openldap/certs/tlsrsarootca2024cross-pem.cer
```

### 1-5. OpenLDAPの設定変更

配置した証明書を読み込むための設定と、LDAPSを有効にするための設定を追加する必要があります。

**1. 証明書読み込み設定の追加**

ldifファイルを作成:

```bash
$ vi ./enable-ldaps.ldif
```

```
dn:cn=config
changetype:modify
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/openldap/certs/nii-odca4g8rsa-pem.cer
replace:olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/server.crt
replace:olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/servername.key
```

ldifファイルを反映:

```bash
$ ldapmodify -Y EXTERNAL -H ldapi:/// -f enable-ldaps.ldif
```

反映結果を確認:

```bash
$ ldapsearch -LLL -Y EXTERNAL -H ldapi:// -b cn=config
```

確認項目:
- `olcTLSCACertificateFile: /etc/openldap/certs/nii-odca4g8rsa-pem.cer`
- `olcTLSCertificateFile: /etc/openldap/certs/server.crt`
- `olcTLSCertificateKeyFile: /etc/openldap/certs/servername.key`

**2. LDAPS通信の有効化**

```bash
$ vi /etc/sysconfig/slapd
```

`SLAPD_URLS`にldaps通信の記載を追加:

```
SLAPD_URLS="ldapi:/// ldap:/// ldaps:///"
```

### 1-6. サーバ証明書の置き換えインストール

```bash
# 旧鍵ペアのバックアップ
$ cp servername.key servername.key.old

# 旧サーバ証明書のバックアップ
$ cp server.crt server.crt.old

# 旧中間CA証明書のバックアップ
$ cp nii-odca4g8rsa-pem.cer nii-odca4g8rsa-pem.cer.old

# 新しい証明書の配置（1-2〜1-4の手順に従う）
$ mv nii-odca4g8rsa-pem.cer /etc/openldap/certs/nii-odca4g8rsa-pem.cer
$ mv servername.key /etc/openldap/certs/servername.key
$ mv server.crt /etc/openldap/certs/server.crt
```

### 1-7. 起動確認

OpenLDAPの再起動は不要です。

OpenLDAPクライアント経由で、該当のサーバへアクセスし、SSL通信に問題がないことを確認してください。
