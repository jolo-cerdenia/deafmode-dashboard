# deafmode signal schema

schema version: v0.3

---

## purpose

`signal.json` is the canonical operational telemetry payload for deafmode.

It is designed to be:
- machine-readable
- human-legible
- low-noise
- resilient across distributed consumers

Consumers may include:
- dashboard frontends
- Eggdrop parsers
- remote observers
- archival tooling
- future automation systems

---

# canonical structure

```json
{
  "version": "0.3",
  "generated_at": "2026-05-28T10:42:00+08:00",

  "signal": {
    "state": "recovering",
    "display": "RECOVERING",
    "confidence": 0.78,
    "trajectory": "positive"
  },

  "inference": {
    "primary": "recovery capacity stabilizing",
    "secondary": [
      "stress load tolerable"
    ]
  },

  "drift": {
    "present": true,
    "severity": "moderate",
    "vector": "context switching elevated"
  },

  "response": {
    "priority": "protect uninterrupted blocks",
    "secondary": [
      "reduce notification exposure"
    ]
  },

  "resources": {
    "sleep_hours": 6.2,
    "training_readiness": 0.71,
    "cognitive_load": 0.83
  },

  "meta": {
    "schema": "deafmode-signal-v0.3",
    "generator": "heartbeat.sh",
    "stale_after_sec": 7200,
    "sequence": 184
  }
}