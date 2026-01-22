FROM ubuntu:22.04

ARG TARGETARCH
ARG VERSION=v0.1.0

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY republicd-linux-${TARGETARCH:-amd64} /usr/local/bin/republicd
RUN chmod +x /usr/local/bin/republicd

RUN useradd -m -s /bin/bash republic
USER republic
WORKDIR /home/republic

ENV HOME=/home/republic
ENV REPUBLIC_HOME=/home/republic/.republicd

EXPOSE 26656
EXPOSE 26657
EXPOSE 1317
EXPOSE 9090
EXPOSE 8545
EXPOSE 8546

ENTRYPOINT ["republicd"]
CMD ["start", "--chain-id", "raitestnet_77701-1"]
