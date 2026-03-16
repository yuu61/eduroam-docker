FROM freeradius/freeradius-server:3.2.6

# デフォルトのサイトを無効化（eduroam用に置き換える）
RUN rm -f /etc/raddb/sites-enabled/default \
    && rm -f /etc/raddb/sites-enabled/inner-tunnel

# カスタム設定をコピー
COPY raddb/clients.conf /etc/raddb/clients.conf
COPY raddb/proxy.conf /etc/raddb/proxy.conf
COPY raddb/mods-available/eap /etc/raddb/mods-available/eap
COPY raddb/mods-available/ldap /etc/raddb/mods-available/ldap
COPY raddb/mods-available/ldap_google /etc/raddb/mods-available/ldap_google
COPY raddb/sites-available/eduroam /etc/raddb/sites-available/eduroam
COPY raddb/sites-available/eduroam-inner-tunnel /etc/raddb/sites-available/eduroam-inner-tunnel
COPY raddb/policy.d/filter /etc/raddb/policy.d/filter

# カスタムモジュールとサイトを有効化
RUN ln -sf /etc/raddb/mods-available/eap /etc/raddb/mods-enabled/eap \
    && ln -sf /etc/raddb/mods-available/ldap /etc/raddb/mods-enabled/ldap \
    && ln -sf /etc/raddb/sites-available/eduroam /etc/raddb/sites-enabled/eduroam \
    && ln -sf /etc/raddb/sites-available/eduroam-inner-tunnel /etc/raddb/sites-enabled/eduroam-inner-tunnel

EXPOSE 1812/udp 1813/udp

CMD ["radiusd", "-f", "-l", "stdout"]
