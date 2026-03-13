# 🌐 Republic AI Testnet Helper Bot

**Contribution Type:** Developer Tool  
**Author:** solscammer  
**Live Bot:** [@republicaihelperbot](https://t.me/republicaihelperbot)  
**Repo:** [github.com/kursatkorkmazx-spec/republic-ai-helper-bot](https://github.com/kursatkorkmazx-spec/republic-ai-helper-bot)

---

## Overview

This Telegram bot provides real-time access to Republic AI Testnet data for validators, delegators, and community members. Built using the Republic AI Cosmos RPC and REST API endpoints.

## Technical Stack

- **Language:** Python 3.12
- **Framework:** python-telegram-bot 20.7
- **HTTP Client:** httpx (async)
- **Data:** JSON file-based persistence
- **Infrastructure:** Linux VPS with systemd service
- **Endpoints Used:**
  - `https://rpc.republicai.io`
  - `https://rest.republicai.io`

## Features Implemented

- [x] Real-time block height & sync status
- [x] Active validator set monitoring (100 validator limit)
- [x] Minimum stake calculation to enter active set
- [x] Full wallet info (balance, staking, rewards, unbonding)
- [x] Validator operator address lookup
- [x] Validator search across 650+ validators (paginated)
- [x] Transaction lookup by hash
- [x] Persistent wallet saving per user
- [x] Automated jail alerts (5 min polling)
- [x] Delegation change notifications
- [x] Daily faucet reminders (09:00 UTC)
- [x] 24/7 uptime via systemd

## Why This Matters

Republic AI's vision depends on a healthy validator set and an engaged community. This bot lowers the barrier to entry for:

1. Node operators who need instant jail/inactive alerts
2. Delegators tracking their staking positions
3. New users exploring the network without technical knowledge

## Usage Stats

Bot is live and serving community members on the Republic AI testnet.

## Links

- 🤖 Bot: [@republicaihelperbot](https://t.me/republicaihelperbot)
- 💻 Code: [github.com/kursatkorkmazx-spec/republic-ai-helper-bot](https://github.com/kursatkorkmazx-spec/republic-ai-helper-bot)
- 🌐 Network: [explorer.republicai.io](https://explorer.republicai.io)
