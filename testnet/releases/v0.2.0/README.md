# Republic AI Testnet - v0.2.0 Release Notes

## Overview

This release introduces key improvements to the Republic AI testnet, including RPC endpoint enhancements, staking fixes, and binary updates.

## What's New

### GetBlockResults RPC Endpoint
- Added `GetBlockResults` RPC endpoint via cosmos-sdk fork
- Improves compatibility with EVM tooling that queries block results directly

### Staking Hooks Fix
- Fixed staking hooks initialization order
- Resolves edge cases during validator set updates at genesis

### 18-Decimal Chain Test Fixes
- Updated test suite to correctly handle 18-decimal (`arai`) token amounts
- Ensures consistent behavior across unit and integration tests

## Upgrade Instructions

### Binary Download

Download the latest binary from the [v0.2.0 release page](https://github.com/RepublicAI/networks/releases/tag/v0.2.0):

```bash
VERSION="v0.2.0"
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
curl -L "https://github.com/RepublicAI/networks/releases/download/${VERSION}/republicd-linux-${ARCH}" -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd
```

Verify the binary version:
```bash
republicd version
```

### Upgrading from v0.1.x

1. Stop your running node:
```bash
sudo systemctl stop republicd
```

2. Replace the binary:
```bash
VERSION="v0.2.0"
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
curl -L "https://github.com/RepublicAI/networks/releases/download/${VERSION}/republicd-linux-${ARCH}" -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd
```

3. Restart your node:
```bash
sudo systemctl start republicd
```

4. Verify sync status:
```bash
republicd status | jq '.sync_info'
```

## Network Information

| Property | Value |
|----------|-------|
| Chain ID | `raitestnet_77701-1` |
| Release  | `v0.2.0` |

## Resources

- [GitHub Release](https://github.com/RepublicAI/networks/releases/tag/v0.2.0)
- [Discord](https://discord.com/invite/republicai)
- [Full Setup Guide](../README.md)
