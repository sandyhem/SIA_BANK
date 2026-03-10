# How eBPF Works - Your Questions Answered

## ❓ Your Questions:

1. **You are not running the services** - How is it possible?
2. **What are the events and how is it increasing**?
3. **Without starting the services, how is it creating the attack**?

---

## ✅ ANSWER: The Data You Saw Was OLD (Stale)

### Current Reality:
```
❌ Banking services (auth/account/transaction): NOT RUNNING
❌ eBPF monitor: NOT RUNNING  
❌ Attack simulator: NOT RUNNING
✅ Prometheus exporter: RUNNING - reading OLD log file from 7 minutes ago
```

**The 1,227 events you saw in Grafana were from a PREVIOUS run!**

- Log file last modified: **22:18** (7 minutes before you looked)
- Current time when you checked: **22:25**
- Data is **STALE** - not live

---

## 🔍 How eBPF Actually Works

### 1. What eBPF Monitors

eBPF captures **ALL TCP connections** on your

 entire Linux system, **NOT just banking services**:

```
┌─────────────────────────────────────────────────────┐
│           YOUR LINUX SYSTEM                         │
│                                                     │
│  🌐 Chrome/Firefox → websites                       │
│  🔐 SSH → remote servers                            │
│  📦 apt/yum → package repositories                  │
│  💻 VS Code → remote extensions                     │
│  🐳 Docker → container networking                   │
│  ⚙️  systemd → system services                      │
│  🏦 Banking services → auth/account/transaction     │
│                                                     │
│         ↓ ALL TCP connections captured ↓           │
│                                                     │
│  ╔═══════════════════════════════════════════╗     │
│  ║    eBPF Monitor (Kernel Level)            ║     │
│  ║  Tracepoint: sock:inet_sock_set_state     ║     │
│  ╚═══════════════════════════════════════════╝     │
└─────────────────────────────────────────────────────┘
```

**Key Point**: Even without banking services, eBPF captures:
- Your web browser connections
- System update checks
- SSH sessions
- Docker container traffic
- **ANY application making TCP connections**

---

### 2. What Events Look Like

When captured, each event includes:

```json
{
  "timestamp": "2026-03-04T16:48:22.887856+00:00",
  "pid": 12345,
  "comm": "chrome",                    ← Process name
  "sourceIP": "192.168.1.100",
  "sourcePort": 54321,
  "destinationIP": "142.250.185.78",
  "destinationPort": 443,
  "sourceService": "unknown:54321",    ← Not in policy = "unknown"
  "destinationService": "unknown:443",
  "alerts": []                         ← Normal traffic = no alerts
}
```

**"unknown" means**: The connection doesn't match any service in `service_map.json` policy.

---

### 3. How The Attack Simulation Works

#### **WITHOUT Attack Simulator**:
```
Normal System Traffic:
  chrome → google.com:443
  firefox → github.com:443
  ssh → server.com:22

eBPF captures these, but NO alerts (normal traffic)
```

#### **WITH Attack Simulator**:
```python
# simulate_unwanted_behavior.py does 3 things:

1. Starts rogue service on port 19090
   python3 listening on port 19090
   BUT policy expects: java on port 19090
   → PROCESS_PORT_MISMATCH alert!

2. Creates 80 rapid connections (burst)
   python3 → localhost:19090 (repeat 80 times in 2ms intervals)
   → LATERAL_MOVEMENT_PATTERN alert! (burst ≥ 3)

3. Connections to unregistered service
   → UNAUTHORIZED_FLOW alert!
```

---

## 📊 Complete Data Flow

```
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: eBPF Monitor (MUST RUN AS ROOT)                     │
│                                                              │
│  $ sudo python3 ebpf/monitor_runtime.py                     │
│                                                              │
│  ↓ Captures TCP events from kernel                          │
│  ↓ Analyzes against policy (service_map.json)               │
│  ↓ Writes to: logs/ebpf-attack-demo.jsonl                   │
│                                                              │
│  Example output:                                             │
│  {"timestamp":"...","pid":123,"comm":"chrome",...}           │
│  {"timestamp":"...","pid":456,"comm":"python3",...}}         │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 2: Attack Simulator (OPTIONAL - for testing)           │
│                                                              │
│  $ python3 ebpf/simulate_unwanted_behavior.py               │
│                                                              │
│  Creates suspicious traffic patterns:                        │
│  • Rogue service (wrong process)                            │
│  • Burst connections (lateral movement)                     │
│  • Unauthorized flows                                        │
│                                                              │
│  These get captured by Step 1 and trigger alerts            │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 3: Prometheus Exporter                                 │
│                                                              │
│  $ ./start-ebpf-exporter.sh                                 │
│                                                              │
│  ↓ Reads: logs/ebpf-attack-demo.jsonl                       │
│  ↓ Converts to Prometheus metrics format                    │
│  ↓ Exposes on: http://localhost:9110/metrics                │
│                                                              │
│  Example metrics:                                            │
│  ebpf_events_total 1227                                      │
│  ebpf_alerts_by_type_total{type="LATERAL_MOVEMENT"} 147     │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 4: Prometheus (Docker)                                 │
│                                                              │
│  Scrapes http://localhost:9110/metrics every 5 seconds      │
│  Stores time-series data                                     │
│  Evaluates alert rules                                       │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 5: Grafana (Docker)                                    │
│                                                              │
│  Queries Prometheus                                          │
│  Displays dashboards with panels                             │
│  http://localhost:3000                                       │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎬 To See It ACTUALLY Work:

### Run This Interactive Demo:
```bash
cd /home/inba/SIA_BANK
./demo-how-ebpf-works.sh
```

This will:
1. ✅ Show current status (nothing running)
2. ✅ Start eBPF monitor
3. ✅ Capture normal system traffic (5 seconds)
4. ✅ Launch attack simulator
5. ✅ Show you the alerts in real-time
6. ✅ Explain how data flows to Grafana

---

## 🔑 Key Concepts

### 1. **Banking Services NOT Required**
- eBPF monitors **entire system**
- Sees Chrome, SSH, Docker, VS Code, etc.
- Banking services are just ONE type of traffic

### 2. **Events vs Alerts**
- **Event**: Any TCP connection (most are normal)
- **Alert**: Suspicious pattern detected
  - Example: 80 connections in 1 second = burst alert

### 3. **How Attacks Are Detected WITHOUT Running Banking Services**

The attack simulator creates its OWN traffic:
```python
# It doesn't need banking services!
# It creates a rogue server and connects to itself

RogueService().listen(port=19090)    # Start fake server
burst_connections(port=19090, count=80)  # Connect to itself 80 times

# This triggers alerts because:
# 1. python3 on port 19090 (expected: java) → MISMATCH
# 2. 80 rapid connections → LATERAL_MOVEMENT
# 3. Connections to non-policy service → UNAUTHORIZED_FLOW
```

### 4. **Stale Data Problem**
- Exporter reads the JSONL file from beginning
- If monitor stopped, file has old events
- Grafana shows old data
- **Solution**: Run `./demo-ebpf-attack.sh` to generate fresh data

---

## 📝 Summary Answering Your Questions

### Q1: "You are not running the services - how is it possible?"

**A**: The data was from a PREVIOUS run. The exporter was reading an old log file. eBPF doesn't need banking services - it captures ALL system TCP traffic.

### Q2: "What are the events and how is it increasing?"

**A**: Events are TCP connection metadata (PID, ports, IPs). They increase when:
- eBPF monitor is running (captures live traffic)
- ANY application makes TCP connections (browser, SSH, Docker, etc.)
- NOT just banking services!

### Q3: "Without starting the services, how is it creating the attack?"

**A**: The attack simulator creates its OWN traffic:
1. Starts a rogue Python server on port 19090
2. Makes 80 rapid connections to itself
3. This gets captured by eBPF and triggers alerts
4. **No banking services needed!**

---

## 🎯 Try It Now!

```bash
cd /home/inba/SIA_BANK

# Run interactive demo
./demo-how-ebpf-works.sh

# Or manual steps:
# 1. Start monitor (captures traffic for 30 seconds then stops)
sudo ./demo-ebpf-attack.sh &

# 2. Wait 10 seconds

# 3. Check Grafana
# http://localhost:3000
# Refresh dashboard - you'll see NEW events!
```

The monitor will capture traffic for 30 seconds, then automatically stop.
