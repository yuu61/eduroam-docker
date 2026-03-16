FROM debian:bookworm-slim

# radtest（freeradius-utils）とeapol_testビルド用パッケージ
RUN apt-get update && apt-get install -y --no-install-recommends \
    freeradius-utils \
    build-essential \
    libssl-dev \
    libnl-3-dev \
    libnl-genl-3-dev \
    pkg-config \
    wget \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# eapol_testをwpa_supplicantソースからビルド
RUN cd /tmp && \
    wget -q https://w1.fi/releases/wpa_supplicant-2.10.tar.gz && \
    tar xzf wpa_supplicant-2.10.tar.gz && \
    cd wpa_supplicant-2.10/wpa_supplicant && \
    cp defconfig .config && \
    sed -i 's/#CONFIG_EAPOL_TEST=y/CONFIG_EAPOL_TEST=y/' .config && \
    make eapol_test -j$(nproc) && \
    cp eapol_test /usr/local/bin/ && \
    cd / && rm -rf /tmp/wpa_supplicant-*

WORKDIR /scripts

CMD ["sleep", "infinity"]
