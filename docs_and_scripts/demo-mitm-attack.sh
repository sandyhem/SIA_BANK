#!/bin/bash

# MITM Attack Detection and Prevention Demo
# This script simulates MITM attacks and runs the detector simultaneously

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
EBPF_DIR="$PROJECT_ROOT/ebpf"
LOGS_DIR="$PROJECT_ROOT/logs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
ROUTE_INFO="$(ip route get 1.1.1.1 2>/dev/null || true)"
DEFAULT_IFACE="$(echo "$ROUTE_INFO" | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
DEFAULT_SRC_IP="$(echo "$ROUTE_INFO" | awk '/src/ {for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
DEFAULT_GW_IP="$(ip route show default 2>/dev/null | awk '/default/ {for(i=1;i<=NF;i++) if($i=="via"){print $(i+1); exit}}')"

INTERFACE="${MITM_INTERFACE:-${DEFAULT_IFACE:-eth0}}"
TARGET_IP="${MITM_TARGET_IP:-${DEFAULT_SRC_IP:-127.0.0.1}}"
GATEWAY_IP="${MITM_GATEWAY_IP:-${DEFAULT_GW_IP:-192.168.1.1}}"
ATTACK_TYPE="${1:-all}"
DURATION="${2:-30}"

mkdir -p "$LOGS_DIR"

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}ERROR: Must run as root${NC}"
    echo "Try: sudo $0"
    exit 1
fi

# Check dependencies
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: python3 not found${NC}"
    exit 1
fi

if ! python3 -c "import scapy" 2>/dev/null; then
    echo -e "${YELLOW}Installing Scapy...${NC}"
    pip3 install scapy --quiet
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  MITM Attack Detection & Prevention Demo${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Configuration:${NC}"
echo "  Interface: $INTERFACE"
echo "  Target IP: $TARGET_IP"
echo "  Attack Type: $ATTACK_TYPE"
echo "  Duration: ${DURATION}s"
echo ""

# Function to cleanup
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping all processes...${NC}"
    pkill -P $$ 2>/dev/null || true
    jobs -p | xargs -r kill 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

echo -e "${GREEN}[1/2] Starting MITM Attack Detector...${NC}"
python3 "$EBPF_DIR/detect_mitm_attacks.py" \
    --interface "$INTERFACE" \
    --output "$LOGS_DIR/mitm-attacks.jsonl" \
    --simulation-only \
    --duration $((DURATION + 10)) &
DETECTOR_PID=$!
echo -e "${GREEN}      PID: $DETECTOR_PID${NC}"

sleep 2

echo -e "${GREEN}[2/2] Starting MITM Attack Simulation...${NC}"
echo ""

# Run attack simulation
python3 "$EBPF_DIR/simulate_mitm_attacks.py" \
    --target "$TARGET_IP" \
    --gateway "$GATEWAY_IP" \
    --interface "$INTERFACE" \
    --attack-type "$ATTACK_TYPE" \
    --duration "$DURATION" \
    --output "$LOGS_DIR/mitm-simulation.jsonl"

# Give detector time to process
sleep 5

# Stop detector
if kill -0 $DETECTOR_PID 2>/dev/null; then
    kill $DETECTOR_PID 2>/dev/null || true
fi

# Display results
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Attack Detection Results${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

if [ -f "$LOGS_DIR/mitm-attacks.jsonl" ]; then
    echo -e "${YELLOW}Detected Attacks:${NC}"
    python3 - "$LOGS_DIR/mitm-attacks.jsonl" <<'PY'
import json
import sys

path = sys.argv[1]
count = 0
with open(path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            print(json.dumps(json.loads(line), indent=2))
            count += 1
            if count >= 5:
                break
        except json.JSONDecodeError:
            continue
PY
fi

echo ""
echo -e "${GREEN}Logs saved to:${NC}"
echo "  • Detector: $LOGS_DIR/mitm-attacks.jsonl"
echo "  • Simulator: $LOGS_DIR/mitm-simulation.jsonl"
echo ""

cleanup
