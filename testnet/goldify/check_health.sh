#!/bin/bash
# ==========================================
# REPUBLIC AI - NODE HEALTH CHECK TOOL
# Developed by: goldify
# Wallet: rai1kyvgpy7yt6350xkh3h4s5cdm8uhuj3sqhjds9t
# ==========================================

echo "Checking System Resources..."
echo "---------------------------"
echo "CPU Load: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')%"
echo "Memory: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')"
echo "Disk: $(df -h / | awk 'NR==2{print $5}')"

echo -e "\nChecking RepublicAI Node Status..."
echo "---------------------------"
# RPC üzerinden durum kontrolü
STATUS=$(curl -s http://localhost:26657/status || echo "error")

if [ "$STATUS" == "error" ]; then
    echo "Status: Node is NOT running or RPC is closed."
else
    BLOCK=$(echo $STATUS | jq -r '.result.sync_info.latest_block_height')
    SYNCING=$(echo $STATUS | jq -r '.result.sync_info.catching_up')
    echo "Current Block: $BLOCK"
    echo "Is Catching Up (Syncing): $SYNCING"
fi
echo "=========================================="
