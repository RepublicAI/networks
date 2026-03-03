# Republic AI: GPU Compute Jobs Guide

This guide explains how to send and receive GPU compute jobs on the Republic AI testnet, including setting up a public result endpoint and submitting job results to the chain.

---

## Overview

The compute job lifecycle on Republic AI:

1. **Job Requester** submits a job to a target validator
2. **Target Validator** executes the job using GPU Docker inference
3. **Validator** uploads result to requester's endpoint
4. **Requester** verifies and submits result hash to the chain

---

## Prerequisites

- Running Republic AI validator node
- Docker with GPU support configured
- `republic-llm-inference:latest` Docker image pulled
- Python 3 installed

---

## Part 1: Receiving Jobs (As Target Validator)

### Check for Pending Jobs
```bash
republicd query computevalidation list-job \
  --node tcp://localhost:43657 \
  --output json 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
my_val = 'raivaloper1YOUR_ADDRESS_HERE'
print('=== JOBS ASSIGNED TO ME ===')
for job in d['jobs']:
    if job['target_validator'] == my_val:
        print(f'Job {job[\"id\"]}: {job[\"status\"]}')
        print(f'  Upload endpoint: {job[\"result_upload_endpoint\"]}')
        print(f'  Execution image: {job[\"execution_image\"]}')
        print()
"
```

### Execute a Job with GPU
```bash
JOB_ID="<job_id>"
UPLOAD_ENDPOINT="<result_upload_endpoint_from_job>"
JOBS_DIR="/var/lib/republic/jobs"

mkdir -p $JOBS_DIR/$JOB_ID

# Run GPU inference
docker run --rm --gpus all \
  -v $JOBS_DIR/$JOB_ID:/output \
  republic-llm-inference:latest

# Calculate result hash
RESULT_HASH=$(sha256sum $JOBS_DIR/$JOB_ID/result.bin | awk '{print $1}')
echo "Result hash: $RESULT_HASH"

# Upload result to requester endpoint
curl -X POST "$UPLOAD_ENDPOINT?job_id=$JOB_ID" \
  --data-binary @$JOBS_DIR/$JOB_ID/result.bin

echo "Result uploaded successfully"
```

### Submit Result to Chain
```bash
JOB_ID="<job_id>"
RESULT_FETCH_URL="<your_public_url>/result.bin"
RESULT_HASH="<sha256_hash_of_result>"

republicd tx computevalidation submit-job-result \
  $JOB_ID \
  $RESULT_FETCH_URL \
  example-verification:latest \
  $RESULT_HASH \
  --from validator \
  --home ~/.republicd \
  --chain-id raitestnet_77701-1 \
  --gas 300000 \
  --gas-prices 1000000000arai \
  --node tcp://localhost:43657 \
  --keyring-backend test \
  -y
```

---

## Part 2: Sending Jobs (As Job Requester)

### Set Up a Public Upload Endpoint

WSL2 does not have a public IP. Use Flask + Cloudflare Tunnel:

**Install Flask:**
```bash
pip3 install flask --break-system-packages
```

**Create upload server:**
```bash
cat > /tmp/upload_server.py << 'EOF'
from flask import Flask, request, jsonify
import os

app = Flask(__name__)
JOBS_DIR = "/var/lib/republic/jobs"

@app.route('/upload', methods=['POST'])
def upload():
    job_id = request.args.get('job_id', 'unknown')
    os.makedirs(f"{JOBS_DIR}/{job_id}", exist_ok=True)
    data = request.get_data()
    with open(f"{JOBS_DIR}/{job_id}/result.bin", 'wb') as f:
        f.write(data)
    print(f"Result received for job {job_id}")
    return jsonify({"status": "ok", "job_id": job_id})

@app.route('/<path:path>', methods=['GET'])
def serve(path):
    full_path = f"{JOBS_DIR}/{path}"
    if os.path.exists(full_path):
        with open(full_path, 'rb') as f:
            return f.read()
    return "Not found", 404

@app.route('/', methods=['GET'])
def index():
    return jsonify({"status": "Republic AI Upload Server running"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Stop any existing server on port 8080
pkill -f "http.server" 2>/dev/null
pkill -f "upload_server" 2>/dev/null
sleep 2

# Start upload server
nohup python3 /tmp/upload_server.py > /tmp/upload_server.log 2>&1 &
echo "Upload server started"
```

**Start Cloudflare Tunnel:**
```bash
nohup cloudflared tunnel --url http://localhost:8080 > /tmp/cloudflare.log 2>&1 &
sleep 10
PUBLIC_URL=$(cat /tmp/cloudflare.log | grep -o 'https://[^[:space:]]*trycloudflare.com')
echo "Your public URL: $PUBLIC_URL"
```

### Send a Job to Another Validator
```bash
TARGET_VALIDATOR="raivaloper1TARGET_ADDRESS_HERE"
PUBLIC_URL="https://your-tunnel.trycloudflare.com"

republicd tx computevalidation submit-job \
  $TARGET_VALIDATOR \
  republic-llm-inference:latest \
  $PUBLIC_URL/upload \
  $PUBLIC_URL/result \
  example-verification:latest \
  1000000000000000000arai \
  --from validator \
  --home ~/.republicd \
  --chain-id raitestnet_77701-1 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  --node tcp://localhost:43657 \
  --keyring-backend test \
  -y
```

### Check Job Status
```bash
JOB_ID="<job_id>"
republicd query computevalidation job $JOB_ID \
  --node tcp://localhost:43657
```

---

## Part 3: Submit Result After Receiving Upload

Once the target validator uploads the result to your endpoint:
```bash
JOB_ID="<job_id>"

# Check if result was received
ls -la /var/lib/republic/jobs/$JOB_ID/

# Get job details
JOB_INFO=$(republicd query computevalidation job $JOB_ID \
  --node tcp://localhost:43657 --output json)

RESULT_HASH=$(echo $JOB_INFO | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['job']['result_hash'])")
RESULT_URL=$(echo $JOB_INFO | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['job']['result_fetch_endpoint'])")

echo "Result hash: $RESULT_HASH"
echo "Result URL: $RESULT_URL"

# Submit result to chain
republicd tx computevalidation submit-job-result \
  $JOB_ID \
  $RESULT_URL \
  example-verification:latest \
  $RESULT_HASH \
  --from validator \
  --home ~/.republicd \
  --chain-id raitestnet_77701-1 \
  --gas 300000 \
  --gas-prices 1000000000arai \
  --node tcp://localhost:43657 \
  --keyring-backend test \
  -y
```

---

## Part 4: Monitor All Your Jobs
```bash
republicd query computevalidation list-job \
  --node tcp://localhost:43657 \
  --output json 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
my_val = 'raivaloper1YOUR_ADDRESS_HERE'
my_addr = 'rai1YOUR_WALLET_ADDRESS_HERE'

print('=== JOBS ASSIGNED TO ME ===')
for job in d['jobs']:
    if job['target_validator'] == my_val:
        print(f'  Job {job[\"id\"]}: {job[\"status\"]}')

print()
print('=== JOBS I SENT ===')
for job in d['jobs']:
    if job['creator'] == my_addr:
        print(f'  Job {job[\"id\"]}: {job[\"status\"]} -> {job[\"target_validator\"][:30]}...')
"
```

---

## Troubleshooting

### Discord Bot Deleting Links

Discord security bots may delete Cloudflare tunnel URLs. Send URLs in code blocks or with spaces:
```
Upload: your-tunnel [dot] trycloudflare [dot] com/upload
```

### Tunnel URL Changes on Restart

The free Cloudflare quick tunnel generates a new URL on each restart. For a persistent URL, create a free Cloudflare account and set up a named tunnel with a custom domain.

### Job Stuck in PendingExecution

The target validator may not be processing jobs automatically. Reach out via Discord to coordinate job execution with other validators.

### result_hash Already Populated

If a job already has a `result_hash` when you check it, another validator may have already processed it. You can still submit your own result transaction referencing the populated hash.

---

## Job Status Reference

| Status | Meaning |
|---|---|
| `PendingExecution` | Job submitted, waiting for validator to execute |
| `PendingValidation` | Result submitted, waiting for committee verification |
| `Completed` | Job verified and finalized |
| `Failed` | Job execution or verification failed |

---

*This guide was contributed by a community validator based on hands-on experience running GPU compute jobs on Republic AI testnet.*
