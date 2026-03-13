#!/bin/bash

# Start complete eBPF monitoring stack for SIA_BANK
# This script launches both TCP and SSL/TLS monitors with observability integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
EBPF_DIR="$PROJECT_ROOT/ebpf"
LOGS_DIR="$PROJECT_ROOT/logs"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  SIA_BANK Complete eBPF Monitoring${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Create logs directory
mkdir -p "$LOGS_DIR"

# Parse options
MONITOR_TYPE="tcp"  # Default to TCP only (SSL/TLS monitor has kernel verifier issues with Java+BouncyCastle)
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssl)
            MONITOR_TYPE="both"
            shift
            ;;
        --tcp-only)
            MONITOR_TYPE="tcp"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--tcp-only | --ssl] (default: tcp-only)"
            exit 1
            ;;
    esac
done

echo -e "${YELLOW}Starting monitoring stack...${NC}"
echo ""

# Function to cleanup background processes
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping all monitors...${NC}"
    jobs -p | xargs -r kill 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start TCP connection monitor
if [[ "$MONITOR_TYPE" == "tcp" || "$MONITOR_TYPE" == "both" ]]; then
    echo -e "${GREEN}[1/4] Starting TCP connection monitor...${NC}"
    python3 "$EBPF_DIR/monitor_runtime.py" \
        --config "$EBPF_DIR/service_map.json" \
        --output "$LOGS_DIR/ebpf-events.jsonl" \
        --summary-interval 30 &
    TCP_MONITOR_PID=$!
    echo -e "${GREEN}      → PID: $TCP_MONITOR_PID${NC}"
    sleep 2
fi

# Start SSL/TLS traffic monitor (Note: eBPF program has kernel verifier issues with BouncyCastle)
if [[ "$MONITOR_TYPE" == "both" ]]; then
    echo -e "${YELLOW}[2/4] Skipping SSL/TLS traffic monitor${NC}"
    echo -e "${YELLOW}      → Java services using BouncyCastle don't use OpenSSL${NC}"
    echo -e "${YELLOW}      → For SSL visibility, use TCP connection monitor (active above)${NC}"
fi

# Start Prometheus exporters
if [[ "$MONITOR_TYPE" == "tcp" || "$MONITOR_TYPE" == "both" ]]; then
    echo -e "${GREEN}[3/4] Starting TCP metrics exporter (port 9110)...${NC}"
    python3 "$EBPF_DIR/export_prometheus_metrics.py" \
        --input "$LOGS_DIR/ebpf-events.jsonl" \
        --port 9110 &
    TCP_EXPORTER_PID=$!
    echo -e "${GREEN}      → PID: $TCP_EXPORTER_PID${NC}"
    echo -e "${GREEN}      → Metrics: http://localhost:9110/metrics${NC}"
    sleep 1
fi

if [[ "$MONITOR_TYPE" == "ssl" || "$MONITOR_TYPE" == "both" ]]; then
    echo -e "${GREEN}[4/4] Starting SSL metrics exporter (port 9100)...${NC}"
    python3 "$EBPF_DIR/export_ssl_metrics.py" \
        --input "$LOGS_DIR/ebpf-ssl-traffic.jsonl" \
        --port 9100 &
    SSL_EXPORTER_PID=$!
    echo -e "${GREEN}      → PID: $SSL_EXPORTER_PID${NC}"
    echo -e "${GREEN}      → Metrics: http://localhost:9100/metrics${NC}"
    sleep 1
fi
echo -e "${GREEN}[3/4] Starting TCP metrics exporter (port 9110)...${NC}"
python3 "$EBPF_DIR/export_prometheus_metrics.py" \
    --input "$LOGS_DIR/ebpf-events.jsonl" \
    --port 9110 &
TCP_EXPORTER_PID=$!
echo -e "${GREEN}      → PID: $TCP_EXPORTER_PID${NC}"
echo -e "${GREEN}      → Metrics: http://localhost:9110/metrics${NC}"
echo "  • TCP events: $LOGS_DIR/ebpf-events.jsonl"
echo ""
echo -e "${YELLOW}Prometheus endpoints:${NC}"
echo "  • TCP metrics: http://localhost:9110/metrics"
echo ""
echo -e "${YELLOW}Grafana dashboards:${NC}"
echo "  • http://localhost:3000 (admin/admin)"
echo "  • Dashboard: eBPF Runtime Monitoring (ebpf-overview.json)"
echo ""
echo -e "${YELLOW}Sample commands:${NC}"
echo "  • View events: tail -f $LOGS_DIR/ebpf-events.jsonl | jq ."
echo "  • Check metrics: curl -s http://localhost:9110/metrics | head -20