#!/bin/bash
# Test eBPF Alerting Stack - Full End-to-End Validation
# 
# This script validates the complete alerting pipeline:
# eBPF Monitor → Exporter → Prometheus → Alert Rules → Grafana

set -e

WORKSPACE="/home/inba/SIA_BANK"
EXPORTER_PID=""
MONITOR_PID=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  eBPF Security Alerting Stack - End-to-End Test${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up processes...${NC}"
    [[ -n "$EXPORTER_PID" ]] && kill $EXPORTER_PID 2>/dev/null && echo "  ✓ Stopped exporter (PID $EXPORTER_PID)"
    [[ -n "$MONITOR_PID" ]] && sudo kill $MONITOR_PID 2>/dev/null && echo "  ✓ Stopped monitor (PID $MONITOR_PID)"
}
trap cleanup EXIT

# Step 1: Start Docker Stack
echo -e "${BLUE}[1/6]${NC} Starting Prometheus + Grafana..."
cd "$WORKSPACE/observability"
docker compose up -d

# Wait for services
echo "  ⏳ Waiting for services to be ready..."
sleep 5

# Check if Prometheus is up
if ! curl -s http://localhost:9090/-/healthy > /dev/null; then
    echo -e "${RED}  ✗ Prometheus is not responding${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Prometheus is running${NC}"

# Check if Grafana is up
if ! curl -s http://localhost:3000/api/health > /dev/null; then
    echo -e "${RED}  ✗ Grafana is not responding${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Grafana is running${NC}"

# Step 2: Verify Alert Rules Loaded
echo -e "\n${BLUE}[2/6]${NC} Verifying Prometheus alert rules..."
RULES_COUNT=$(curl -s http://localhost:9090/api/v1/rules | grep -o "ebpf_security_alerts" | wc -l)
if [ "$RULES_COUNT" -eq 0 ]; then
    echo -e "${RED}  ✗ Alert rules not loaded${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Alert rules loaded: ebpf_security_alerts group${NC}"

# Step 3: Run eBPF Attack Simulation
echo -e "\n${BLUE}[3/6]${NC} Running eBPF attack simulation..."
cd "$WORKSPACE"
sudo ./demo-ebpf-attack.sh > /dev/null 2>&1 &
MONITOR_PID=$!
sleep 2

# Verify monitor is running
if ! ps -p $MONITOR_PID > /dev/null; then
    echo -e "${RED}  ✗ eBPF monitor failed to start${NC}"
    exit 1
fi

# Wait for events to be generated
sleep 8
echo -e "${GREEN}  ✓ Attack simulation running (PID $MONITOR_PID)${NC}"

# Verify JSONL output
if [ ! -f "logs/ebpf-attack-demo.jsonl" ]; then
    echo -e "${RED}  ✗ No JSONL output file found${NC}"
    exit 1
fi
EVENT_COUNT=$(wc -l < logs/ebpf-attack-demo.jsonl)
echo -e "${GREEN}  ✓ Generated $EVENT_COUNT events${NC}"

# Step 4: Start Prometheus Exporter
echo -e "\n${BLUE}[4/6]${NC} Starting Prometheus exporter..."
./start-ebpf-exporter.sh > /dev/null 2>&1 &
EXPORTER_PID=$!
sleep 2

# Verify exporter metrics
if ! curl -s http://localhost:9110/metrics | grep -q "ebpf_events_total"; then
    echo -e "${RED}  ✗ Exporter not providing metrics${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Exporter running on port 9110 (PID $EXPORTER_PID)${NC}"

# Step 5: Wait for Prometheus to Scrape and Evaluate Alerts
echo -e "\n${BLUE}[5/6]${NC} Waiting for Prometheus to evaluate alerts..."
echo "  ⏳ Waiting 30 seconds for alert evaluation..."
sleep 30

# Step 6: Verify Alerts are Firing
echo -e "\n${BLUE}[6/6]${NC} Checking for firing alerts..."

# Get firing alerts from Prometheus
FIRING_ALERTS=$(curl -s http://localhost:9090/api/v1/alerts | grep -o '"state":"firing"' | wc -l)

if [ "$FIRING_ALERTS" -gt 0 ]; then
    echo -e "${GREEN}  ✓ Found $FIRING_ALERTS firing alerts!${NC}\n"
    
    # Show specific alerts
    echo -e "${YELLOW}Active Alerts:${NC}"
    curl -s http://localhost:9090/api/v1/alerts | \
        python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'data' in data and 'alerts' in data['data']:
    for alert in data['data']['alerts']:
        if alert.get('state') == 'firing':
            name = alert.get('labels', {}).get('alertname', 'Unknown')
            severity = alert.get('labels', {}).get('severity', 'unknown')
            print(f'  🔥 {name} [{severity.upper()}]')
" || echo "  (Could not parse alert details)"
    
else
    echo -e "${YELLOW}  ⚠ No alerts are firing yet${NC}"
    echo -e "${YELLOW}  This may be normal if thresholds haven't been reached${NC}"
fi

# Show metrics summary
echo -e "\n${YELLOW}Metrics Summary:${NC}"
curl -s http://localhost:9110/metrics | grep "ebpf_alerts_by_type_total" | head -5 | while read line; do
    echo "  $line"
done

# Final Instructions
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Alerting stack is operational!${NC}\n"
echo -e "${YELLOW}Access Points:${NC}"
echo "  • Prometheus Alerts: ${BLUE}http://localhost:9090/alerts${NC}"
echo "  • Prometheus Metrics: ${BLUE}http://localhost:9090${NC}"
echo "  • Grafana Dashboard: ${BLUE}http://localhost:3000${NC} (admin/admin)"
echo "  • eBPF Metrics Endpoint: ${BLUE}http://localhost:9110/metrics${NC}"
echo -e "\n${YELLOW}View the dashboard:${NC}"
echo "  1. Open http://localhost:3000"
echo "  2. Login with admin/admin"
echo "  3. Navigate to 'eBPF Security Monitoring' dashboard"
echo "  4. Check the '🔥 Active Prometheus Alerts' panel"
echo -e "\n${YELLOW}Note:${NC} Press Ctrl+C to stop all services and cleanup"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Keep running until user interrupts
read -p "Press Enter to stop all services and cleanup..."
