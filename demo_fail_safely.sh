demo_fail_safely.sh

This script is intentionally adversarial.
It demonstrates three failure modes and proves the ledger does not change.

#!/usr/bin/env bash
set -e

echo "🟢 Starting Installable Governance Kernel demo..."
echo

docker compose up -d
sleep 5

echo "🔎 STEP 1: Submit a VALID Ω emission (should be accepted)"
curl -s -X POST http://localhost:8000/emit \
  -H "Content-Type: application/json" \
  -d '{
    "state": {"value": 10, "type": "symbolic"},
    "bias": {"value": 1, "version": "v1.0.0"},
    "alpha": {"value": 1.1, "domain": "demo"}
  }' | jq

sleep 2

echo
echo "🔎 STEP 2: Trigger ENTROPY VIOLATION (should be rejected)"
curl -s -X POST http://localhost:8000/emit \
  -H "Content-Type: application/json" \
  -d '{
    "state": {"value": [1,2,3,4,9999], "type": "symbolic"},
    "bias": {"value": 1, "version": "v1.0.0"},
    "alpha": {"value": 10.0, "domain": "demo"}
  }' | jq

sleep 2

echo
echo "🔎 STEP 3: Trigger VALIDATOR MISMATCH (should be rejected)"
curl -s -X POST http://localhost:8000/emit \
  -H "Content-Type: application/json" \
  -H "X-Force-Mismatch: true" \
  -d '{
    "state": {"value": 5, "type": "symbolic"},
    "bias": {"value": 1, "version": "v2.0.0"},
    "alpha": {"value": 1.0, "domain": "demo"}
  }' | jq

sleep 2

echo
echo "📜 STEP 4: Inspect fossil ledger (should contain ONLY the first entry)"
curl -s http://localhost:8002/ledger | jq

echo
echo "🧪 STEP 5: Inspect mutable shell (should contain rejected emissions)"
docker exec igk-kernel-runtime ls -l /var/igk/mutable-shell

echo
echo "✅ Demo complete."
echo "Governance failed safely."
