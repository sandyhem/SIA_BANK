# eBPF Attack Simulation Quick Start

## Quick Commands

### Run All Attacks Automatically
```bash
cd /home/inba/SIA_BANK

# Start the interactive simulator
./simulate-attack-scenarios.sh

# Then select option "7" to run all attacks
```

### Run Specific Attack Scenarios
```bash
# Start the simulator
./simulate-attack-scenarios.sh

# Select from menu:
# 1 - Compromised Service Exfiltration
# 2 - Network Scanning & Lateral Movement
# 3 - Unauthorized Data Access
# 4 - Privilege Escalation
# 5 - Command & Control (C2)
# 6 - Supply Chain Attacks
```

---

## Attack Scenarios Explained

### 1️⃣ Compromised Service Exfiltration

**What it simulates**: A compromised Account Service trying to steal encryption keys

**Attack steps**:
- Account Service connects to attacker C2 server (192.168.1.99:443)
- Attempts to exfiltrate ML-KEM private keys
- Makes multiple connection attempts to different attacker IPs

**Expected eBPF Detection**:
```
ALERT: UNAUTHORIZED_FLOW
Message: "Unexpected service flow account-service -> unknown:443"
Severity: HIGH
```

**Dashboard Impact**:
- 🔴 "Unauthorized Flow" panel turns RED
- Alert count increases
- Grafana notification fires

**Real-World Scenario**: Log4Shell, SQL injection, RCE vulnerabilities allow attacker to inject malicious code

---

### 2️⃣ Lateral Movement & Network Scanning

**What it simulates**: Compromised service trying to find other vulnerable microservices

**Attack steps**:
- Account Service scans 30 ports (8000-8030) on localhost
- Probes transaction-service, auth-service, database
- Sends malicious payloads to test vulnerabilities
- All within 2 seconds

**Expected eBPF Detection**:
```
ALERT: HIGH_FANOUT (too many connections to different services)
Message: "Process account-service contacted too many peers"
Severity: CRITICAL

ALERT: LATERAL_MOVEMENT_PATTERN (rapid burst of connections)
Message: "Burst of unauthorized communications"
```

**Dashboard Impact**:
- 🔴 "High Fanout Activity" panel turns RED
- 🔴 "Lateral Movement" panel turns RED
- Multiple alerts firing

**Real-World Scenario**: Attacker uses compromised service as pivot point to attack other services

---

### 3️⃣ Unauthorized Data Access (PII Theft)

**What it simulates**: Malicious code reading all customer data from database

**Attack steps**:
- Account Service executes 20 database queries in 3 seconds
- Queries retrieve all customers with balance > $1000
- Each query takes 200-800ms (vs typical 10-50ms)
- Simulates exfiltration of PII (names, SSNs, account numbers)

**Expected eBPF Detection**:
```
ALERT: SLOW_CONNECT
Message: "Connection to database taking 800ms (baseline 10ms)"
Severity: MEDIUM
```

**Database Level Detection** (if enabled):
```
SELECT * FROM customers WHERE balance > 100000
├─ Unusual: Should be SELECT specific_columns
├─ Unusual: Account has read-only on limited customer set
├─ Unusual: 3 AM execution time
└─ ALERT: Anomalous query pattern
```

**Real-World Scenario**: GDPR violations, identity theft, fraud ring operations

---

### 4️⃣ Privilege Escalation via Unauthorized API

**What it simulates**: Service attempting to create backdoor admin accounts

**Attack steps**:
- Account Service connects to Auth Service
- Sends: `POST /api/admin/create-user` with backdoor credentials
- Connects to Transaction Service
- Sends: `PATCH /api/transaction/rules/disable` to turn off fraud detection
- Two-phase attack: create access + disable safeguards

**Expected eBPF Detection**:
```
ALERT: UNAUTHORIZED_FLOW
Message: "Unexpected connection account-service -> auth-service"
Severity: MEDIUM

ALERT: PROCESS_PORT_MISMATCH
Message: "Service accessing endpoints outside normal baseline"
Severity: MEDIUM
```

**Application Level Detection** (if APM enabled):
```
POST /api/admin/create-user
├─ Not in Account Service's baseline APIs
├─ Admin endpoint being called by non-admin service
└─ ALERT: Anomalous API call pattern
```

**Real-World Scenario**: Account Service takes full control of Auth Service, locks out legitimate admins

---

### 5️⃣ Command & Control (C2) Communication

**What it simulates**: Attacker maintaining persistent access via periodic beacons

**Attack steps**:
- Account Service initiates heartbeat to C2 server (203.0.113.42:443)
- Sends: `ALIVE:account-service:PID-1234`
- Makes 3 beacon attempts at ~10 second intervals
- C2 can send back commands (exfiltrate, spread, persist)

**Expected eBPF Detection**:
```
ALERT: UNAUTHORIZED_FLOW
Message: "Unexpected external connection to 203.0.113.42:443"
Severity: HIGH

+ Repeated connections to same external IP
+ Periodic pattern detected (10s intervals)
= Indicates C2 CONTROL
```

**Behavioral Pattern**:
- First connection: 5-10 seconds (initial beacon)
- Second connection: 15-20 seconds (second beacon)
- Third connection: 25-30 seconds (third beacon)
- Pattern clearly shows **C2 heartbeat**, not legitimate traffic

**Real-World Scenario**: Attacker maintains access to banking system for months, waits for right moment to execute theft

---

### 6️⃣ Supply Chain Attack (Malicious Dependency)

**What it simulates**: Compromised Maven/NPM package injecting malicious code

**Attack steps**:
- Malicious Maven dependency (e.g., `com.attacker:stolen-utils:1.0.0`)
- Automatically executes on Account Service startup
- Connects to `malicious-pkg-mirror.com:443`
- Exfiltrates: Spring config, database credentials, API keys
- Attempts to spawn reverse shell for remote access
- All happening silently in background

**Expected eBPF Detection**:
```
ALERT: UNAUTHORIZED_FLOW
Message: "Unexpected connection to malicious-pkg-mirror.com:443"
Severity: CRITICAL
```

**Process Level Detection** (if auditd enabled):
```
java (Account Service) spawning: /bin/bash -i >& /dev/tcp/...
├─ Unexpected: Banking service should not spawn shells
├─ Suspicious: Reverse shell command pattern detected
└─ ALERT: Malicious process injection detected
```

**Context**:
- This is why **dependency scanning** is critical
- Tools: Snyk, Dependabot, GitHub Security scanning
- Watch: `log4j`, `jackson-databind`, `protobuf-java` (real vulnerabilities)

**Real-World Scenario**: 
- Attacker compromises a small utility library on Maven Central
- 10,000+ companies' databases exposed
- Attacker backdoors infrastructure for months before discovery

---

## Monitoring & Response

### Watch in Real-Time

**Terminal 1: Watch eBPF Events**
```bash
tail -f /home/inba/SIA_BANK/logs/ebpf-scenarios.jsonl | grep -E "(ALERT|alert|UNAUTHORIZED|lateral)"
```

**Terminal 2: Monitor Prometheus**
```bash
# Query metrics
curl -s http://localhost:9090/api/v1/query?query=ebpf_alerts_total | jq '.data.result[] | {metric: .metric.alertType, value: .value[1]}'
```

**Browser: Watch Grafana Live Updates**
```
http://localhost:3000
Dashboard: eBPF Security Overview
Refresh: Auto-refresh enabled
```

### Response Timeline

For Attack 1 (Exfiltration):
```
T+0s:   Account Service attempts connection to 192.168.1.99:443
        └─ eBPF tracepoint captures event

T+1s:   eBPF exporter reads JSONL log

T+2s:   Prometheus scrapes metrics
        └─ ebpf_alerts_total increases
        └─ ebpf_unauthorized_flow increases

T+5s:   Alert rule fires
        └─ UnauthorizedFlowBurst: HIGH severity

T+10s:  Dashboard updates
        └─ "Unauthorized Flow" panel: RED
        └─ "Alert List" shows new alerts

T+15s:  Notification sent
        └─ Slack alert (if configured)
        └─ PagerDuty incident (if configured)

T+30s:  Security team response
        □ Kill Account Service process
        □ Review eBPF logs for details
        □ Check for data exfiltration
        □ Restore from backup
        □ Patch vulnerability
```

---

## Success Indicators

### During Attack Simulation:

✅ **Prometheus metrics increase**
```bash
curl http://localhost:9090/api/v1/query?query=ebpf_events_total
# Result: [1200, 1250, 1300, ...] (number increases)
```

✅ **Grafana dashboard shows RED alerts**
- "Unauthorized Flow" panel
- "High Fanout Activity" panel  
- "Lateral Movement" panel
- "Active Alerts" list shows recent alerts

✅ **eBPF logs show events**
```bash
tail -f logs/ebpf-scenarios.jsonl
# Events show: source, destination, type, alerts
```

✅ **Alert rules fire**
- Check Prometheus Alerts tab: http://localhost:9090/alerts
- Look for state: `FIRING`
- Severity: `critical`, `high`, `medium`

---

## Advanced: Understand the Detection Chain

### Data Flow During Attack:

```
Attacker Action
    ↓
Malicious Code Executes
    ↓
System Call (socket(), connect(), send())
    ↓
eBPF Tracepoint Probe (sock:inet_sock_set_state)
    ↓
JSONL Log File
    ↓
Prometheus Exporter (reads JSONL every 10s)
    ↓
Prometheus Metrics Endpoint (:9110/metrics)
    ↓
Prometheus Scraper (pulls every 5s)
    ↓
Alert Rules Evaluation (every 5s)
    ↓
Alert Condition Match
    ↓
ALERT FIRING
    ↓
Grafana Datasource Query (Prometheus)
    ↓
Dashboard Update (real-time)
    ↓
Visual Alert (RED panels, notifications)
```

**Total Detection Time: 5-20 seconds**

---

## What's Next?

### Add Database Layer Detection

```bash
# Enable PostgreSQL audit logging
echo "log_statement = 'all'" >> /etc/postgresql/.../postgresql.conf
systemctl restart postgresql

# Now detect:
- SELECT * FROM customers (full table scans)
- Unusual time patterns (3 AM queries)
- Data access anomalies
```

### Add Application Monitoring (APM)

```bash
# Use DataDog, New Relic, or Elastic APM
# Detect:
- Unusual API endpoints called
- Request patterns changed
- Response sizes anomalous
- Function call chains suspicious
```

### Add Process Monitoring

```bash
# Enable auditd for system calls
auditctl -w /path/to/services -p wa -k service_changes

# Detect:
- Unexpected process spawning (bash from Java)
- File system modifications
- Privilege changes
```

---

## Testing Checklist

Before using in production:

- [ ] eBPF monitor starts without errors
- [ ] Prometheus scrapes metrics successfully
- [ ] Grafana connects to Prometheus datasource
- [ ] Baseline alerts set (no false positives)
- [ ] Team trained on alert response
- [ ] Incident response playbook created
- [ ] Automated response mechanisms tested
- [ ] Backup and restore tested
- [ ] Performance impact measured (<5% CPU overhead)

---

## Troubleshooting

### No alerts showing in Grafana?
```bash
# Check datasource
curl -s http://localhost:3000/api/datasources | jq '.[0]' 

# Check Prometheus has data
curl http://localhost:9090/api/v1/query?query=ebpf_events_total

# Check alert rules loaded
curl http://localhost:9090/api/v1/rules | jq '.data.groups'
```

### eBPF monitor not capturing events?
```bash
# Check if running
pgrep -f monitor_runtime

# Check logs
tail -f /tmp/monitor.log

# Check permissions
whoami  # Should be root or use sudo
```

### Prometheus not scraping metrics?
```bash
# Check exporter
curl http://localhost:9110/metrics | head -20

# Check Prometheus config
docker exec sia-prometheus cat /etc/prometheus/prometheus.yml | grep -A 5 "job_name"

# Check target status
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[]'
```

---

## Summary

You now have a **complete attack simulation framework** that:

✅ Simulates 6 real-world attack scenarios  
✅ Demonstrates eBPF detection in action  
✅ Shows multi-layer defense benefits  
✅ Provides live Grafana visualization  
✅ Generates alert rules automatically  

Use this to:
- Train your security team
- Test your response procedures  
- Validate detection rules
- Demonstrate security value to stakeholders
