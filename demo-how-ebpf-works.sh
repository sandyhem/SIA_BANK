#!/bin/bash
# Live Demo: How eBPF Captures Events and Detects Attacks
# This shows you exactly what happens when you run the monitoring system

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  eBPF Security Monitoring - LIVE DEMO                          ║"
echo "║  This will show you how events are captured in real-time       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check current status
echo "📍 STEP 1: Current System Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MONITOR_RUNNING=$(pgrep -f monitor_runtime || true)
SERVICES_RUNNING=$(pgrep -f "java.*auth-service" || true)

if [ -z "$MONITOR_RUNNING" ]; then
    echo "  ❌ eBPF Monitor: NOT RUNNING"
else
    echo "  ✅ eBPF Monitor: RUNNING (PID: $MONITOR_RUNNING)"
fi

if [ -z "$SERVICES_RUNNING" ]; then
    echo "  ❌ Banking Services: NOT RUNNING"
    echo "     ℹ️  eBPF will capture SYSTEM TRAFFIC instead"
else
    echo "  ✅ Banking Services: RUNNING"
fi

echo ""
echo "📍 STEP 2: What eBPF Monitors"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  eBPF captures ALL TCP connections on your Linux system:"
echo "  • Web browsers (Chrome, Firefox)"
echo "  • SSH connections"
echo "  • Docker containers"
echo "  • System services (systemd, etc.)"
echo "  • VS Code remote connections"
echo "  • Package managers (apt, yum)"
echo "  • AND your banking services (if running)"
echo ""
echo "  🔍 HOW: Uses Linux kernel tracepoint: sock:inet_sock_set_state"
echo "  📊 WHAT: Process name, PID, source/dest IP:port, timestamps"
echo "  🚫 CANNOT: Read encrypted data (only metadata)"
echo ""

echo "📍 STEP 3: Starting eBPF Monitor (requires sudo)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  This will capture network events for 15 seconds..."
echo ""
echo "  Press Enter to start (requires sudo password)..."
read

# Clear old log
rm -f logs/ebpf-attack-demo.jsonl
echo "  ✅ Cleared old log file"

# Start monitor in background
echo "  ⚡ Starting eBPF monitor..."
sudo python3 ebpf/monitor_runtime.py \
    --policy ebpf/service_map.json \
    --output logs/ebpf-attack-demo.jsonl \
    > logs/monitor-demo.log 2>&1 &
MONITOR_PID=$!

sleep 2

if ps -p $MONITOR_PID > /dev/null; then
    echo "  ✅ Monitor started (PID: $MONITOR_PID)"
else
    echo "  ❌ Failed to start monitor. Check logs/monitor-demo.log"
    exit 1
fi

echo ""
echo "📍 STEP 4: Monitor is Now Capturing Events"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Waiting 5 seconds to capture normal system traffic..."
sleep 5

EVENT_COUNT=$(wc -l < logs/ebpf-attack-demo.jsonl 2>/dev/null || echo "0")
echo "  📊 Captured so far: $EVENT_COUNT events from normal system activity"

if [ "$EVENT_COUNT" -gt 0 ]; then
    echo ""
    echo "  📝 Sample event (normal traffic):"
    tail -1 logs/ebpf-attack-demo.jsonl | python3 -c "
import sys, json
line = sys.stdin.read()
if line:
    e = json.loads(line)
    print(f\"     Process: {e['comm']} (PID: {e['pid']})\")
    print(f\"     Flow: {e['sourceService']} → {e['destinationService']}\")
    print(f\"     Alerts: {len(e.get('alerts',[]))} (normal traffic usually has 0)\")
" 2>/dev/null || echo "     (Could not parse event)"
fi

echo ""
echo "📍 STEP 5: Simulating Attack Traffic"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  The attack simulator will:"
echo "  1. Start a rogue service on port 19090 (wrong process)"
echo "  2. Create 80 rapid connections (burst pattern)"
echo "  3. This triggers LATERAL_MOVEMENT + PROCESS_PORT_MISMATCH alerts"
echo ""
echo "  Press Enter to launch attack..."
read

python3 ebpf/simulate_unwanted_behavior.py --count 80 --delay-ms 2 &
ATTACK_PID=$!

echo "  ⚡ Attack launched (PID: $ATTACK_PID)"
echo "  ⏳ Running attack for 3 seconds..."
sleep 3

echo ""
echo "📍 STEP 6: Attack Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL_EVENTS=$(wc -l < logs/ebpf-attack-demo.jsonl 2>/dev/null || echo "0")
LATERAL=$(grep -c "LATERAL_MOVEMENT_PATTERN" logs/ebpf-attack-demo.jsonl 2>/dev/null || echo "0")
MISMATCH=$(grep -c "PROCESS_PORT_MISMATCH" logs/ebpf-attack-demo.jsonl 2>/dev/null || echo "0")
UNAUTHORIZED=$(grep -c "UNAUTHORIZED_FLOW" logs/ebpf-attack-demo.jsonl 2>/dev/null || echo "0")

echo "  📊 Total Events Captured: $TOTAL_EVENTS"
echo "  🚨 Security Alerts:"
echo "     • LATERAL_MOVEMENT_PATTERN: $LATERAL"
echo "     • PROCESS_PORT_MISMATCH: $MISMATCH"
echo "     • UNAUTHORIZED_FLOW: $UNAUTHORIZED"

if [ "$LATERAL" -gt 0 ]; then
    echo ""
    echo "  📝 Example LATERAL_MOVEMENT alert:"
    grep "LATERAL_MOVEMENT_PATTERN" logs/ebpf-attack-demo.jsonl | tail -1 | python3 -c "
import sys, json
line = sys.stdin.read()
if line:
    e = json.loads(line)
    for alert in e.get('alerts', []):
        if alert['type'] == 'LATERAL_MOVEMENT_PATTERN':
            print(f\"     Type: {alert['type']}\")
            print(f\"     Severity: {alert['severity']}\")
            print(f\"     Message: {alert['message']}\")
            print(f\"     Count: {alert.get('count_last_minute', 'N/A')}\")
            break
" 2>/dev/null || echo "     (Could not parse alert)"
fi

# Stop monitor
echo ""
echo "  🛑 Stopping monitor..."
sudo kill $MONITOR_PID 2>/dev/null
wait $MONITOR_PID 2>/dev/null

echo ""
echo "📍 STEP 7: How This Flows to Grafana"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. eBPF Monitor → logs/ebpf-attack-demo.jsonl"
echo "        ↓"
echo "  2. Prometheus Exporter → reads JSONL, exposes metrics on :9110"
echo "        ↓"
echo "  3. Prometheus → scrapes :9110 every 5 seconds"
echo "        ↓"
echo "  4. Grafana → queries Prometheus, displays dashboards"
echo ""
echo "  Current exporter status:"
if ps aux | grep -q "[e]xport_prometheus_metrics"; then
    echo "     ✅ Exporter is running"
    METRICS_COUNT=$(curl -s http://localhost:9110/metrics 2>/dev/null | grep "^ebpf_events_total" | awk '{print $2}')
    echo "     📊 Exposed metrics: $METRICS_COUNT events"
else
    echo "     ❌ Exporter not running - start with: ./start-ebpf-exporter.sh"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  DEMO COMPLETE!                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "🎯 Key Takeaways:"
echo "  1. eBPF captures ALL TCP traffic, not just banking services"
echo "  2. Events are written to JSONL log file"
echo "  3. Attack simulator creates suspicious patterns"
echo "  4. Alerts fire when thresholds are exceeded"
echo "  5. Data flows: eBPF → JSONL → Exporter → Prometheus → Grafana"
echo ""
echo "📖 Log file: logs/ebpf-attack-demo.jsonl ($TOTAL_EVENTS events)"
echo "📊 View in Grafana: http://localhost:3000 (refresh dashboard)"
echo ""
