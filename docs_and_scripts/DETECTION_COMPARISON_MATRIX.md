# Attack Types & eBPF Detection Matrix

## Visual Comparison: All 6 Attack Scenarios

```
┌─────────────────────────┬──────────────────────┬─────────────────────┐
│  ATTACK NAME            │  ATTACK METHOD       │  eBPF DETECTS       │
├─────────────────────────┼──────────────────────┼─────────────────────┤
│                         │                      │                     │
│ 1️⃣  EXFILTRATION       │ Service → External   │ UNAUTHORIZED_FLOW   │
│    (Compromised         │ C2 Server           │ Alert Fires: 5-10s   │
│     Service)            │                      │ Severity: HIGH      │
│                         │ Steals:             │                     │
│                         │ • Keys              │ Confidence: 99%     │
│                         │ • Credentials       │                     │
│                         │ • Secrets           │                     │
├─────────────────────────┼──────────────────────┼─────────────────────┤
│                         │                      │                     │
│ 🔍  LATERAL MOVEMENT   │ Service → Multiple   │ HIGH_FANOUT         │
│    (Network Scanning)   │ Unknown Services    │ + LATERAL_MOVEMENT  │
│                         │                      │ Alert Fires: 5-15s  │
│                         │ Probes:             │ Severity: CRITICAL  │
│                         │ • 80+ port scans    │                     │
│                         │ • Service detection │ Confidence: 95%     │
│                         │ • Vulnerability     │                     │
│                         │   research          │                     │
├─────────────────────────┼──────────────────────┼─────────────────────┤
│                         │                      │                     │
│ 📊  DATA THEFT          │ Service → Database   │ SLOW_CONNECT        │
│    (PII Extraction)     │ Full Table Scans    │ Alert Fires: 15-30s │
│                         │                      │ Severity: MEDIUM    │
│                         │ Reads:              │                     │
│                         │ • All customers     │ Confidence: 75%     │
│                         │ • All SSNs          │ (needs DB layer)    │
│                         │ • Payment data      │                     │
├─────────────────────────┼──────────────────────┼─────────────────────┤
│                         │                      │                     │
│ 📈 PRIVILEGE            │ Service → Auth      │ UNAUTHORIZED_FLOW   │
│   ESCALATION            │ Service             │ Alert Fires: 5-10s  │
│    (Backdoor Accounts)  │                      │ Severity: HIGH      │
│                         │ Creates:            │                     │
│                         │ • New admin         │ Confidence: 98%     │
│                         │ • Backdoor user     │ (if APM enabled)    │
│                         │ • Disabled 2FA      │                     │
├─────────────────────────┼──────────────────────┼─────────────────────┤
│                         │                      │                     │
│ 📡 C2 CONTROL          │ Service → External   │ UNAUTHORIZED_FLOW   │
│    (Beaconing)          │ Periodic Heartbeat  │ + Pattern Detection │
│                         │                      │ Alert Fires: 15-30s │
│                         │ Maintains:          │ Severity: CRITICAL  │
│                         │ • Remote access     │                     │
│                         │ • Command channel   │ Confidence: 99%     │
│                         │ • Data control      │ (periodic pattern)  │
├─────────────────────────┼──────────────────────┼─────────────────────┤
│                         │                      │                     │
│ 🎁 SUPPLY CHAIN        │ Malicious Package   │ UNAUTHORIZED_FLOW   │
│   (Dependency Attack)   │ → External Server   │ + Process/Syscall   │
│                         │                      │ Alert Fires: 5-20s  │
│                         │ Injects:            │ Severity: CRITICAL  │
│                         │ • Backdoor code     │                     │
│                         │ • Spawn shell       │ Confidence: 95%+    │
│                         │ • Exfiltrate data   │ (if auditd enabled) │
│                         │                      │                     │
└─────────────────────────┴──────────────────────┴─────────────────────┘
```

---

## Detection Layer Analysis

### eBPF Network Monitoring (Layer 1)

**Strengths:**
```
✅ Detects external connections (most attacks start here)
✅ 5-15 second detection latency
✅ Very low false positive rate
✅ Works on ANY service (no instrumentation needed)
✅ Catches both encrypted and unencrypted traffic
```

**Weaknesses:**
```
❌ Cannot see INSIDE encrypted connections
❌ Cannot distinguish legitimate from malicious queries
❌ Limited context about what data was accessed
❌ Needs baseline to work effectively
```

**Best For:**
```
🎯 Exfiltration attempts
🎯 C2 communication
🎯 Network scanning
🎯 Supply chain attacks
```

---

### Database Audit Logging (Layer 2)

**Strengths:**
```
✅ Sees EXACT queries (SELECT * FROM customers)
✅ Detects data access patterns (who, what, when)
✅ Catches privilege escalation attempts
✅ 1-5 second detection latency
```

**Weaknesses:**
```
❌ Only works if query patterns baseline exists
❌ Can generate massive log volumes
❌ Encrypted at-rest data is still encrypted
❌ Need to encrypt sensitive columns
```

**Best For:**
```
🎯 Unauthorized data access
🎯 Data exfiltration detection
🎯 Compliance auditing (GDPR, PCI-DSS)
🎯 Insider threats
```

---

### Application Monitoring (Layer 3)

**Strengths:**
```
✅ Sees API calls and parameters
✅ Detects behavioral changes (latency, errors)
✅ Understands application context
✅ 5-30 second detection latency
✅ Can auto-instrument (no code changes)
```

**Weaknesses:**
```
❌ Performance overhead (1-5% CPU impact)
❌ Requires API gateway or instrumentation
❌ May miss things outside API scope
❌ Configuration complexity
```

**Best For:**
```
🎯 Privilege escalation (API call patterns)
🎯 Behavioral anomalies
🎯 Latency analysis
🎯 Performance degradation
```

---

### Process Monitoring (Layer 4)

**Strengths:**
```
✅ Detects process spawning (shells, reverse shells)
✅ Sees system calls (open(), connect(), execve())
✅ Catches shellcode injection
✅ 1-5 second detection latency
```

**Weaknesses:**
```
❌ Can be noisy on development systems
❌ Needs tuning to reduce false positives
❌ May miss attacks NOT using new processes
❌ Requires auditd or similar (additional overhead)
```

**Best For:**
```
🎯 Supply chain attacks (process spawning)
🎯 Shellcode injection
🎯 Persistence attempts
🎯 Unusual system calls
```

---

## Attack Detection Heatmap

```
Attack Type              Layer 1(eBPF)  Layer 2(DB)  Layer 3(APM)  Layer 4(Proc)
─────────────────────────────────────────────────────────────────────────────
1. Exfiltration              🔴🔴🔴      🟡🟡       ⚠️           🟡
2. Lateral Movement          🟢🟢🟢      ⚠️         ⚠️           🟢
3. Data Theft               🟡🟡         🔴🔴🔴     ⚠️           ⚠️
4. Privilege Escalation      🟡           🟡         🔴🔴🔴      🟡
5. C2 Control               🔴🔴🔴      ⚠️         ⚠️           🟡
6. Supply Chain             🔴🔴        ⚠️         ⚠️           🔴🔴🔴

Legend:
🔴🔴🔴 = Excellent detection (primary)
🟢🟢🟢 = Strong detection
🟡🟡   = Moderate detection
⚠️    = Weak detection (needs tuning)
❌    = Cannot detect at this layer
```

---

## Attack Timeline Comparison

```
ATTACK 1: Exfiltration
┌────────────────────────────────────────────────────────────┐
│ T+0s   Account Service spawns malicious thread             │
│ T+0.1s Socket connects to 192.168.1.99:443                │
│ ├──────→ eBPF CAPTURES event                               │
│ T+1s    eBPF log written to JSONL                          │
│ T+1s    Prometheus exporter reads log                      │
│ T+6s    Prometheus scraper detects metric increase         │
│ T+11s   Alert rule fires "UNAUTHORIZED_FLOW"              │
│ T+16s   Grafana shows RED alert                            │
│ T+20s   Security team notified                             │
│ T+45s   Response: Kill process, preserve logs, restore     │
│                                                             │
│ DETECTION TIME: ~11 seconds                                │
│ COMPROMISE WINDOW: ~45 seconds                             │
│ DATA LOSS: ~10GB (many keys exfiltrated in 45s)           │
└────────────────────────────────────────────────────────────┘

ATTACK 2: Network Scanning
┌────────────────────────────────────────────────────────────┐
│ T+0s   Account Service starts port scanning                │
│ T+0.1s Port 8000 probed                                    │
│ T+0.2s Port 8001 probed                                    │
│ ...continues...                                             │
│ T+2s    80 ports probed in burst                            │
│ ├──────→ eBPF CAPTURES all events                           │
│ T+2s    Pattern analysis: HIGH_FANOUT                       │
│ T+7s    Prometheus scrapes metrics                          │
│ T+12s   Alert rules fire: "HIGH_FANOUT" + "LATERAL_MOVE"  │
│ T+17s   Grafana shows CRITICAL alerts                       │
│ T+20s   Security team notified                             │
│ T+45s   Response: Kill process, audit for compromise       │
│                                                             │
│ DETECTION TIME: ~12 seconds                                │
│ COMPROMISE WINDOW: ~45 seconds                             │
│ EXPOSURE: Other 2 services discovered and probed           │
└────────────────────────────────────────────────────────────┘

ATTACK 3: Data Theft (eBPF Only)
┌────────────────────────────────────────────────────────────┐
│ T+0s   Account Service queries: SELECT * FROM customers    │
│ T+0.5s Query executes (DB doesn't raise alarm yet)         │
│ T+1s    Second query executes                              │
│ ...continues...                                             │
│ T+20s   20 queries executed, 5GB downloaded                │
│ ├──────→ eBPF sees SLOW_CONNECT alerts                      │
│ T+25s   SLOW_CONNECT triggers                              │
│ T+30s   Prometheus updates metrics                          │
│ T+35s   Alert rule fires: "SLOW_CONNECT" (MEDIUM)         │
│ T+40s   Grafana shows alert (not as obvious)               │
│ T+60s   Security team notices and responds                 │
│                                                             │
│ DETECTION TIME: ~35 seconds (eBPF only)                    │
│ DETECTION TIME: ~1 second (with DB layer!)                 │
│ DATA LOSS: 5GB without DB monitoring!                       │
│                                                             │
│ ⚠️  THIS SHOWS WHY MULTI-LAYER DEFENSE IS CRITICAL!        │
└────────────────────────────────────────────────────────────┘

ATTACK 4: Privilege Escalation
┌────────────────────────────────────────────────────────────┐
│ T+0s   Account Service connects to Auth Service             │
│ T+0.1s POST /api/admin/create-user sent                    │
│ ├──────→ eBPF CAPTURES network flow                         │
│ ├──────→ APM CAPTURES API call                              │
│ T+1s    Response received: 201 Created (backdoor added!)    │
│ T+6s    Prometheus metrics update                           │
│ T+11s   Alert fires: "UNAUTHORIZED_FLOW" (eBPF)           │
│ T+5s    APM alert fires: "Anomalous API call" (if enabled) │
│ T+16s   Grafana shows alerts                                │
│ T+20s   Security team notified                             │
│ T+45s   Response: Revoke access, kill session, rotate keys │
│                                                             │
│ DETECTION TIME: ~5-11 seconds                              │
│ COMPROMISE WINDOW: ~45 seconds                             │
│ DAMAGE: Attacker has admin account (critical!)              │
│                                                             │
│ ⚠️  Backdoor account allows future attacks                  │
└────────────────────────────────────────────────────────────┘

ATTACK 5: C2 Beaconing
┌────────────────────────────────────────────────────────────┐
│ T+0s   Account Service calls out to C2 (beacon #1)         │
│ ├──────→ eBPF CAPTURES connection                           │
│ T+1s    Exporter reads JSONL                               │
│ T+6s    Prometheus scrapes metrics                          │
│ T+11s   Alert fires: "UNAUTHORIZED_FLOW"                   │
│ T+16s   Grafana shows alert                                │
│ T+20s   Security team notified                             │
│                                                             │
│ T+30s  Account Service calls out to C2 (beacon #2)         │
│ ├──────→ Pattern detected: PERIODIC C2                     │
│ T+36s  Alert elevates to CRITICAL: "C2_BEACONING"         │
│ T+41s  Second notification sent                            │
│ T+60s  Security team takes action                          │
│                                                             │
│ DETECTION TIME: ~11 seconds (first beacon)                │
│ DETECTION TIME: ~25 seconds (identified as C2)            │
│ COMPROMISE WINDOW: Months (if not detected immediately!)   │
│                                                             │
│ ⚠️  This is why behavioral analysis is important!          │
└────────────────────────────────────────────────────────────┘

ATTACK 6: Supply Chain
┌────────────────────────────────────────────────────────────┐
│ T+0s   Malicious dependency loaded on service startup      │
│ T+0.1s Spawns reverse shell: /bin/bash                     │
│ ├──────→ eBPF CAPTURES external connection                  │
│ ├──────→ auditd CAPTURES process spawn                      │
│ T+0.5s Shell connects back to attacker C2                  │
│ T+1s    Exporter + auditd log events                       │
│ T+6s    Prometheus scrapes metrics                          │
│ T+11s   Multiple alerts fire:                              │
│         • "UNAUTHORIZED_FLOW" (eBPF)                       │
│         • "UNEXPECTED_PROCESS_SPAWN" (auditd)             │
│ T+16s   Grafana shows CRITICAL alerts                       │
│ T+20s   Security team notified (multiple channels)         │
│ T+45s   Response: Kill service, trace impact, rebuild      │
│                                                             │
│ DETECTION TIME: ~11 seconds                                │
│ COMPROMISE WINDOW: ~45 seconds                             │
│ EXPOSURE: Entire database and credentials exposed          │
│                                                             │
│ ✅ Multi-layer detection (eBPF + auditd) is CRITICAL       │
└────────────────────────────────────────────────────────────┘
```

---

## Summary Matrix

```
┌──────────────────┬─────────┬────────┬──────────┬──────────┬────────────┐
│ Attack Type      │ Time    │ Impact │ eBPF     │ DB Auth  │ Process    │
│                  │ to      │        │ Layer    │ Layer    │ Layer      │
│                  │ Detect  │        │          │          │            │
├──────────────────┼─────────┼────────┼──────────┼──────────┼────────────┤
│ 1. Exfiltration  │ 5-10s   │ HIGH   │ 🔴 BEST  │ Good     │ Good       │
├──────────────────┼─────────┼────────┼──────────┼──────────┼────────────┤
│ 2. Scanning      │ 5-15s   │ HIGH   │ 🔴 BEST  │ N/A      │ Good       │
├──────────────────┼─────────┼────────┼──────────┼──────────┼────────────┤
│ 3. Data Theft    │ 1-5s*   │ CRIT   │ Medium   │ 🔴 BEST  │ N/A        │
│                  │ 35s     │        │          │          │            │
│                  │ (eBPF)  │        │          │          │            │
├──────────────────┼─────────┼────────┼──────────┼──────────┼────────────┤
│ 4. Privilege Esc │ 5-11s   │ CRIT   │ Good     │ Good     │ 🔴 BEST    │
├──────────────────┼─────────┼────────┼──────────┼──────────┼────────────┤
│ 5. C2 Beaconing  │ 15-30s  │ CRIT   │ 🔴 BEST  │ N/A      │ Medium     │
├──────────────────┼─────────┼────────┼──────────┼──────────┼────────────┤
│ 6. Supply Chain  │ 5-20s   │ CRIT   │ Good     │ Good     │ 🔴 BEST    │
│                  │         │        │          │          │            │
└──────────────────┴─────────┴────────┴──────────┴──────────┴────────────┘

* With ALL layers: 1-5 seconds
* With eBPF only: 35 seconds
```

---

## Key Takeaway

```
╔════════════════════════════════════════════════════════════════════╗
║                    DEFENSE-IN-DEPTH WORKS                          ║
╠════════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Single Layer Detection Times:                                    ║
║  ├─ eBPF Network:            5-35 seconds                         ║
║  ├─ Database Audit:          1-5 seconds                          ║
║  ├─ Application APM:         5-30 seconds                         ║
║  └─ Process Monitoring:      1-5 seconds                          ║
║                                                                    ║
║  Attack Window: 45-60 seconds                                     ║
║                                                                    ║
║  With ALL layers:                                                 ║
║  ✅ Minimum detection time: 1-5 seconds                          ║
║  ✅ Maximum data loss: ~10GB (limited)                           ║
║  ✅ Attacker impact: MINIMAL                                     ║
║                                                                    ║
║  With ONLY eBPF:                                                  ║
║  ❌ Detection time: 5-35 seconds (varies by attack)              ║
║  ❌ Data loss: Can be significant                                ║
║  ❌ Harder to prove source of compromise                         ║
║                                                                    ║
║  ➡️  RECOMMENDATION: Layer all 4 detection methods               ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
```
