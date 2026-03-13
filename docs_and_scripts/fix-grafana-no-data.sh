#!/bin/bash
# Quick fix for Grafana showing no data

echo "=============================================="
echo "  Grafana No Data - Quick Fix"
echo "=============================================="
echo ""

# Check if exporter is running
if ! ps aux | grep -v grep | grep "export_prometheus_metrics" > /dev/null; then
    echo "❌ Prometheus exporter is NOT running!"
    echo "   Starting exporter..."
    cd /home/inba/SIA_BANK
    ./start-ebpf-exporter.sh &
    sleep 2
else
    echo "✅ Prometheus exporter is running"
fi

# Check if monitor/demo is running
if ! ps aux | grep -v grep | grep -E "monitor_runtime|demo-ebpf" > /dev/null; then
    echo "❌ eBPF monitor is NOT running (this is why no data appears!)"
    echo ""
    echo "Starting attack simulation to generate events..."
    cd /home/inba/SIA_BANK
    sudo ./demo-ebpf-attack.sh > /dev/null 2>&1 &
    DEMO_PID=$!
    
    echo "   Demo started (PID: $DEMO_PID)"
    echo "   Waiting 10 seconds for events..."
    sleep 10
    
    # Check if events are being generated
    EVENT_COUNT=$(wc -l < logs/ebpf-attack-demo.jsonl 2>/dev/null || echo "0")
    echo "   ✅ Generated $EVENT_COUNT total events"
else
    echo "✅ eBPF monitor is running"
fi

echo ""
echo "=============================================="
echo "  Checking Metrics"
echo "=============================================="

# Check exporter metrics
EVENTS=$(curl -s http://localhost:9110/metrics 2>/dev/null | grep "^ebpf_events_total" | awk '{print $2}')
ALERTS=$(curl -s http://localhost:9110/metrics 2>/dev/null | grep "^ebpf_alerts_total" | awk '{print $2}')

echo "Current metrics from exporter:"
echo "  - Events: $EVENTS"
echo "  - Alerts: $ALERTS"

# Check data age
LAST_UPDATE=$(curl -s http://localhost:9110/metrics 2>/dev/null | grep "^ebpf_exporter_last_update_seconds" | awk '{print $2}')
CURRENT_TIME=$(date +%s)
AGE=$((CURRENT_TIME - LAST_UPDATE))

echo "  - Data age: ${AGE} seconds old"

if [ "$AGE" -lt 30 ]; then
    echo "  ✅ Data is FRESH!"
else
    echo "  ⚠️  Data is stale (older than 30s)"
    echo "     Waiting for new events..."
    sleep 5
fi

echo ""
echo "=============================================="
echo "  Grafana Access"
echo "=============================================="
echo ""
echo "Open Grafana: http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "Dashboard: eBPF Security Monitoring"
echo ""
echo "⚡ IMPORTANT: Make sure time range is set to 'Last 15 minutes'"
echo "              or 'Last 5 minutes' in top-right corner!"
echo ""
echo "If still no data:"
echo "  1. Click the time picker (top right)"
echo "  2. Select 'Last 5 minutes'"
echo "  3. Click 'Apply'"
echo ""
echo "Data should now appear! 🎉"
echo ""
