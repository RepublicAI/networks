# Changelog

All notable changes to Republic AI Networks will be documented in this file.

## [0.1.0] - 2026-01-22

### Added
- Initial testnet release (`raitestnet_77701-1`)
- Multi-arch Docker image (amd64/arm64) published to `ghcr.io/republicai/republicd:0.1.0`
- State sync support via https://statesync.republicai.io
- Binary releases for Linux (amd64/arm64) via Git LFS
- Chain registry files (`chain.json`, `assetlist.json`)
- Validator onboarding guide with three installation options:
  - Binary installation with state sync
  - Full sync from genesis
  - Docker with state sync

### Infrastructure
- Genesis validator node
- Secondary validator node
- 2 load-balanced RPC nodes
- Dedicated state sync node
- Public endpoints with TLS:
  - Cosmos RPC: https://rpc.republicai.io
  - REST API: https://rest.republicai.io
  - gRPC: grpc.republicai.io:443
  - EVM JSON-RPC: https://evm-rpc.republicai.io

### Documentation
- Network joining guide for validators
- Systemd service configuration
- Useful commands reference
