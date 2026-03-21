#!/bin/bash

# Start eBPF SSL/TLS Traffic Monitor for SIA_BANK Microservices
# This script launches the enhanced eBPF monitor that observes encrypted traffic
# across all microservices using kernel-level uprobes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EBPF_DIR="$PROJECT_ROOT/ebpf"
LOG_DIR="$PROJECT_ROOT/logs"

# Configuration
CONFIG_FILE="$EBPF_DIR/tls_service_map.json"
OUTPUT_LOG="$LOG_DIR/ebpf-ssl-traffic.jsonl"
SUMMARY_INTERVAL=30
JAVA_RUNTIME=false
RUNTIME_CONFIG_FILE="$EBPF_DIR/service_map.json"
RUNTIME_OUTPUT_LOG="$LOG_DIR/ebpf-runtime-events.jsonl"
SIMULATE=false
SIMULATE_ITERATIONS=5
INCLUDE_UNKNOWN=""
SIM_PORT=9443
SIM_CERT="$PROJECT_ROOT/certs/ca.crt"
SIM_KEY="$PROJECT_ROOT/certs/ca.key"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SIA_BANK eBPF SSL/TLS Traffic Monitor${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

simulate_tls_for_service() {
    local service_name="$1"
    local iterations="$2"

    for ((i=1; i<=iterations; i++)); do
        printf "GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n" | \
            env SERVICE_NAME="$service_name" bash -c 'exec -a "$SERVICE_NAME" openssl s_client -connect 127.0.0.1:'"$SIM_PORT"' -quiet -tls1_3 >/dev/null 2>&1' || true
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "eBPF probes require elevated privileges to attach to kernel functions"
    echo "Please run: sudo $0"
    exit 1
fi

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: python3 not found${NC}"
    echo "Please install Python 3"
    exit 1
fi

# Check for BCC/eBPF tools
if ! python3 -c "import bcc" 2>/dev/null; then
    echo -e "${RED}ERROR: BCC (BPF Compiler Collection) not installed${NC}"
    echo ""
    echo "To install on Ubuntu/Debian:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y bpfcc-tools python3-bpfcc linux-headers-\$(uname -r)"
    echo ""
    echo "To install on RHEL/CentOS:"
    echo "  sudo yum install -y bcc-tools python3-bcc kernel-devel-\$(uname -r)"
    exit 1
fi

# Check for OpenSSL library
echo -e "${YELLOW}Locating OpenSSL library...${NC}"
SSL_LIB=""
possible_paths=(
    "/usr/lib/x86_64-linux-gnu/libssl.so.3"
    "/usr/lib/x86_64-linux-gnu/libssl.so.1.1"
    "/usr/lib64/libssl.so.3"
    "/usr/lib64/libssl.so.1.1"
    "/lib/x86_64-linux-gnu/libssl.so.3"
    "/lib/x86_64-linux-gnu/libssl.so.1.1"
)

for path in "${possible_paths[@]}"; do
    if [ -f "$path" ]; then
        SSL_LIB="$path"
        echo -e "${GREEN}Found OpenSSL library: $SSL_LIB${NC}"
        break
    fi
done

if [ -z "$SSL_LIB" ]; then
    echo -e "${YELLOW}WARNING: Could not auto-detect OpenSSL library${NC}"
    echo "Java applications using BouncyCastle may not use OpenSSL directly."
    echo "Consider using the TCP-based monitor for Java microservices."
    echo ""
    echo "Attempting to continue anyway..."
fi

# Create log directory
mkdir -p "$LOG_DIR"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}ERROR: Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Configuration loaded from: $CONFIG_FILE${NC}"
echo -e "${GREEN}Logs will be written to: $OUTPUT_LOG${NC}"
echo ""

# Display monitored services
echo -e "${YELLOW}Monitored services:${NC}"
python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
    for svc in config['services']:
        tls_status = '✓ TLS' if svc.get('tlsEnabled') else '✗ No TLS'
        pqc_status = '✓ PQC' if svc.get('pqcEnabled') else ''
        print(f\"  • {svc['name']:25} Port {svc['port']:5} {tls_status} {pqc_status}\")
"
echo ""

# Parse command line arguments
CAPTURE_DATA=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --capture-data)
            CAPTURE_DATA="--capture-data"
            echo -e "${YELLOW}WARNING: Data capture enabled - sensitive data will be logged!${NC}"
            shift
            ;;
        --include-unknown)
            INCLUDE_UNKNOWN="--include-unknown"
            shift
            ;;
        --java-runtime)
            JAVA_RUNTIME=true
            shift
            ;;
        --simulate)
            SIMULATE=true
            shift
            ;;
        --simulate-iterations)
            SIMULATE_ITERATIONS="$2"
            shift 2
            ;;
        --ssl-lib)
            SSL_LIB="$2"
            shift 2
            ;;
        --summary-interval)
            SUMMARY_INTERVAL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--java-runtime] [--capture-data] [--include-unknown] [--simulate] [--simulate-iterations N] [--ssl-lib PATH] [--summary-interval SECONDS]"
            exit 1
            ;;
    esac
done

if [ "$JAVA_RUNTIME" = true ]; then
    if [ ! -f "$RUNTIME_CONFIG_FILE" ]; then
        echo -e "${RED}ERROR: Runtime config file not found: $RUNTIME_CONFIG_FILE${NC}"
        exit 1
    fi

    echo -e "${GREEN}Starting Java-compatible eBPF runtime monitor...${NC}"
    echo -e "${YELLOW}Mode: TCP runtime flow monitor (recommended for Java microservices)${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""

    python3 "$EBPF_DIR/monitor_runtime.py" \
      --config "$RUNTIME_CONFIG_FILE" \
      --output "$RUNTIME_OUTPUT_LOG" \
      --summary-interval "$SUMMARY_INTERVAL"
    exit 0
fi

# Build command
CMD="python3 $EBPF_DIR/monitor_ssl_traffic.py \
    --config $CONFIG_FILE \
    --output $OUTPUT_LOG \
    --summary-interval $SUMMARY_INTERVAL"

if [ -n "$SSL_LIB" ]; then
    CMD="$CMD --ssl-lib $SSL_LIB"
fi

if [ -n "$CAPTURE_DATA" ]; then
    CMD="$CMD $CAPTURE_DATA"
fi

if [ -n "$INCLUDE_UNKNOWN" ]; then
    CMD="$CMD $INCLUDE_UNKNOWN"
fi

echo -e "${GREEN}Starting eBPF SSL/TLS Traffic Monitor...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""
echo "Command: $CMD"
echo ""
echo "----------------------------------------"

if [ "$SIMULATE" = true ]; then
    if ! command -v openssl >/dev/null 2>&1; then
        echo -e "${RED}ERROR: openssl not found (required for simulation)${NC}"
        exit 1
    fi

    if [ ! -f "$SIM_CERT" ] || [ ! -f "$SIM_KEY" ]; then
        echo -e "${RED}ERROR: Simulation cert/key not found${NC}"
        echo "Expected: $SIM_CERT and $SIM_KEY"
        exit 1
    fi

    : > "$OUTPUT_LOG"
    MONITOR_STDOUT="$LOG_DIR/ebpf-ssl-monitor.sim.out"
    : > "$MONITOR_STDOUT"

    echo -e "${GREEN}Simulation mode enabled${NC}"
    echo "Starting monitor in background..."
    bash -c "$CMD" > "$MONITOR_STDOUT" 2>&1 &
    MONITOR_PID=$!

    cleanup() {
        if [ -n "${SIM_SERVER_PID:-}" ]; then
            kill "$SIM_SERVER_PID" 2>/dev/null || true
        fi
        if [ -n "${MONITOR_PID:-}" ]; then
            kill -INT "$MONITOR_PID" 2>/dev/null || true
            wait "$MONITOR_PID" 2>/dev/null || true
        fi
    }
    trap cleanup EXIT

    sleep 3

    echo "Starting local TLS test endpoint on port $SIM_PORT..."
    openssl s_server -accept "$SIM_PORT" -cert "$SIM_CERT" -key "$SIM_KEY" -www -quiet >/dev/null 2>&1 &
    SIM_SERVER_PID=$!
    sleep 1

    echo "Generating simulated TLS traffic for SIA services..."
    simulate_tls_for_service "auth-service" "$SIMULATE_ITERATIONS"
    simulate_tls_for_service "account-service" "$SIMULATE_ITERATIONS"
    simulate_tls_for_service "transaction-service" "$SIMULATE_ITERATIONS"

    sleep 2
    kill "$SIM_SERVER_PID" 2>/dev/null || true
    unset SIM_SERVER_PID

    kill -INT "$MONITOR_PID" 2>/dev/null || true
    wait "$MONITOR_PID" 2>/dev/null || true
    unset MONITOR_PID

    echo ""
    echo "Simulation complete. Recent monitor output:"
    tail -n 40 "$MONITOR_STDOUT" || true
    echo ""
    echo "Recent captured events:"
    tail -n 20 "$OUTPUT_LOG" || true
    exit 0
fi

# Run the monitor normally
$CMD
