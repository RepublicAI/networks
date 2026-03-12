#!/bin/bash
# Republic AI - Validator Health Monitor
# Displays real-time validator and node statistics

VALOPER="YOUR_VALOPER_ADDRESS"
NODE="tcp://localhost:43657"

clear
echo "╔═══════════════════════════════════════════╗"
echo "║     Republic AI Validator Monitor          ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# Node sync status
echo "── NODE STATUS ─────────────────────────────"
republicd status --node $NODE 2>/dev/null | jq '{
  block: .sync_info.latest_block_height,
  catching_up: .sync_info.catching_up,
  peers: .node_info.other.rpc_address
}' 2>/dev/null || echo "Node not responding"

echo ""
echo "── VALIDATOR STATUS ─────────────────────────"
republicd query staking validator $VALOPER \
  --node $NODE -o json 2>/dev/null | jq '{
  moniker: .validator.description.moniker,
  status: .validator.status,
  jailed: .validator.jailed,
  tokens: (.validator.tokens | tonumber / 1e18 | floor | tostring) + " RAI",
  commission: .validator.commission.commission_rates.rate
}' 2>/dev/null || echo "Validator not found"

echo ""
echo "── GPU STATUS ───────────────────────────────"
nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total \
  --format=csv,noheader 2>/dev/null || echo "No GPU detected"

echo ""
echo "── JOBS (last 10 minutes) ───────────────────"
if [ -f "$HOME/full-auto.log" ]; then
  grep "Job.*submitted! TX\|Inference done\|TX bos\|Docker error" \
    $HOME/full-auto.log | tail -10
else
  echo "No job log found"
fi

echo ""
echo "── PROCESS STATUS ───────────────────────────"
pgrep -f "full-auto.sh" > /dev/null && echo "✅ full-auto.sh: RUNNING" || echo "❌ full-auto.sh: STOPPED"
pgrep -f "watchdog.sh" > /dev/null && echo "✅ watchdog.sh: RUNNING" || echo "❌ watchdog.sh: STOPPED"
pgrep -f "http.server" > /dev/null && echo "✅ HTTP server: RUNNING" || echo "❌ HTTP server: STOPPED"
pgrep -f "republicd" > /dev/null && echo "✅ republicd: RUNNING" || echo "❌ republicd: STOPPED"
