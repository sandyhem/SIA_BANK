#!/bin/bash

# Quick Start - MITM Detection on This System
# Wait for attacks from external devices

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "    🛡️  MITM ATTACK DETECTION - Monitoring Mode"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Target System: 10.220.184.64"
echo "Interface:     wlp0s20f3 (WiFi)"
echo "Gateway:       10.220.184.57"
echo ""
echo "Waiting for attacks from external devices..."
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

cd /home/inba/SIA_BANK

# Activate virtual environment
source mitm_venv/bin/activate

# Start detector in background
echo "[1/3] Starting MITM detector..."
sudo -E python3 ebpf/detect_mitm_attacks.py \
    --interface wlp0s20f3 \
    --output logs/mitm-attacks.jsonl \
    --verbose > /tmp/mitm-detector.log 2>&1 &

DETECTOR_PID=$!
echo "      ✅ Detector started (PID: $DETECTOR_PID)"
sleep 2

# Check if running
if ps -p $DETECTOR_PID > /dev/null; then
    echo "[2/3] Detector is active and monitoring"
    echo "[3/3] Watching for attacks..."
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "📊 Live Attack Alerts:"
    echo ""
    
    # Monitor log file
    touch logs/mitm-attacks.jsonl
    tail -f logs/mitm-attacks.jsonl | while read line; do
        if [ -n "$line" ]; then
            echo "$line" | jq -r '
                "🚨 \(.attack_type // "ALERT")",
                "   Time:     \(.timestamp // "N/A")",
                "   Attacker: \(.attacker_ip // "Unknown") (\(.attacker_mac // "Unknown"))",
                "   Severity: \(.severity // "N/A")",
                "   Action:   \(.action // "Monitor")",
                ""
            ' 2>/dev/null || echo "$line"
        fi
    done
else
    echo ""
    echo "❌ Error: Detector failed to start"
    echo "Check logs: cat /tmp/mitm-detector.log"
    exit 1
fi
