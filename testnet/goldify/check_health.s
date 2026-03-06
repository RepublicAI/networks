#!/bin/bash
# ==========================================
# REPUBLIC AI - NODE HEALTH CHECK TOOL
# Developed by: goldify
# ==========================================
echo "Checking System Resources for goldify..."
echo "CPU Load: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')%"
echo "Memory: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')"
echo "Disk Space: $(df -h / | awk 'NR==2{print $5}')"
echo -e "\nNode Sync Status:"
curl -s http://localhost:26657/status | jq -r '.result.sync_info | "Block: \(.latest_block_height)\nSyncing: \(.catching_up)"'
