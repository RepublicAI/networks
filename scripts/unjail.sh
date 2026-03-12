#!/bin/bash
# Republic AI - Auto Unjail Script
# Checks if validator is jailed and automatically unjails

VALOPER="YOUR_VALOPER_ADDRESS"
WALLET="YOUR_WALLET_ADDRESS"
NODE="tcp://localhost:43657"
CHAIN_ID="raitestnet_77701-1"
CHECK_INTERVAL=300  # Check every 5 minutes

echo "Auto-unjail monitor started..."
echo "Validator: $VALOPER"

while true; do
  JAILED=$(republicd query staking validator $VALOPER \
    --node $NODE -o json 2>/dev/null | jq -r '.validator.jailed')

  if [ "$JAILED" = "true" ]; then
    echo "[$(date '+%H:%M:%S')] Validator is JAILED! Attempting unjail..."
    republicd tx slashing unjail \
      --from validator \
      --home $HOME/.republicd \
      --chain-id $CHAIN_ID \
      --gas auto \
      --gas-adjustment 1.5 \
      --gas-prices 1000000000arai \
      --node $NODE \
      --keyring-backend test \
      -y 2>/dev/null | grep txhash | awk '{print "[$(date)] Unjail TX: "$2}'
    echo "[$(date '+%H:%M:%S')] Unjail transaction sent!"
  else
    echo "[$(date '+%H:%M:%S')] Validator status: OK (not jailed)"
  fi

  sleep $CHECK_INTERVAL
done
