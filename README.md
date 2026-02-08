# Installable Governance Kernel (IGK)

## What This Is

An installable governance kernel that enforces rules **by execution**, not policy.

Governance here is:
- deterministic
- auditable
- append-only
- safe under failure

If it runs, it governs.
If it fails, it fails safely.

---

## What This Is Not

- Not a DAO
- Not AI ethics
- Not a policy framework
- Not advisory governance
- Not permission-based authority

---

## One-Command Demo

```bash
docker compose up
./demo_fail_safely.sh
How to Break Governance (On Purpose)

You are expected to try to break it.

This repo includes built-in failure cases:

entropy overflow

drift violation

validator disagreement

hash mismatch attempts

Each one should:

be rejected

be logged

NOT corrupt history

What Safe Failure Looks Like

When governance fails:

❌ No ledger writes

❌ No history rewrite

❌ No silent override

Instead:

rejected emissions go to the mutable shell

failure reasons are explicit

last valid state remains authoritative

Architectural Guarantees

Typed state

Versioned bias

Domain-scoped alpha

Stateful continuity enforcement

Dual validator anchoring

Append-only fossil ledger

If any invariant is violated, execution halts.

Invariant Guarantee

If governance fails, it fails without corruption.

Clone it.
Break it.
Watch it refuse to lie.


---

# 3️⃣ `tests/test_governance.py` (pytest)

This suite proves **failure paths are first-class**, not edge cases.

```python
import requests
import time

BASE_RUNTIME = "http://localhost:8000"
BASE_LEDGER = "http://localhost:8002"

def emit(payload, headers=None):
    return requests.post(
        f"{BASE_RUNTIME}/emit",
        json=payload,
        headers=headers or {},
        timeout=5
    )

def get_ledger():
    return requests.get(f"{BASE_LEDGER}/ledger", timeout=5).json()

def test_valid_emission_is_fossilized():
    payload = {
        "state": {"value": 10, "type": "symbolic"},
        "bias": {"value": 1, "version": "v1"},
        "alpha": {"value": 1.0, "domain": "test"}
    }

    r = emit(payload)
    assert r.status_code == 200

    ledger = get_ledger()
    assert len(ledger) >= 1

def test_entropy_violation_is_rejected():
    payload = {
        "state": {"value": [1,2,3,9999], "type": "symbolic"},
        "bias": {"value": 1, "version": "v1"},
        "alpha": {"value": 10.0, "domain": "test"}
    }

    before = len(get_ledger())
    r = emit(payload)
    after = len(get_ledger())

    assert r.status_code == 400
    assert before == after

def test_validator_mismatch_blocks_fossilization():
    payload = {
        "state": {"value": 5, "type": "symbolic"},
        "bias": {"value": 1, "version": "v2"},
        "alpha": {"value": 1.0, "domain": "test"}
    }

    before = len(get_ledger())
    r = emit(payload, headers={"X-Force-Mismatch": "true"})
    after = len(get_ledger())

    assert r.status_code == 400
    assert before == after

def test_continuity_preserved_on_failure():
    ledger = get_ledger()
    last_hash = ledger[-1]["hash"]

    payload = {
        "state": {"value": 99999, "type": "symbolic"},
        "bias": {"value": 999, "version": "bad"},
        "alpha": {"value": 999, "domain": "test"}
    }

    emit(payload)
    ledger_after = get_ledger()

    assert ledger_after[-1]["hash"] == last_hash
