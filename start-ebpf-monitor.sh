#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${ROOT_DIR}/logs"
MONITOR_SCRIPT="${ROOT_DIR}/ebpf/monitor_runtime.py"
POLICY_FILE="${ROOT_DIR}/ebpf/service_map.json"

mkdir -p "${LOG_DIR}"

if [[ $EUID -ne 0 ]]; then
  echo "This script must run as root because eBPF attachment requires elevated privileges."
  echo "Try: sudo ./start-ebpf-monitor.sh"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required"
  exit 1
fi

echo "Starting eBPF runtime monitor..."
echo "Policy: ${POLICY_FILE}"
echo "Logs: ${LOG_DIR}/ebpf-events.jsonl"

python3 "${MONITOR_SCRIPT}" \
  --config "${POLICY_FILE}" \
  --output "${LOG_DIR}/ebpf-events.jsonl" \
  --summary-interval 10
