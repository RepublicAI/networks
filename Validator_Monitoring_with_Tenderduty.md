# Validator Monitoring with Tenderduty

This guide shows how to set up monitoring for your RepublicAI validator using Tenderduty. It's straightforward and gives you a web dashboard plus optional Telegram alerts.

## Prerequisites

- Ubuntu 22.04 or 24.04
- Running RepublicAI validator node
- Go 1.21+ (we'll install this)

## Installation

First, install Go if you don't have it:

```bash
GO_VERSION="1.21.6"
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc
go version
```

Clone and build Tenderduty:

```bash
cd ~
git clone https://github.com/blockpane/tenderduty
cd tenderduty
go install
mkdir -p chains.d
```

## Configuration

Create the config file:

```bash
cd ~/tenderduty
cat > config.yml << 'EOF'
enable_dashboard: true
listen_port: 8888
hide_logs: false
node_down_alert_minutes: 3

telegram:
  enabled: false

discord:
  enabled: false

chains:
  republicai:
    chain_id: raitestnet_77701-1
    valoper_address: YOUR_VALOPER_ADDRESS
    public_fallback: yes
    alerts:
      stalled_enabled: yes
      stalled_minutes: 10
      consecutive_enabled: yes
      consecutive_missed: 5
      consecutive_priority: critical
      percentage_enabled: yes
      percentage_missed: 10
      percentage_priority: warning
      alert_if_inactive: yes
      alert_if_no_servers: yes
    nodes:
      - url: https://rpc-republic.onenov.xyz
        alert_if_down: yes
      - url: http://localhost:YOUR_RPC_PORT
        alert_if_down: yes
EOF
```

Edit the config to add your details:

```bash
nano config.yml
```

You need to change:
- `YOUR_VALOPER_ADDRESS` - your validator operator address (get it with `republicd keys show YOUR_KEY --bech val`)
- `YOUR_RPC_PORT` - your node's RPC port (check your config.toml, usually 26657 or custom)

Save and exit (Ctrl+X, then Y, then Enter).

## Running as a Service

Create a systemd service file:

```bash
sudo tee /etc/systemd/system/tenderduty.service > /dev/null <<EOF
[Unit]
Description=Tenderduty
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/tenderduty
ExecStart=$HOME/go/bin/tenderduty
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
```

Start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable tenderduty
sudo systemctl start tenderduty
```

Check if it's running:

```bash
sudo systemctl status tenderduty
```

View the logs:

```bash
journalctl -u tenderduty -f
```

## Opening the Firewall

You need to allow port 8888 for the dashboard:

```bash
sudo ufw allow 8888/tcp
sudo ufw reload
```

If you're using iptables instead:

```bash
sudo iptables -A INPUT -p tcp --dport 8888 -j ACCEPT
sudo netfilter-persistent save
```

Don't forget to also open port 8888 in your cloud provider's firewall settings (Hetzner, AWS, DigitalOcean, etc).

## Accessing the Dashboard

Open your browser and go to:

```
http://YOUR_SERVER_IP:8888
```

You should see the Tenderduty dashboard showing your validator status, missed blocks, and node health.

## Adding Telegram Notifications (Optional)

If you want to receive alerts on Telegram when something goes wrong:

1. Open Telegram and search for @BotFather
2. Send `/newbot` and follow the instructions to create a bot
3. Save the bot token you receive
4. Send any message to your new bot
5. Get your chat ID by visiting: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
6. Look for `"chat":{"id":123456789}` in the response

Edit your config:

```bash
nano ~/tenderduty/config.yml
```

Change the telegram section:

```yaml
telegram:
  enabled: true
  api_key: "YOUR_BOT_TOKEN"
  channel: "YOUR_CHAT_ID"
```

Restart Tenderduty:

```bash
sudo systemctl restart tenderduty
```

## What Gets Monitored

The dashboard tracks:
- Validator status (active, jailed, inactive)
- Missed blocks in the current window
- Signing percentage
- Node sync status
- Block height
- Whether your RPC endpoints are responding

You'll get alerts (if configured) when:
- Your validator gets jailed
- You miss more than 5 consecutive blocks
- Your node goes down
- Your signing percentage drops below 90%

## Troubleshooting

If the dashboard isn't loading, check:

```bash
# Is the service running?
sudo systemctl status tenderduty

# Check the logs for errors
journalctl -u tenderduty -n 50

# Is the port open?
sudo netstat -tulpn | grep 8888
```

If you see "Failed to scan chainConfigDirectory" in the logs, that's just a warning and can be ignored. The `chains.d` directory is optional.

If your validator shows as INACTIVE but you know it's active, double-check that your valoper address in the config is correct.

## Resources

- Tenderduty GitHub: https://github.com/blockpane/tenderduty
- RepublicAI Discord: https://discord.com/invite/therepublic
- RepublicAI GitHub: https://github.com/RepublicAI/networks

