## State Sync Bootstrapping

### [statesync.sh](https://github.com/RepublicAI/networks/blob/2460cda4a2a2258b1d0ae289a6316847acc3ec8e/scripts/statesync.sh)

Configures a `republicd` node to use state sync instead of replaying the full chain.

**Prerequisites**
- `republicd init <moniker>` has been run
- `curl`, `jq`, `sed` installed

### Run after copying or downloading the script

```sh
# Default home (~/.republic)
./scripts/statesync.sh

# Custom home directory
./scripts/statesync.sh --home /opt/republic

# Optional: wipe existing state
./scripts/statesync.sh --reset
````

### Run directly without cloning

```sh
bash <(curl -sS https://raw.githubusercontent.com/RepublicAI/networks/main/scripts/statesync.sh)

# With flags
bash <(curl -sS https://raw.githubusercontent.com/RepublicAI/networks/main/scripts/statesync.sh) --reset
```

After running, start the node:

```sh
republicd start
```
