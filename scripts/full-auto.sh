#!/bin/bash
# Republic AI - Full Auto Compute Script
# Automatically submits jobs, runs GPU inference, and submits results
# GitHub: https://github.com/erhnysr/republic-ai-node

# ─── CONFIGURATION ───────────────────────────────────────────────
VALOPER="YOUR_VALOPER_ADDRESS"
WALLET="YOUR_WALLET_ADDRESS"
NODE="tcp://localhost:43657"
CHAIN_ID="raitestnet_77701-1"
SERVER_IP="YOUR_SERVER_IP_OR_CLOUDFLARE_TUNNEL"
JOBS_DIR="/var/lib/republic/jobs"
JOB_FEE="5000000000000000arai"
# ─────────────────────────────────────────────────────────────────

echo "Republic AI Full Auto started..."
echo "Validator: $VALOPER"
echo "Node: $NODE"

while true; do
  # Network check
  BLOCK=$(curl -s http://localhost:43657/status 2>/dev/null | \
    jq -r ".result.sync_info.latest_block_height" 2>/dev/null)
  if [ -z "$BLOCK" ] || [ "$BLOCK" = "null" ]; then
    echo "[$(date '+%H:%M:%S')] Network down, waiting 60s..."
    sleep 60
    continue
  fi
  echo "[$(date '+%H:%M:%S')] Block: $BLOCK"

  # Thermal protection
  TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
  if [ -n "$TEMP" ]; then
    echo "[$(date '+%H:%M:%S')] GPU Temp: ${TEMP}C"
    if [ "$TEMP" -ge 85 ]; then
      echo "CRITICAL: ${TEMP}C - cooling down 5 minutes..."
      sleep 300; continue
    elif [ "$TEMP" -ge 80 ]; then
      echo "HOT: ${TEMP}C - cooling down 3 minutes..."
      sleep 180; continue
    elif [ "$TEMP" -ge 75 ]; then
      echo "WARM: ${TEMP}C - slowing down..."
      WAIT=90
    else
      WAIT=30
    fi
  else
    WAIT=30
  fi

  # Submit job
  echo "[$(date '+%H:%M:%S')] Submitting job..."
  TX=$(republicd tx computevalidation submit-job \
    $VALOPER \
    republic-llm-inference:latest \
    https://$SERVER_IP/upload \
    https://$SERVER_IP/result \
    example-verification:latest \
    $JOB_FEE \
    --from validator \
    --home $HOME/.republicd \
    --chain-id $CHAIN_ID \
    --gas auto \
    --gas-adjustment 1.5 \
    --gas-prices 1000000000arai \
    --node $NODE \
    --keyring-backend test \
    -y 2>/dev/null | grep txhash | awk '{print $2}')
  echo "[$(date '+%H:%M:%S')] TX: $TX"

  if [ -z "$TX" ]; then
    echo "TX empty, network issue. Waiting 30s..."
    sleep 30; continue
  fi

  sleep 15

  # Get Job ID
  JOB_ID=$(republicd query tx $TX --node $NODE -o json 2>/dev/null | \
    jq -r '.events[] | select(.type=="job_submitted") | .attributes[] | select(.key=="job_id") | .value')
  echo "[$(date '+%H:%M:%S')] Job ID: $JOB_ID"

  if [ -z "$JOB_ID" ]; then
    echo "Job ID not found, skipping..."
    sleep 30; continue
  fi

  # Run GPU inference
  RESULT_FILE="$JOBS_DIR/$JOB_ID/result.bin"
  mkdir -p $JOBS_DIR/$JOB_ID

  timeout 60 docker run --rm --gpus all \
    -v $JOBS_DIR/$JOB_ID:/output \
    republic-llm-inference:latest 2>/dev/null

  if [ $? -ne 0 ]; then
    echo "Docker error for job $JOB_ID, skipping..."
    sleep 30; continue
  fi

  echo "[$(date '+%H:%M:%S')] Inference done for job $JOB_ID"

  # Submit result (with bech32 fix)
  if [ -f "$RESULT_FILE" ]; then
    SHA256=$(sha256sum $RESULT_FILE | awk '{print $1}')

    republicd tx computevalidation submit-job-result \
      $JOB_ID \
      https://$SERVER_IP/$JOB_ID/result.bin \
      example-verification:latest \
      $SHA256 \
      --from validator \
      --home $HOME/.republicd \
      --chain-id $CHAIN_ID \
      --gas 300000 \
      --gas-prices 1000000000arai \
      --node $NODE \
      --keyring-backend test \
      --generate-only 2>/dev/null > /tmp/tx_unsigned.json

    # Fix bech32 address bug
    python3 -c "
import bech32, json
tx = json.load(open('/tmp/tx_unsigned.json'))
_, data = bech32.bech32_decode('$WALLET')
valoper = bech32.bech32_encode('raivaloper', data)
tx['body']['messages'][0]['validator'] = valoper
json.dump(tx, open('/tmp/tx_unsigned.json', 'w'))
print('Bech32 fix applied:', valoper)
"
    republicd tx sign /tmp/tx_unsigned.json \
      --from validator \
      --home $HOME/.republicd \
      --chain-id $CHAIN_ID \
      --node $NODE \
      --keyring-backend test \
      --output-document /tmp/tx_signed.json 2>/dev/null

    republicd tx broadcast /tmp/tx_signed.json \
      --node $NODE \
      --chain-id $CHAIN_ID 2>/dev/null | grep txhash | \
      awk "{print \"[$(date '+%H:%M:%S')] Job $JOB_ID submitted! TX: \"\$2}"

    sleep 15
  fi

  echo "[$(date '+%H:%M:%S')] Waiting ${WAIT}s..."
  sleep $WAIT
done
