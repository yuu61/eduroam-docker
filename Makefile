DOCKER_DIR := docker
COMPOSE := docker compose -f $(DOCKER_DIR)/docker-compose.yml --env-file $(DOCKER_DIR)/.env

# .envから変数を読み込み（Makeターゲット内で使用）
-include $(DOCKER_DIR)/.env

.PHONY: setup build up down restart logs test-radtest test-eapol test test-all certs clean

# 初期セットアップ
setup:
	bash scripts/setup.sh

# 証明書生成
certs:
	bash scripts/generate-certs.sh

# Dockerビルド
build:
	$(COMPOSE) build

# Docker操作
up:
	$(COMPOSE) up -d

up-debug:
	$(COMPOSE) up

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f freeradius

logs-all:
	$(COMPOSE) logs -f

# テスト
test-radtest:
	$(COMPOSE) exec test-client radtest $(TEST_USER) $(TEST_PASSWORD) freeradius 0 $(RADIUS_SECRET)

test-eapol:
	$(COMPOSE) exec test-client eapol_test -c /scripts/eapol_test.conf -s $(RADIUS_SECRET) -a freeradius

test: test-radtest

test-all:
	$(COMPOSE) exec test-client bash /scripts/test-all.sh

# LDAP確認
ldap-search:
	$(COMPOSE) exec openldap ldapsearch -x -H ldap://localhost -b "dc=kobedenshi,dc=ac,dc=jp" -D "cn=admin,dc=kobedenshi,dc=ac,dc=jp" -w $(LDAP_ADMIN_PASSWORD)

# クリーンアップ
clean:
	$(COMPOSE) down -v

clean-certs:
	rm -f $(DOCKER_DIR)/freeradius/raddb/certs/*.pem
	rm -f $(DOCKER_DIR)/freeradius/raddb/certs/*.key
	rm -f $(DOCKER_DIR)/freeradius/raddb/certs/*.crt
	rm -f $(DOCKER_DIR)/freeradius/raddb/certs/*.csr
	rm -f $(DOCKER_DIR)/freeradius/raddb/certs/dh
	rm -f $(DOCKER_DIR)/freeradius/raddb/certs/serial*
	rm -f $(DOCKER_DIR)/freeradius/raddb/certs/index.*
