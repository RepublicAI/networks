#!/bin/bash
# RepublicAI Node Reporter by goldify
# Wallet: rai1kyvgpy7yt6350xkh3h4s5cdm8uhuj3sqhjds9t

NODE_NAME="goldify"
RPC_URL="http://localhost:26657"

echo "Checking RepublicAI Node Status for $NODE_NAME..."

STATUS=$(curl -s $RPC_URL/status)

if [ -z "$STATUS" ]; then
    echo "Error: Node is not responding at $RPC_URL"
    exit 1
else
    BLOCK_HEIGHT=$(echo $STATUS | jq -r '.result.sync_info.latest_block_height')
    CATCHING_UP=$(echo $STATUS | jq -r '.result.sync_info.catching_up')
    
    echo "Current Block Height: $BLOCK_HEIGHT"
    echo "Syncing: $CATCHING_UP"
    
    if [ "$CATCHING_UP" = "false" ]; then
        echo "Status: Node is fully synced and healthy!"
    else
        echo "Status: Node is still syncing..."
    fi
fi
