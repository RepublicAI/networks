#!/usr/bin/env bash
# Republic AI network state sync bootstrap script
# Configures a fresh republicd node to join via state sync from the
# official snapshot provider, with the RPC node as a light client witness.
#
# Usage:
#   ./republicsync.sh                # Use defaults
#   ./republicsync.sh --home /path   # Custom home directory
#   ./republicsync.sh --reset        # Unsafe-reset-all before configuring

set -euo pipefail

# ---------------------------------------------------------------------------
# Network constants
# ---------------------------------------------------------------------------
SNAP_RPC="https://state-sync-service.republicai.io"
WITNESS_RPC="https://rpc.republicai.io"
SNAP_PEER="f13fec7efb7538f517c74435e082c7ee54b4a0ff@54.204.89.111:26656"
RPC_PEER="cd10f1a4162e3a4fadd6993a24fd5a32b27b8974@3.94.103.50:26656"

# Snapshot interval on the provider is 1000 blocks (~83 min at 5s blocks).
# We round the trust height down to the nearest 1000 so it aligns with an
# actual snapshot boundary, then step back one more interval as a safety
# margin so the snapshot has had time to finish writing.
SNAP_INTERVAL=1000

# Trust period -- should be roughly 2/3 of the unbonding period.
TRUST_PERIOD="168h0m0s"

# Chunk fetcher parallelism -- the provider is a single node so keep this
# reasonable to avoid overwhelming it, but high enough to saturate the link.
CHUNK_FETCHERS=4

# ---------------------------------------------------------------------------
# CLI flags
# ---------------------------------------------------------------------------
REPUBLIC_HOME="${HOME}/.republic"
DO_RESET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home)  REPUBLIC_HOME="$2"; shift 2 ;;
    --reset) DO_RESET=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--home <dir>] [--reset]"
      echo "  --home   republicd home directory (default: ~/.republic)"
      echo "  --reset  run 'republicd tendermint unsafe-reset-all' first"
      exit 0 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

CONFIG_FILE="${REPUBLIC_HOME}/config/config.toml"

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
for cmd in curl jq sed; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Required tool missing: $cmd"; exit 1; }
done

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config not found at $CONFIG_FILE"
  echo "Run 'republicd init <moniker>' first, or pass --home <dir>."
  exit 1
fi

# ---------------------------------------------------------------------------
# Optional reset
# ---------------------------------------------------------------------------
if $DO_RESET; then
  echo "Resetting node state..."
  republicd tendermint unsafe-reset-all --home "$REPUBLIC_HOME" 2>/dev/null \
    || republicd cometbft unsafe-reset-all --home "$REPUBLIC_HOME"
fi

# ---------------------------------------------------------------------------
# Fetch latest height from the snapshot provider
# ---------------------------------------------------------------------------
echo "Querying snapshot provider for latest height..."

status_json=$(curl -sS --fail --max-time 10 "${SNAP_RPC}/status") || {
  echo "Cannot reach ${SNAP_RPC}/status"; exit 1
}

# Handle both wrapped (.result.sync_info) and unwrapped (.sync_info) responses
LATEST=$(jq -r '(.result.sync_info.latest_block_height // .sync_info.latest_block_height) // empty' <<<"$status_json")

if ! [[ "$LATEST" =~ ^[0-9]+$ ]]; then
  echo "Unexpected latest_block_height: '${LATEST:-empty}'"
  exit 1
fi

echo "  Latest height: $LATEST"

# ---------------------------------------------------------------------------
# Calculate trust height aligned to snapshot boundary
# ---------------------------------------------------------------------------
# Round down to the nearest SNAP_INTERVAL, then subtract one more interval
# so the snapshot at that height has definitely been written and propagated.
TRUST_HEIGHT=$(( (LATEST / SNAP_INTERVAL - 2) * SNAP_INTERVAL ))
(( TRUST_HEIGHT < 1 )) && TRUST_HEIGHT=1

# ---------------------------------------------------------------------------
# Fetch trust hash at the calculated height
# ---------------------------------------------------------------------------
echo "Fetching block hash at trust height $TRUST_HEIGHT..."

block_json=$(curl -sS --fail --max-time 10 "${SNAP_RPC}/block?height=${TRUST_HEIGHT}") || {
  echo "Cannot fetch block at height $TRUST_HEIGHT"; exit 1
}

TRUST_HASH=$(jq -r '(.result.block_id.hash // .block_id.hash) // empty' <<<"$block_json")

if [[ -z "$TRUST_HASH" || "$TRUST_HASH" == "null" ]]; then
  echo "Failed to obtain block hash at height $TRUST_HEIGHT"
  exit 1
fi

echo "  Trust hash:   $TRUST_HASH"

# ---------------------------------------------------------------------------
# Cross-verify against the witness RPC
# ---------------------------------------------------------------------------
echo "Cross-verifying against witness RPC..."

witness_json=$(curl -sS --fail --max-time 10 "${WITNESS_RPC}/block?height=${TRUST_HEIGHT}") || {
  echo "Warning: could not reach witness RPC for verification (continuing anyway)"
  witness_json=""
}

if [[ -n "$witness_json" ]]; then
  WITNESS_HASH=$(jq -r '(.result.block_id.hash // .block_id.hash) // empty' <<<"$witness_json")
  if [[ "$WITNESS_HASH" != "$TRUST_HASH" ]]; then
    echo "HASH MISMATCH between provider and witness at height $TRUST_HEIGHT"
    echo "  Provider: $TRUST_HASH"
    echo "  Witness:  $WITNESS_HASH"
    echo "Aborting -- investigate before proceeding."
    exit 1
  fi
  echo "  Verified: hashes match."
fi

# ---------------------------------------------------------------------------
# Patch config.toml
# ---------------------------------------------------------------------------
echo "Updating $CONFIG_FILE..."

# State sync section -- match CometBFT's underscore-style TOML keys
sed -i '/^\[statesync\]/,/^\[/{
  s|^enable *=.*|enable = true|
  s|^rpc_servers *=.*|rpc_servers = "'"${SNAP_RPC},${WITNESS_RPC}"'"|
  s|^trust_height *=.*|trust_height = '"${TRUST_HEIGHT}"'|
  s|^trust_hash *=.*|trust_hash = "'"${TRUST_HASH}"'"|
  s|^trust_period *=.*|trust_period = "'"${TRUST_PERIOD}"'"|
  s|^chunk_fetchers *=.*|chunk_fetchers = "'"${CHUNK_FETCHERS}"'"|
  s|^discovery_time *=.*|discovery_time = "15s"|
}' "$CONFIG_FILE"

# Persistent peers -- append ours without clobbering existing entries
CURRENT_PEERS=$(sed -n '/^persistent_peers *=/{s/^persistent_peers *= *"\(.*\)"/\1/;p;q}' "$CONFIG_FILE")
OUR_PEERS="${SNAP_PEER},${RPC_PEER}"
if [[ -n "$CURRENT_PEERS" ]]; then
  # Deduplicate: only add peers not already present
  NEW_PEERS="$CURRENT_PEERS"
  for p in $(echo "$OUR_PEERS" | tr ',' '\n'); do
    node_id="${p%%@*}"
    if ! echo "$CURRENT_PEERS" | grep -q "$node_id"; then
      NEW_PEERS="${NEW_PEERS},${p}"
    fi
  done
else
  NEW_PEERS="$OUR_PEERS"
fi
sed -i 's|^persistent_peers *=.*|persistent_peers = "'"${NEW_PEERS}"'"|' "$CONFIG_FILE"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "State sync configured:"
echo "  enable         = true"
echo "  rpc_servers    = ${SNAP_RPC},${WITNESS_RPC}"
echo "  trust_height   = ${TRUST_HEIGHT}"
echo "  trust_hash     = ${TRUST_HASH}"
echo "  trust_period   = ${TRUST_PERIOD}"
echo "  chunk_fetchers = ${CHUNK_FETCHERS}"
echo "  peers          = ${NEW_PEERS}"
echo ""
echo "Start the node with:"
echo "  republicd start --home ${REPUBLIC_HOME}"
