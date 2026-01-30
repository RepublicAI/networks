# Republic AI Testnet

## This Guide from Vinjan.Inc

### Prerequisites

- Ubuntu 24.04 LTS
- 4+ CPU cores
- 16GB+ RAM
- 500GB+ SSD

### Install dependencies Required
```
sudo apt update && sudo apt upgrade -y && sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y
```

### Install go

We are gonna use GO Version 1.25.6
If you already have GO installed you can skip this 
```
ver="1.25.6"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version
```

### Install binary
```
wget https://github.com/RepublicAI/networks/raw/refs/heads/main/testnet/releases/v0.1.0/republicd-linux-amd64 -O republicd
chmod +x republicd
mv republicd $HOME/go/bin/
```
### Verify that you've installed successfully
```
republicd version  --long | grep -e version -e commit
```

### Initialize Node
Please change `<MONIKER>` To your own Moniker.
```
republicd init <MONIKER> --chain-id raitestnet_77701-1
```

### Download Genesis
```
curl -L https://snapshot-t.vinjan-inc.com/republic/genesis.json > $HOME/.republic/config/genesis.json
```

### Download Addrbook (update every 6 hour)
```
curl -L https://snapshot-t.vinjan-inc.com/republic/addrbook.json > $HOME/.republic/config/addrbook.jso
```

### Configure Gas
```
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"2500000000arai\"/" $HOME/.republic/config/app.toml
```

### Add Peerr ( if needed )
```
peers="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656,a5d2fe7d932c3b6f7c9633164f102315d1f575c6@195.201.160.23:13356"
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$peers\"|" $HOME/.republic/config/config.toml
```

### create service file and start node
```
sudo tee /etc/systemd/system/republicd.service > /dev/null <<EOF
[Unit]
Description=republic
After=network-online.target

[Service]
User=$USER
ExecStart=$(which republicd) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

### Enable Service and Start Node

```
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl restart republicd
sudo journalctl -u republicd -f -o cat
```

### Use Snapshot for faster sync
<a href="https://vinjan-inc.com/testnet/republic/snapshot" target="_blank">
  <button style="background-color: green; border: none; color: white; padding: 15px 32px; text-align: center; text-decoration: none; display: inline-block; font-size: 16px; margin: 4px 2px; cursor: pointer; border-radius: 10px; box-shadow: 0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19);" onmouseover="this.style.boxShadow='0 0 0 4px rgba(0,255,0,0.5)'" onmouseout="this.style.boxShadow='0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19)'">Snapshot</button>
</a>


### Explorer
<a href="https://explorer.vinjan-inc.com/republic-testnet/staking" target="_blank">
  <button style="background-color: green; border: none; color: white; padding: 15px 32px; text-align: center; text-decoration: none; display: inline-block; font-size: 16px; margin: 4px 2px; cursor: pointer; border-radius: 10px; box-shadow: 0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19);" onmouseover="this.style.boxShadow='0 0 0 4px rgba(0,255,0,0.5)'" onmouseout="this.style.boxShadow='0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19)'">Explorer</button>
</a>


### Complete Guides
<a href="https://vinjan-inc.com/testnet/republic" target="_blank">
  <button style="background-color: green; border: none; color: white; padding: 15px 32px; text-align: center; text-decoration: none; display: inline-block; font-size: 16px; margin: 4px 2px; cursor: pointer; border-radius: 10px; box-shadow: 0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19);" onmouseover="this.style.boxShadow='0 0 0 4px rgba(0,255,0,0.5)'" onmouseout="this.style.boxShadow='0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19)'">Website</button>
</a>
