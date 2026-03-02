# Republic AI Node - Troubleshooting Guide

Common issues during Republic AI testnet node setup on WSL.

## 1. Wrong RPC port
Default port is 26657 but Republic uses 43657.
Check your port: grep "laddr" ~/.republicd/config/config.toml
Use: republicd status --node tcp://localhost:43657

## 2. Block height stuck at 0
State sync trust_height is outdated. Use snapshot instead:
curl -L https://snapshot.vinjan-inc.com/republic/latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.republicd

## 3. Wrong app version error
Download v0.3.0 binary:
curl -L https://github.com/RepublicAI/networks/releases/download/v0.3.0/republicd-linux-amd64 -o republicd
cp republicd ~/.republicd/cosmovisor/genesis/bin/republicd

## 4. Wrong home directory
Use ~/.republicd not ~/.republic in all commands.

## 5. Database locked error
pkill -9 -f republicd && pkill -9 -f cosmovisor
Or: sudo systemctl stop republicd

## 6. Cosmovisor DAEMON_NAME not set
DAEMON_NAME=republicd DAEMON_HOME=$HOME/.republicd cosmovisor run start --home ~/.republicd --chain-id raitestnet_77701-1

## 7. Systemd service setup (WSL)
sudo tee /etc/systemd/system/republicd.service << EOF
[Unit]
Description=Republic Node
After=network-online.target
[Service]
User=$USER
Environment="DAEMON_NAME=republicd"
Environment="DAEMON_HOME=$HOME/.republicd"
ExecStart=/home/$USER/go/bin/cosmovisor run start --home /home/$USER/.republicd --chain-id raitestnet_77701-1
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload && sudo systemctl enable republicd && sudo systemctl start republicd
