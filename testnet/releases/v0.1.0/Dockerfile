FROM ubuntu:24.04

ARG TARGETARCH
ARG VERSION=v0.2.0

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY republicd-linux-${TARGETARCH:-amd64} /usr/local/bin/republicd
RUN chmod +x /usr/local/bin/republicd

RUN useradd -m -s /bin/bash republic
USER republic
WORKDIR /home/republic

ENV HOME=/home/republic
ENV REPUBLIC_HOME=/home/republic/.republic

# P2P only for validators - all APIs are disabled in app.toml/config.toml -- uncomment the others as needed
EXPOSE 26656
# EXPOSE 26657
# EXPOSE 1317
# EXPOSE 9090
# EXPOSE 8545
# EXPOSE 8546

ENTRYPOINT ["republicd"]
CMD ["start", "--home", "/home/republic/.republic"]

