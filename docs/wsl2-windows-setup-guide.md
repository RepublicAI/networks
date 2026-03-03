# Republic AI Validator Node Setup on Windows (WSL2 + GPU)

This guide covers setting up a Republic AI validator node on **Windows 11** using **WSL2 (Ubuntu 24.04)** with full **GPU compute support** via NVIDIA CUDA and Docker.

> **Why WSL2?** Many validators run on Windows laptops or desktops. This guide enables GPU-accelerated inference without requiring a dedicated Linux machine.

---

## Prerequisites

| Requirement | Minimum |
|---|---|
| OS | Windows 10 (Build 19041+) or Windows 11 |
| RAM | 16GB+ |
| Storage | 100GB+ free on WSL2 drive |
| GPU | NVIDIA GPU with CUDA support (6GB+ VRAM recommended) |
| NVIDIA Driver | 525.x or later (Windows driver) |

---

## Step 1: Enable WSL2 and Install Ubuntu 24.04

Open **PowerShell as Administrator** and run:
```powershell
wsl --install -d Ubuntu-24.04
```

After installation, restart your computer and set WSL2 as default:
```powershell
wsl --set-default-version 2
```

Verify WSL2 is active:
```powershell
wsl -l -v
```

You should see `VERSION 2` next to Ubuntu-24.04.

---

## Step 2: Configure WSL2 Memory and Resources

Create or edit `C:\Users\<YourUsername>\.wslconfig`:
```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
```

Restart WSL2:
```powershell
wsl --shutdown
wsl
```

---

## Step 3: Install NVIDIA CUDA Toolkit in WSL2

> **Important:** Do NOT install NVIDIA drivers inside WSL2. Only install the CUDA toolkit. WSL2 uses your Windows NVIDIA driver automatically.

Inside WSL2 Ubuntu terminal:
```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-11-8
```

Add CUDA to PATH:
```bash
echo 'export PATH=/usr/local/cuda-11.8/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

Verify:
```bash
nvidia-smi
nvcc --version
```

---

## Step 4: Install Docker with NVIDIA GPU Support
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

Test:
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

---

## Step 5: Prevent Laptop Sleep When Lid is Closed

1. Open **Control Panel** → **Power Options**
2. Click **"Choose what closing the lid does"**
3. Set **"When I close the lid"** to **"Do nothing"** for both Battery and Plugged in
4. Click **Save changes**

---

## Step 6: Fix DNS Resolution (If Needed)
```bash
sudo tee /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
```

---

## Step 7: Install Republic AI Node

Follow the standard installation from [testnet guide](../testnet/readme.md), then continue below for GPU-specific configuration.
```bash
sudo tee /etc/systemd/system/republicd.service << 'EOF'
[Unit]
Description=Republic AI Node
After=network-online.target

[Service]
User=$USER
ExecStart=$(which republicd) start --home $HOME/.republicd
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
```

---

## Step 8: Set Up Auto Compute with Unjail Protection
```bash
cat > ~/auto_compute.sh << 'SCRIPT'
#!/bin/bash
VALIDATOR_ADDRESS="raivaloper1YOUR_ADDRESS_HERE"
WALLET_NAME="validator"
CHAIN_ID="raitestnet_77701-1"
NODE="tcp://localhost:43657"

while true; do
    JAILED=$(republicd query staking validator $VALIDATOR_ADDRESS \
        --node $NODE --output json 2>/dev/null | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d['validator']['jailed'])" 2>/dev/null)
    
    if [ "$JAILED" = "True" ]; then
        echo "$(date): Validator jailed! Sending unjail..."
        republicd tx slashing unjail \
            --from $WALLET_NAME \
            --chain-id $CHAIN_ID \
            --gas auto --gas-adjustment 1.5 \
            --gas-prices 1000000000arai \
            --node $NODE --keyring-backend test -y
        sleep 30
    fi
    sleep 300
done
SCRIPT
chmod +x ~/auto_compute.sh
nohup ~/auto_compute.sh > ~/auto_compute.log 2>&1 &
```

---

## Step 9: Set Up Public Endpoint with Cloudflare Tunnel

WSL2 does not have a public IP. Use Cloudflare Tunnel to expose your result upload endpoint:
```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/

cd /var/lib/republic/jobs
nohup python3 -m http.server 8080 > /tmp/http_server.log 2>&1 &
nohup cloudflared tunnel --url http://localhost:8080 > /tmp/cloudflare.log 2>&1 &
sleep 10
cat /tmp/cloudflare.log | grep trycloudflare
```

---

## Troubleshooting

### GLIBC Version Error
```bash
ldd --version
sudo apt update && sudo apt upgrade -y
```

### Docker GPU Not Detected
```bash
docker info | grep -i runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Validator Jailed After Downtime
```bash
republicd tx slashing unjail \
  --from validator \
  --chain-id raitestnet_77701-1 \
  --gas auto --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  --node tcp://localhost:43657 \
  --keyring-backend test -y
```

---

*This guide was contributed by a community validator running Republic AI on WSL2 with NVIDIA RTX 4050.*
